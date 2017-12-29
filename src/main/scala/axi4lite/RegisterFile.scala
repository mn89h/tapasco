package chisel.axi.axi4lite
import  chisel.axi._, chisel.axi.Axi4Lite
import  chisel.miscutils.Logging
import  chisel3._
import  chisel3.util._
import  scala.util.Properties.{lineSeparator => NL}
import  org.scalactic.anyvals.PosInt

object RegisterFile {
  /** Configuration object for RegisterFiles.
   *  @param addressWordBits Smallest addressable bit width (default: 8, e.g., 1 byte).
   *  @param width Register data width (in bits).
   *  @param regs Map from offsets in addrGranularity to register implementations.
   **/
  case class Configuration(addressWordBits: Int = 8, regs: Map[Long, ControlRegister], fifoDepth: PosInt = 2)
                          (implicit axi: Axi4Lite.Configuration) {
    /* internal helpers: */
    private def overlap(p: (BitRange, BitRange)) = p._1.overlapsWith(p._2)
    private def makeRange(a: Long): BitRange =
      BitRange(a * addressWordBits + axi.dataWidth.toLong - 1, a * addressWordBits)
    private lazy val m = regs.keys.toList.sorted map makeRange
    private lazy val o = (m.take(m.length - 1) zip m.tail) map { case (r1, r2) => ((r1, r2), r1.overlapsWith(r2)) }
    o filter (_._2) foreach { case ((r1, r2), _) => require(!r1.overlapsWith(r2), s"$r1 and $r2 must not overlap") }

    /* constraint checking */
    require (regs.size > 0, "regs must not be empty")
    require (regs.size == 1 || !(o map (_._2) reduce (_ || _)), "ranges must not overlap: " + regs)

    /** Minimum bit width of address lines. */
    lazy val minAddrWidth: AddrWidth = AddrWidth(Seq(if (regs.size * axi.dataWidth.toInt / addressWordBits >= regs.keys.max) {
      log2Ceil((regs.size * axi.dataWidth.toInt) / addressWordBits)
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
    val saxi = Axi4Lite.Slave(axi.copy(addrWidth = addrWidth))

    override def cloneType = new IO(cfg)(axi).asInstanceOf[this.type]
  }

  def behavior(cfg: RegisterFile.Configuration, io: RegisterFile.IO)
              (implicit axi: Axi4Lite.Configuration, logger: Logging, logLevel: Logging.Level) {
    class ReadData extends Bundle {
      val data = io.saxi.readData.bits.data.cloneType
      val resp = io.saxi.readData.bits.resp.cloneType
      override def cloneType = (new ReadData).asInstanceOf[this.type]
    }
    val in_q_ra = Module(new Queue(io.saxi.readAddr.bits.addr.cloneType, entries = cfg.fifoDepth, pipe = true))
    val in_q_wa = Module(new Queue(io.saxi.writeAddr.bits.addr.cloneType, entries = cfg.fifoDepth, pipe = true))
    val in_q_wd = Module(new Queue(io.saxi.writeData.bits.data.cloneType, entries = cfg.fifoDepth, pipe = true))

    val read_reg = Reg((new ReadData).cloneType)
    val resp_reg = RegNext(Response.slverr, init = Response.slverr)

    val out_q_rd = Module(new Queue((new ReadData).cloneType, cfg.fifoDepth))
    val out_q_wr = Module(new Queue(io.saxi.writeResp.bits.bresp.cloneType, cfg.fifoDepth))

    io.saxi.readData.bits.defaults
    io.saxi.readData.valid  := false.B
    io.saxi.writeResp.bits.defaults
    io.saxi.writeResp.valid := false.B

    in_q_ra.io.enq.bits     := io.saxi.readAddr.bits.addr
    in_q_ra.io.enq.valid    := io.saxi.readAddr.valid
    io.saxi.readAddr.ready  := in_q_ra.io.enq.ready
    in_q_wa.io.enq.bits     := io.saxi.writeAddr.bits.addr
    in_q_wa.io.enq.valid    := io.saxi.writeAddr.valid
    io.saxi.writeAddr.ready := in_q_wa.io.enq.ready
    in_q_wd.io.enq.bits     := io.saxi.writeData.bits.data
    in_q_wd.io.enq.valid    := io.saxi.writeData.valid
    io.saxi.writeData.ready := in_q_wd.io.enq.ready

    val out_q_rd_enq_valid = RegNext(false.B, init = false.B)
    out_q_rd.io.enq.bits    := read_reg
    out_q_rd.io.enq.valid   := out_q_rd_enq_valid
    out_q_rd.io.deq.ready   := io.saxi.readData.ready
    io.saxi.readData.bits.data := out_q_rd.io.deq.bits.data
    io.saxi.readData.bits.resp := out_q_rd.io.deq.bits.resp
    io.saxi.readData.valid     := out_q_rd.io.deq.valid

    val out_q_wr_enq_valid = RegNext(false.B, init = false.B)
    out_q_wr.io.enq.bits    := resp_reg
    out_q_wr.io.enq.valid   := out_q_wr_enq_valid
    out_q_wr.io.deq.ready   := io.saxi.writeResp.ready
    io.saxi.writeResp.valid := out_q_wr.io.deq.valid
    io.saxi.writeResp.bits.bresp := out_q_wr.io.deq.bits

    in_q_ra.io.deq.ready    := out_q_rd.io.enq.ready

    when (in_q_ra.io.deq.fire) {
      val addr = in_q_ra.io.deq.bits
      read_reg.resp := Response.slverr
      for (off <- cfg.regs.keys.toList.sorted) {
        when (addr === off.U) { cfg.regs(off).read() map { v =>
          logger.info(p"reading from address 0x${Hexadecimal(addr)} ($addr) -> 0x${Hexadecimal(v)} ($v)")
          read_reg.data := v
          read_reg.resp := Response.okay
        }}
      }
      out_q_rd_enq_valid := true.B
    }

    in_q_wa.io.deq.ready := in_q_wd.io.deq.valid && out_q_wr.io.enq.ready
    in_q_wd.io.deq.ready := in_q_wa.io.deq.valid && out_q_wr.io.enq.ready

    when (in_q_wa.io.deq.fire) {
      val addr = in_q_wa.io.deq.bits
      val v = in_q_wd.io.deq.bits
      for (off <- cfg.regs.keys.toList.sorted) {
        when (addr === off.U) {
          val r = cfg.regs(off).write(v)
          logger.info(p"writing to address 0x${Hexadecimal(addr)} ($addr) -> 0x${Hexadecimal(v)} ($v): 0x${Hexadecimal(r)} ($r)")
          resp_reg := r
        }
      }
      out_q_wr_enq_valid := true.B
    }
  }

  def resetBehavior(io: RegisterFile.IO)(implicit module: Module) {
    when (module.reset.toBool) { // this is required for AXI compliance; apparently Queues start working while reset is high
      io.saxi.readAddr.ready  := false.B
      io.saxi.readData.valid  := false.B
      io.saxi.writeAddr.ready := false.B
      io.saxi.writeData.ready := false.B
      io.saxi.writeResp.valid := false.B
    }
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
  implicit val logger: Logging = this
  cinfo(s"AXI config: $axi")
  val io = IO(new RegisterFile.IO(cfg))
  RegisterFile.behavior(cfg, io)(axi, logger, logLevel)
  RegisterFile.resetBehavior(io)(this)
}
