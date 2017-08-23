package chisel.axiutils
import  chisel3._
import  chisel3.util._
import  chisel3.iotesters.{PeekPokeTester}
import  chisel.axi._

class AxiSlaveModelIO(val cfg: AxiSlaveModelConfiguration)
                     (implicit axi: Axi4.Configuration) extends Bundle {
  val saxi = Axi4.Slave(axi)
}

class AxiSlaveModel(val cfg: AxiSlaveModelConfiguration)
                   (implicit val axi: Axi4.Configuration) extends Module {
  val sz = cfg.size
  println ("AxiSlaveModel: %s".format(cfg.toString))

  val io = IO(new AxiSlaveModelIO(cfg))
  val mem = Mem(sz, UInt(axi.dataWidth))

  /** WRITE PROCESS **/
  val wa_valid = (io.saxi.writeAddr.valid)
  val wd_valid = (io.saxi.writeData.valid)
  val wr_ready = RegNext(io.saxi.writeResp.ready)
  val wa_addr  = (io.saxi.writeAddr.bits.addr)
  val wd_data  = (io.saxi.writeData.bits.data)
  val wa_len   = RegNext(io.saxi.writeAddr.bits.burst.len)
  val wa_size  = RegNext(io.saxi.writeAddr.bits.burst.size)
  val wa_burst = RegNext(io.saxi.writeAddr.bits.burst.burst)

  val wa = Reg(UInt(axi.dataWidth))
  val wd = Reg(UInt(axi.dataWidth))
  val wr = Reg(UInt(2.W))
  val wl = Reg(io.saxi.writeAddr.bits.burst.len.cloneType)

  val wa_hs = Reg(Bool()) // address handshake complete?
  val wd_hs = Reg(Bool()) // data handshake complete?
  val wr_hs = Reg(Bool()) // response handshake complete?
  val wr_valid = Reg(Bool()) // response valid
  val wr_wait = Reg(UInt(log2Ceil(cfg.writeDelay + 1).W))

  /**
   * Returns data at address (dataWidth bits).
   * @param address AXI address (byte granularity).
   * @param t PeekPokeTester instance.
   * @return value of internal memory (cfg.dataWidth bit wide).
   **/
  def at(address: Int)(implicit t: PeekPokeTester[_]): BigInt  = {
    val idx = address / (axi.dataWidth / 8)
    require (idx >= 0 && idx < cfg.size,
             "AxiSlaveModel: read at invalid index %d (max: %d) for address 0x%x"
             .format(idx, cfg.size - 1, address))
    t.peekAt(mem, address / (axi.dataWidth / 8))
  }

  /**
   * Returns data at word index (dataWidth bits).
   * @param index Index into internal memory (cfg.dataWidth sized words).
   * @param t PeekPokeTester instance.
   * @return value of internal memory (cfg.dataWidth bit wide)
   **/
  def apply(index: Int)(implicit t: PeekPokeTester[_]): BigInt = {
    require (index >= 0 && index < cfg.size,
             "AxiSlaveModel: read at invalid index %d (max: %d)"
             .format(index, cfg.size - 1))
    t.peekAt(mem, index)
  }

  /**
   * Set data at address (dataWidth bits).
   * @param address AXI address (byte granularity, will be aligned automatically).
   * @param value Word value to set (always full word, cfg.dataWidth bits).
   * @param t PeekPokeTester instance.
   **/
  def set(address: Int, value: BigInt)(implicit t: PeekPokeTester[_]) = {
    val idx = address / (axi.dataWidth / 8)
    printf("AxiSlaveModel: set data at 0x%x (idx: %d) to 0x%x".format(address, value, idx))
    t.pokeAt(mem, value, idx)
  }

  io.saxi.writeAddr.ready      := !wa_hs
  io.saxi.writeData.ready      := wa_hs && !wr_valid && wr_wait === 0.U
  io.saxi.writeResp.bits.bresp := wr
  io.saxi.writeResp.bits.bid   := 0.U
  io.saxi.writeResp.valid      := wa_hs && wr_valid

  when (reset) {
    wa       := 0.U
    wd       := 0.U
    wr       := 0.U // OK
    wr_valid := false.B
    wa_hs    := false.B
    wd_hs    := false.B
    wr_hs    := false.B
    wr_wait  := 0.U
  }
  .otherwise {
    when (!wa_hs && wa_valid) {
      wa     := wa_addr
      wl     := wa_len
      wa_hs  := true.B
      assert (wa_size === (if (axi.dataWidth > 8) log2Ceil(axi.dataWidth / 8).U else 0.U), "wa_size is not supported".format(wa_size))
      assert (wa_burst < 2.U, "wa_burst type (b%s) not supported".format(wa_burst))
      if (cfg.writeDelay > 0) wr_wait := cfg.writeDelay.U
    }
    when (wa_hs && wr_wait > 0.U) { wr_wait := wr_wait - 1.U }
    when (wa_hs && wr_wait === 0.U) {
      when (wa_hs && wd_valid && !wr_valid) {
        val shifted_addr   = if (axi.dataWidth > 8) wa >> log2Ceil(axi.dataWidth / 8).U else wa
        mem(shifted_addr) := wd_data
        printf("writing data 0x%x to address 0x%x (0x%x)\n", wd_data, wa, shifted_addr)
        when (io.saxi.writeData.bits.last || wl === 0.U) { wr_valid := true.B }
        .otherwise {
          wl := wl - 1.U
          // increase address in INCR bursts
          when (wa_burst === "b01".U) { wa := wa + (axi.dataWidth / 8).U }
        }
      }
      when (wa_hs && wr_valid && wr_ready) {
        wa_hs    := false.B
        wd_hs    := false.B
        wr_valid := false.B
      }
    }
  }

  /** READ PROCESS **/
  val ra       = Reg(UInt(axi.addrWidth))
  val l        = Reg(UInt(8.W))
  val ra_valid = RegNext(io.saxi.readAddr.valid)
  val ra_addr  = RegNext(io.saxi.readAddr.bits.addr)
  val ra_len   = RegNext(io.saxi.readAddr.bits.burst.len)
  val ra_size  = RegNext(io.saxi.readAddr.bits.burst.size)
  val ra_burst = RegNext(io.saxi.readAddr.bits.burst.burst)

  val rr_resp  = 0.U(2.W) // response: OKAY

  val rr_wait  = Reg(UInt(log2Ceil(cfg.readDelay + 1).W))
  val ra_hs    = Reg(Bool())
  val ra_ready = !reset && !ra_hs

  io.saxi.readAddr.ready := ra_ready

  val rd_valid = ra_hs && rr_wait === 0.U

  io.saxi.readData.valid := rd_valid
  io.saxi.readData.bits.data := mem(if (axi.dataWidth > 8) ra >> (log2Ceil(axi.dataWidth / 8)).U else ra)
  io.saxi.readData.bits.last := ra_hs && l === 0.U
  io.saxi.readData.bits.resp := rr_resp

  when (reset) {
    ra        := 0.U
    l         := 1.U
    ra_valid  := false.B
    ra_addr   := 0.U
    ra_len    := "hFF".U
    ra_size   := 0.U
    ra_burst  := 0.U
    ra_hs     := false.B
    rr_wait   := 0.U
  }
  .otherwise {
    when(io.saxi.readData.ready && io.saxi.readData.valid) {
      printf("reading data 0x%x from address 0x%x\n",
          io.saxi.readData.bits.data,
          if (axi.dataWidth > 8) ra >> (log2Ceil(axi.dataWidth / 8)).U else ra)
    }
    when (!ra_hs && io.saxi.readAddr.ready && io.saxi.readAddr.valid) {
      ra    := io.saxi.readAddr.bits.addr
      ra_hs := true.B
      l     := io.saxi.readAddr.bits.burst.len
      if (cfg.readDelay > 0) rr_wait := cfg.readDelay.U
    }
    when (ra_hs && rr_wait > 0.U) { rr_wait := rr_wait - 1.U }
    when (rd_valid && io.saxi.readData.ready) {
      l      := l - 1.U
      ra     := ra + (axi.dataWidth / 8).U
      when (l === 0.U) { ra_hs := false.B }
    }
  }
}

/** AxiSlaveModel companion object with diverse helpers. **/
object AxiSlaveModel {
  import scala.util.Properties.{lineSeparator => NL}
  /**
   * Fills the given AXI memory model with linear data:
   * Data is filled with increasing integers of bitWidth size.
   * @param m AxiSlaveModel to fill.
   * @param bitWidth Number of bits per element.
   * @param tester PeekPokeTester instance for memory poking (implicit).
   **/
  def fillWithLinearSeq(m: AxiSlaveModel, bitWidth: Int)
                       (implicit axi: Axi4.Configuration, tester: PeekPokeTester[_]) = {
    import scala.math.{log, pow}
    require (axi.dataWidth % bitWidth == 0,
             "bitWidth (%d) must be evenly divisible by data width (%d)"
             .format(bitWidth, axi.dataWidth:Int))
    val maxData: Int = pow(2, bitWidth).toInt
    val maxAddr: Int = pow(2, axi.addrWidth:Int).toInt
    val size: Int = m.cfg.size 
    def makeNumber(i: Int): Int = {
      /*printf("fillWithLinearSeq::makeNumber: i = %d, maxData = 0x%x -> 0x%x%s"
             .format(i, maxData, i % maxData, NL))*/
      i % maxData
    }

    printf("fillWithLinearSeq: size = %d words, %d bits, bitWidth: %d%s"
      .format(size, axi.dataWidth:Int, bitWidth, NL))
    
    var word: BigInt = 0
    for (i <- 0 until size; addr = i * (axi.dataWidth / 8)) {
      for (j <- 0 until axi.dataWidth / bitWidth)
        word = (word << bitWidth) | makeNumber(i * (axi.dataWidth / bitWidth) + j)
      printf("fillWithLinearSeq: address = 0x%x, word = 0x%x%s".format(addr, word, NL))
      m.set(addr, word)
      word = 0
    }
  }
}
