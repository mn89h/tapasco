package chisel.axiutils.registers
import chisel.axiutils.AxiConfiguration
import chisel.axiutils.registers._
import Chisel._
import AXILiteDefs._
import scala.util.Properties.{lineSeparator => NL}

/**
 * Configuration object for Axi4LiteRegisterFile.
 * @param addrGranularity Smallest addressable bit width (default: 8, e.g., 1 byte).
 * @param width Register data width (in bits).
 * @param regs Map from offsets in addrGranularity to register implementations.
 */
case class Axi4LiteRegisterFileConfiguration(
  addrGranularity: Int = 8,
  width: Int,
  regs: Map[Int, ControlRegister]
) {
  /* internal helpers: */
  private def overlap(p: (BitRange, BitRange)) = p._1.overlapsWith(p._2)
  private def makeRange(a: Int): BitRange = BitRange(a * addrGranularity + width - 1, a * addrGranularity)
  private lazy val m = regs.keys.toList.sorted map makeRange
  private lazy val o: Seq[Boolean] = (m.take(m.length - 1) zip m.tail) map overlap

  /* constraint checking */
  require (width > 0 && width <= 1024,
           "Axi4LiteRegisterFile: width (%d) must be 0 < width <= 1024"
           .format(width))
  require (regs.size > 0, "regs must not be empty")
  require (regs.size == 1 || !(o reduce (_||_)), "ranges must not overlap: " + regs)

  /** Minimum bit width of address lines. */
  lazy val minAddrWidth: Int = Seq(log2Up(regs.size * width / addrGranularity), log2Up(regs.keys.max)).max
}

/**
 * Axi4LiteRegisterFile bundle.
 * @param cfg Configuration object.
 * @param axi Implicit AXI configuration.
 **/
class Axi4LiteRegisterFileIO(cfg: Axi4LiteRegisterFileConfiguration)(implicit axi: AxiConfiguration) extends Bundle {
  val addrWidth: Int = Seq(cfg.minAddrWidth, axi.addrWidth) max
  val dataWidth: Int = Seq(cfg.width, axi.dataWidth) max
  val saxi = new AXILiteSlaveIF(dataWidth, addrWidth)
}

/**
 * Axi4LiteRegisterFile implements a register file:
 * Writes currently take at least 3 cycles (addr -> data -> response), reads at least 2 (addr -> response).
 * No strobe support, always read/write full register width.
 * @param cfg Configuration object.
 * @param axi Implicit AXI configuration.
 **/
class Axi4LiteRegisterFile(cfg: Axi4LiteRegisterFileConfiguration)(implicit axi: AxiConfiguration) extends Module {
  /** Dumps address map as markdown file. **/
  def dumpAddressMap(path: String) = {
    def mksz(s: String, w: Int) = if (s.length > w) s.take(w) else if (s.length < w) s + (" " * (w - s.length)) else s
    val fw = new java.io.FileWriter(java.nio.file.Paths.get(path).resolve("AdressMap.md").toString)
    fw.append("| **Name**        |**From**|**To**  | **Description**                          |").append(NL)
      .append("|:----------------|:------:|:------:|:-----------------------------------------|").append(NL)
    for (off <- cfg.regs.keys.toList.sorted; reg = cfg.regs(off))
      fw.append("| %s | 0x%04x | 0x%04x | %s |".format(
        mksz(reg.name.getOrElse("N/A"), 15), off, off + cfg.width/8 - 1, reg.description//mksz(reg.description, 40)
      )).append(NL)
    fw.flush()
    fw.close
  }

  /** HARDWARE **/
  val io = new Axi4LiteRegisterFileIO(cfg)

  /** states: ready for address, transferring **/
  val ready :: fetch :: transfer :: response :: Nil = Enum(UInt(), 4)

  /** READ PROCESS **/
  val r_state = Reg(init = ready)                   // read state
  val r_data  = Reg(UInt(width = io.dataWidth))     // read data buffer
  val r_addr  = Reg(UInt(width = io.addrWidth))     // read address

  io.saxi.readAddr.ready     := r_state === ready
  io.saxi.readData.valid     := r_state === transfer
  io.saxi.readData.bits.data := r_data
  io.saxi.readData.bits.resp := UInt(2)             // default: SLVERR

  when (reset) {
    r_data                 := UInt("hDEADBEEF")
    r_state                := ready
    io.saxi.readAddr.ready := Bool(false)
    io.saxi.readData.valid := Bool(false)
  }
  .otherwise {
    // assign data from reg
    for (off <- cfg.regs.keys.toList.sorted)
      when (r_addr === UInt(off)) { cfg.regs(off).read() map { v => r_data := v; io.saxi.readData.bits.resp := UInt(0) } }

    // address receive state
    when (r_state === ready && io.saxi.readAddr.valid) {
      assert(io.saxi.readAddr.bits.prot === UInt(0), "Axi4LiteRegisterFile: read does not support PROT")
      r_addr  := io.saxi.readAddr.bits.addr
      r_state := fetch
      printf("Axi4LiteRegisterFile: received read address 0x%x\n", io.saxi.readAddr.bits.addr)
    }

    // wait one cycle for fetch
    when (r_state === fetch) { r_state := transfer }

    // data transfer state
    when (r_state === transfer && io.saxi.readData.ready) {
      r_state := ready
      printf("Axi4LiteRegisterFile: read 0x%x from address 0x%x\n", r_data, r_addr)
    }
  }

  /** WRITE PROCESS **/
  val w_state = Reg(init = ready)                 // write state
  val w_data  = Reg(UInt(width = io.dataWidth))   // write data buffer
  val w_addr  = Reg(UInt(width = io.addrWidth))   // write address
  val w_resp  = Reg(UInt(width = 2))              // write response

  w_resp                  := UInt(2)              // default: SLVERR
  io.saxi.writeResp.bits  := w_resp
  io.saxi.writeResp.valid := w_state === response
  io.saxi.writeData.ready := w_state === transfer
  io.saxi.writeAddr.ready := w_state === ready

  when (reset) {
    w_data                  := UInt("hDEADBEEF")
    w_state                 := ready
    io.saxi.writeAddr.ready := Bool(false)
    io.saxi.writeData.ready := Bool(false)
    io.saxi.writeResp.valid := Bool(false)
  }
  .otherwise {
    // address receive state
    when (w_state === ready) {
      when (io.saxi.writeAddr.valid) {
        assert(io.saxi.readAddr.bits.prot === UInt(0), "Axi4LiteRegisterFile: write does not support PROT")
        w_addr  := io.saxi.writeAddr.bits.addr
        w_state := transfer
        printf("Axi4LiteRegisterFile: received write address 0x%x\n", io.saxi.writeAddr.bits.addr)
      }
    }
    // data transfer state
    when (w_state === transfer && io.saxi.writeData.valid) {
      // TODO assert strobes
      w_state := response
      // assign data to reg
      for (off <- cfg.regs.keys.toList.sorted)
        when (w_addr === UInt(off)) {
          printf("Axi4LiteRegisterFile: writing 0x%x to register with offset %d\n", w_data, UInt(off))
          w_resp := Mux(Bool(cfg.regs(off).write(io.saxi.writeData.bits.data)), UInt(0) /*OKAY*/, UInt(2) /*SLVERR*/)
        }
    }
    // write response state
    when (w_state === response && io.saxi.writeResp.ready) { w_state := ready }
  }
}
