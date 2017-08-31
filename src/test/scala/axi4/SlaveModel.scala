package chisel.axiutils.axi4
import  chisel3._, chisel3.util._
import  chisel3.iotesters.{PeekPokeTester}
import  chisel.axi._
import  chisel.miscutils.Logging
import  scala.util.Properties.{lineSeparator => NL}

object SlaveModel {
  /** SlaveModelConfiguration configures an SlaveModel instance.
   *  @param addrWidth address bits for AXI4 interface.
   *  @param dataWidth word width for AXI4 interface.
   *  @param idWidth id bits for AXI4 interface.
   *  @param size size of memory to model (in dataWidth-sized elements).
   *  @param readDelay simulated delay between read address handshake and data.
   *  @param writeDelay simulated delay between write address handshake and data.
   **/
  class Configuration(val size: Int,
                      val readDelay: Int,
                      val writeDelay: Int)
                     (implicit axi: Axi4.Configuration) {
    require (axi.dataWidth > 0 && axi.dataWidth <= 256,
             "dataWidth (%d) must be 0 < dataWidth <= 256".format(axi.dataWidth))
    require (axi.idWidth.toInt == 1, "id width (%d) is not supported, use 1bit".format(axi.idWidth))
    require (readDelay >= 0, "read delay (%d) must be >= 0".format(readDelay))
    require (writeDelay >= 0, "write delay (%d) must be >= 0".format(writeDelay))

    override def toString: String =
      "addrWidth = %d, dataWidth = %d, idWidth = %d, size = %d, readDelay = %d, writeDelay = %d"
      .format(axi.addrWidth:Int, axi.dataWidth:Int, axi.idWidth:Int, size, readDelay, writeDelay)
  }

  object Configuration {
    /** Construct a Configuration. Size and address width are optional,
     *  but one needs to be supplied to determine simulated memory size.
     *  @param size size of memory to model in bytes (optional).
     *  @param readDelay simulated delay between read address handshake and data (default: 30).
     *  @param writeDelay simulated delay between write address handshake and data (default: 20).
     **/
    def apply(size: Option[Int] = None, readDelay: Int = 30, writeDelay: Int = 120)
             (implicit axi: Axi4.Configuration) = {
      val sz: Int = size.getOrElse(scala.math.pow(2, axi.addrWidth:Int).toInt / axi.dataWidth)
      val aw: Int = Seq(axi.addrWidth:Int, log2Ceil(sz * axi.dataWidth / 8).toInt).min
      new Configuration(size = sz, readDelay = readDelay, writeDelay = writeDelay)
    }
  }

  class IO(val cfg: Configuration)(implicit axi: Axi4.Configuration) extends Bundle {
    val saxi  = Axi4.Slave(axi)
    override def cloneType = { new SlaveModel.IO(cfg)(axi).asInstanceOf[this.type] }
  }
}

class SlaveModel(val cfg: SlaveModel.Configuration)
                   (implicit val axi: Axi4.Configuration,
                    logLevel: Logging.Level) extends Module with Logging {
  val sz = cfg.size
  cinfo(cfg.toString)

  val io = IO(new SlaveModel.IO(cfg))
  val mem = SyncReadMem(sz, UInt(axi.dataWidth))

  /** WRITE PROCESS **/
  val wa_valid = io.saxi.writeAddr.valid
  val wd_valid = io.saxi.writeData.valid
  val wr_ready = RegNext(io.saxi.writeResp.ready)
  val wa_addr  = io.saxi.writeAddr.bits.addr
  val wd_data  = io.saxi.writeData.bits.data
  val wa_len   = RegNext(io.saxi.writeAddr.bits.burst.len)
  val wa_size  = RegNext(io.saxi.writeAddr.bits.burst.size)
  val wa_burst = RegNext(io.saxi.writeAddr.bits.burst.burst)

  val wa       = RegInit(UInt(axi.dataWidth), init = 0.U)
  val wd       = RegInit(UInt(axi.dataWidth), init = 0.U)
  val wr       = RegInit(UInt(2.W), init = Response.okay)
  val wl       = RegInit(wa_len)

  val wa_hs    = RegInit(Bool(), init = false.B) // address handshake complete?
  val wd_hs    = RegInit(Bool(), init = false.B) // data handshake complete?
  val wr_hs    = RegInit(Bool(), init = false.B) // response handshake complete?
  val wr_valid = RegInit(Bool(), init = false.B) // response valid
  val wr_wait  = RegInit(UInt(log2Ceil(cfg.writeDelay + 1).W), init = 0.U)

  io.saxi.writeAddr.ready      := ~wa_hs
  io.saxi.writeData.ready      := wa_hs & ~wr_valid & wr_wait === 0.U
  io.saxi.writeResp.bits.bresp := wr
  io.saxi.writeResp.bits.bid   := 0.U
  io.saxi.writeResp.valid      := wa_hs & wr_valid

  when (!wa_hs & wa_valid) {
    wa     := wa_addr
    wl     := wa_len
    wa_hs  := true.B
    assert (wa_size === (if (axi.dataWidth > 8) log2Ceil(axi.dataWidth / 8).U else 0.U),
            "wa_size is not supported".format(wa_size))
    assert (wa_burst < 2.U, "wa_burst type (b%s) not supported".format(wa_burst))
    if (cfg.writeDelay > 0) wr_wait := cfg.writeDelay.U
  }
  when (wa_hs & wr_wait > 0.U) { wr_wait := wr_wait - 1.U }
  when (wa_hs & wr_wait === 0.U) {
    when (wa_hs & wd_valid & !wr_valid) {
      val shifted_addr   = if (axi.dataWidth > 8) wa >> log2Ceil(axi.dataWidth / 8).U else wa
      //mem(shifted_addr) := wd_data
      mem.write(shifted_addr, wd_data)
      printf("writing data 0x%x to address 0x%x (0x%x)\n", wd_data, wa, shifted_addr)
      when (io.saxi.writeData.bits.last || wl === 0.U) { wr_valid := true.B }
      .otherwise {
        wl := wl - 1.U
        // increase address in INCR bursts
        when (wa_burst === Axi4.Burst.Type.incr) { wa := wa + (axi.dataWidth / 8).U }
      }
    }
    when (wa_hs & wr_valid & wr_ready) {
      wa_hs    := false.B
      wd_hs    := false.B
      wr_valid := false.B
    }
  }

  /** READ PROCESS **/
  val ra = RegInit(io.saxi.readAddr)
  val rd = RegInit(io.saxi.readData)
  val ra_hs = RegInit(Bool(), init = false.B)
  val rr_wait = RegInit(UInt(32.W), init = 0.U)
  val l = RegInit(UInt(32.W), init = 0.U)

  io.saxi.readAddr <> ra
  io.saxi.readData <> rd
  rd.bits.resp := Response.okay
  ra.ready     := ~ra_hs
  rd.valid     :=  ra_hs

  when (ra_hs) {
    when (rr_wait > 0.U) { rr_wait := rr_wait - 1.U }
    .otherwise {
      rd.bits.data := mem.read(ra.bits.addr >> log2Ceil(axi.dataWidth / 8))
      rd.bits.last := l === 0.U
      when (rd.fire()) {
        l            := l - 1.U
        ra.bits.addr := ra.bits.addr + (axi.dataWidth / 8).U
        ra_hs        := l =/= 0.U
        printf("reading data 0x%x from address 0x%x\n", io.saxi.readData.bits.data, ra.bits.addr >> log2Ceil(axi.dataWidth / 8).U)
      }
    }
  }
  .otherwise {
    when (ra.fire()) {
      ra_hs := true.B
      l     := 1.U << ra.bits.burst.len
      if (cfg.readDelay > 0) rr_wait := cfg.readDelay.U
      printf(p"starting read from 0x${Hexadecimal(ra.bits.addr)} with length ${1.U << ra.bits.burst.len}$NL")
    }
  }
}
