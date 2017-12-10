package chisel.axi.axi4lite
import  chisel.axi._, chisel.axi.Axi4Lite
import  chisel.miscutils.Logging
import  chisel3._
import  chisel3.util._
import  scala.util.Properties.{lineSeparator => NL}

object RegisterFile {
  /** Configuration object for RegisterFiles.
   *  @param addrGranularity Smallest addressable bit width (default: 8, e.g., 1 byte).
   *  @param width Register data width (in bits).
   *  @param regs Map from offsets in addrGranularity to register implementations.
   **/
  case class Configuration(addrGranularity: Int = 32, regs: Map[Int, ControlRegister])
                          (implicit axi: Axi4Lite.Configuration) {
    /* internal helpers: */
    private def overlap(p: (BitRange, BitRange)) = p._1.overlapsWith(p._2)
    private def makeRange(a: Int): BitRange =
      BitRange(a * addrGranularity + axi.dataWidth.toInt - 1, a * addrGranularity)
    private lazy val m = regs.keys.toList.sorted map makeRange
    private lazy val o: Seq[Boolean] = (m.take(m.length - 1) zip m.tail) map overlap

    /* constraint checking */
    require (regs.size > 0, "regs must not be empty")
    require (regs.size == 1 || !(o reduce (_||_)), "ranges must not overlap: " + regs)

    /** Minimum bit width of address lines. */
    lazy val minAddrWidth: AddrWidth = AddrWidth(Seq(if (regs.size * axi.dataWidth.toInt >= regs.keys.max) {
      log2Ceil((regs.size * axi.dataWidth.toInt) / addrGranularity)
    } else {
      log2Ceil(regs.keys.max)
    }, 1).max)

    /** Dumps address map as markdown file. **/
    def dumpAddressMap(path: String) = {
      def mksz(s: String, w: Int) = if (s.length > w) s.take(w) else if (s.length < w) s + (" " * (w - s.length)) else s
      val fw = new java.io.FileWriter(java.nio.file.Paths.get(path).resolve("AdressMap.md").toString)
      fw.append("| **Name**        |**From**|**To**  | **Description**                          |").append(NL)
        .append("|:----------------|:------:|:------:|:-----------------------------------------|").append(NL)
      for (off <- regs.keys.toList.sorted; reg = regs(off))
        fw.append("| %s | 0x%04x | 0x%04x | %s |".format(
          mksz(reg.name.getOrElse("N/A"), 15), off, off + axi.dataWidth / 8 - 1, reg.description
        )).append(NL)
      fw.flush()
      fw.close
    }
  }

  /**
   * Axi4LiteRegisterFile bundle.
   * @param cfg [[Configuration]] object.
   * @param axi Implicit AXI configuration.
   **/
  class IO(cfg: Configuration)(implicit axi: Axi4Lite.Configuration) extends Bundle {
    val addrWidth: AddrWidth = AddrWidth(Seq(cfg.minAddrWidth:Int, axi.addrWidth:Int).max)
    val saxi = Axi4Lite.Slave(axi)

    override def cloneType = new IO(cfg)(axi).asInstanceOf[this.type]
  }
}

/**
 * RegisterFile implements a AXI4Lite register file:
 * Writes currently take at least 3 cycles (addr -> data -> response), reads at
 * least 2 (addr -> response). No strobe support, always read/write full register
 * width.
 * @param cfg Configuration object.
 * @param axi Implicit AXI configuration.
 **/
class RegisterFile(cfg: RegisterFile.Configuration)
                  (implicit axi: Axi4Lite.Configuration,
                   logLevel: Logging.Level) extends Module with Logging {
  /** HARDWARE **/
  val io = IO(new RegisterFile.IO(cfg))

  /** states: ready for address, transferring **/
  val ready :: fetch :: transfer :: response :: Nil = Enum(4)

  /** READ PROCESS **/
  val r_state = RegInit(ready)                               // read state
  val r_data  = RegInit(UInt(axi.dataWidth), "hDEADBEEF".U)  // read data buffer
  val r_addr  = RegInit(UInt(axi.addrWidth), 0.U)            // read address

  io.saxi.readAddr.ready     := RegNext(r_state === ready, init = false.B)
  io.saxi.readData.valid     := RegNext(r_state === transfer, init = false.B)
  io.saxi.readData.bits.data := r_data
  io.saxi.readData.bits.resp := Response.slverr

  // assign data from reg
  for (off <- cfg.regs.keys.toList.sorted) {
    when (r_addr === off.U) {
      cfg.regs(off).read() map { v => r_data := v; io.saxi.readData.bits.resp := 0.U }
    }
  }

  // address receive state
  when (r_state === ready && io.saxi.readAddr.valid) {
    assert(io.saxi.readAddr.bits.prot.prot === 0.U, "RegisterFile: read does not support PROT")
    r_addr  := io.saxi.readAddr.bits.addr
    r_state := fetch
    info(p"received read address 0x${Hexadecimal(io.saxi.readAddr.bits.addr)}")
  }

  // wait one cycle for fetch
  when (r_state === fetch) { r_state := transfer }

  // data transfer state
  when (r_state === transfer && io.saxi.readData.ready) {
    r_state := ready
    info(p"read 0x${Hexadecimal(r_data)} from address 0x${Hexadecimal(r_addr)}")
  }

  /** WRITE PROCESS **/
  val w_state = RegInit(ready)                                // write state
  val w_data  = RegInit(UInt(axi.dataWidth), "hDEADBEEF".U)   // write data buffer
  val w_addr  = RegInit(UInt(axi.addrWidth), 0.U)             // write address
  val w_resp  = RegInit(UInt(2.W), Response.slverr)           // write response

  w_resp                       := Response.slverr
  io.saxi.writeResp.bits.bresp := w_resp
  io.saxi.writeResp.valid      := RegNext(w_state === response, init = false.B)
  io.saxi.writeData.ready      := RegNext(w_state === transfer, init = false.B)
  io.saxi.writeAddr.ready      := RegNext(w_state === ready, init = false.B)

  // address receive state
  when (w_state === ready) {
    when (io.saxi.writeAddr.valid) {
      assert(io.saxi.readAddr.bits.prot.prot === 0.U, "RegisterFile: write does not support PROT")
      w_addr  := io.saxi.writeAddr.bits.addr
      w_state := transfer
      info(p"received write address 0x${Hexadecimal(io.saxi.writeAddr.bits.addr)}")
    }
  }
  // data transfer state
  when (w_state === transfer && io.saxi.writeData.valid) {
    // TODO assert strobes; implement logic to return slverr when strobes not set
    w_state := response
    // assign data to reg
    for (off <- cfg.regs.keys.toList.sorted) {
      when (w_addr === off.U) {
        info(p"writing 0x${Hexadecimal(w_data)} to register with offset ${off.U}")
        w_resp := Mux(cfg.regs(off).write(io.saxi.writeData.bits.data).B, Response.okay, Response.slverr)
      }
    }
  }
  // write response state
  when (w_state === response && io.saxi.writeResp.ready) { w_state := ready }
}
