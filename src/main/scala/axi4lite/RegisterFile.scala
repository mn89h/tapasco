package chisel.axi.axi4lite
import  chisel.axi._, chisel.axi.Axi4Lite
import  chisel.miscutils.Logging
import  chisel3._
import  chisel3.util._
import  scala.util.Properties.{lineSeparator => NL}
import  org.scalactic.anyvals.PosInt

object RegisterFile {
  /** Configuration object for RegisterFiles.
   *  @param addrGranularity Smallest addressable bit width (default: 8, e.g., 1 byte).
   *  @param width Register data width (in bits).
   *  @param regs Map from offsets in addrGranularity to register implementations.
   **/
  case class Configuration(addrGranularity: Int = 32, regs: Map[Int, ControlRegister], fifoDepth: PosInt = 2)
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
  class ReadData extends Bundle {
    val data = io.saxi.readData.bits.data.cloneType
    val resp = io.saxi.readData.bits.data.cloneType
    override def cloneType = (new ReadData).asInstanceOf[this.type]
  }

  val io = IO(new RegisterFile.IO(cfg))

  // workaround: code below does not work due to optional elements in bundle
  //val in_q_ra  = Queue(io.saxi.readAddr,  entries = cfg.fifoDepth, pipe = true)
  val in_q_ra = Module(new Queue(io.saxi.readAddr.bits.addr.cloneType, entries = cfg.fifoDepth, pipe = true))
  //val in_q_wa  = Queue(io.saxi.writeAddr, entries = cfg.fifoDepth, pipe = true)
  val in_q_wa = Module(new Queue(io.saxi.writeAddr.bits.addr.cloneType, entries = cfg.fifoDepth, pipe = true))
  //val in_q_wd  = Queue(io.saxi.writeData, entries = cfg.fifoDepth, pipe = true)
  val in_q_wd = Module(new Queue(io.saxi.writeData.bits.data.cloneType, entries = cfg.fifoDepth, pipe = true))

  val read_reg = Reg((new ReadData).cloneType)
  val resp_reg = RegInit(io.saxi.writeResp.bits.bresp.cloneType, init = Response.slverr)

  //val out_q_rd = Module(new Queue(new Axi4Lite.Data.Read, cfg.fifoDepth))
  val out_q_rd = Module(new Queue((new ReadData).cloneType, cfg.fifoDepth))
  //val out_q_wr = Module(new Queue(new Axi4Lite.WriteResponse, cfg.fifoDepth))
  val out_q_wr = Module(new Queue(io.saxi.writeResp.bits.bresp.cloneType, cfg.fifoDepth))

  when (in_q_ra.io.enq.fire)  { info(p"received read address: ${in_q_ra.io.enq.bits}") }
  when (in_q_wa.io.enq.fire)  { info(p"received write address: ${in_q_wa.io.enq.bits}") }
  when (in_q_wd.io.enq.fire)  { info(p"received write data: ${in_q_wd.io.enq.bits}") }
  when (out_q_rd.io.enq.fire) { info(p"enq read data: ${out_q_rd.io.enq.bits}") }
  when (out_q_rd.io.deq.fire) { info(p"deq read data: ${out_q_rd.io.enq.bits}") }
  when (out_q_wr.io.enq.fire) { info(p"enq write resp: ${out_q_wr.io.enq.bits}") }
  when (out_q_wr.io.deq.fire) { info(p"deq write resp: ${out_q_wr.io.enq.bits}") }

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

  out_q_rd.io.enq.bits    := read_reg
  out_q_rd.io.enq.valid   := false.B
  out_q_rd.io.deq.ready   := io.saxi.readData.ready
  io.saxi.readData.bits.data := out_q_rd.io.deq.bits.data
  io.saxi.readData.bits.resp := out_q_rd.io.deq.bits.resp

  out_q_wr.io.enq.bits    := resp_reg
  out_q_wr.io.enq.valid   := false.B
  out_q_wr.io.deq.ready   := io.saxi.writeResp.ready
  io.saxi.writeResp.valid := out_q_wr.io.deq.valid
  io.saxi.writeResp.bits.bresp := out_q_wr.io.deq.bits

  when (in_q_ra.io.deq.valid) {
    val addr = in_q_ra.io.deq.bits
    for (off <- cfg.regs.keys.toList.sorted) {
      when (addr === off.U) { cfg.regs(off).read() map { v =>
        info(p"reading from address $addr -> $v")
        read_reg.data := v
        read_reg.resp := Response.okay
      }}
    }
    in_q_ra.io.deq.ready := RegNext(out_q_rd.io.enq.ready)
  }

  when (in_q_wa.io.deq.valid && in_q_wd.io.deq.valid && out_q_wr.io.enq.ready) {
    val addr = in_q_wa.io.deq.bits
    for (off <- cfg.regs.keys.toList.sorted) {
      when (addr === off.U) { cfg.regs(off).read() map { v =>
        info(p"writing to address $addr -> $v")
        out_q_wr.io.enq.bits  := { if (cfg.regs(off).write(v)) Response.okay else Response.slverr }
        out_q_wr.io.enq.valid := true.B
      }}
    }
  }
}
