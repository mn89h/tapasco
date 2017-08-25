package chisel.axiutils.registers
import  chisel.axi._, Axi4Lite._
import  chisel.axiutils.registers._
import  chisel3._
import  chisel3.util._
import  scala.util.Properties.{lineSeparator => NL}

/** Configuration object for Axi4LiteRegisterFile.
 *  @param addrGranularity Smallest addressable bit width (default: 8, e.g., 1 byte).
 *  @param width Register data width (in bits).
 *  @param regs Map from offsets in addrGranularity to register implementations.
 **/
case class Axi4LiteRegisterFileConfiguration(addrGranularity: Int = 32, regs: Map[Int, ControlRegister])
                                            (implicit axi: Configuration) {
  /* internal helpers: */
  private def overlap(p: (BitRange, BitRange)) = p._1.overlapsWith(p._2)
  private def makeRange(a: Int): BitRange = BitRange(a * addrGranularity + axi.dataWidth.toInt - 1, a * addrGranularity)
  private lazy val m = regs.keys.toList.sorted map makeRange
  private lazy val o: Seq[Boolean] = (m.take(m.length - 1) zip m.tail) map overlap

  /* constraint checking */
  require (regs.size > 0, "regs must not be empty")
  require (regs.size == 1 || !(o reduce (_||_)), "ranges must not overlap: " + regs)

  /** Minimum bit width of address lines. */
  lazy val minAddrWidth: AddrWidth =
    AddrWidth(Seq(log2Ceil(regs.size * axi.dataWidth.toInt / addrGranularity), log2Ceil(regs.keys.max)).max)

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
 * @param cfg Configuration object.
 * @param axi Implicit AXI configuration.
 **/
class Axi4LiteRegisterFileIO(cfg: Axi4LiteRegisterFileConfiguration)(implicit axi: Configuration) extends Bundle {
  val addrWidth: AddrWidth = AddrWidth(Seq(cfg.minAddrWidth:Int, axi.addrWidth:Int).max)
  val saxi = Slave(axi)
}

/**
 * Axi4LiteRegisterFile implements a register file:
 * Writes currently take at least 3 cycles (addr -> data -> response), reads at least 2 (addr -> response).
 * No strobe support, always read/write full register width.
 * @param cfg Configuration object.
 * @param axi Implicit AXI configuration.
 **/
class Axi4LiteRegisterFile(cfg: Axi4LiteRegisterFileConfiguration)(implicit axi: Configuration) extends Module {
  /** HARDWARE **/
  val io = IO(new Axi4LiteRegisterFileIO(cfg))

  /** states: ready for address, transferring **/
  val ready :: fetch :: transfer :: response :: Nil = Enum(4)

  /** READ PROCESS **/
  val r_state = RegInit(ready)            // read state
  val r_data  = Reg(UInt(axi.dataWidth))  // read data buffer
  val r_addr  = Reg(UInt(axi.addrWidth))  // read address

  io.saxi.readAddr.ready     := r_state === ready
  io.saxi.readData.valid     := r_state === transfer
  io.saxi.readData.bits.data := r_data
  io.saxi.readData.bits.resp := Response.slverr

  when (reset) {
    r_data                 := "hDEADBEEF".U
    r_state                := ready
    io.saxi.readAddr.ready := false.B
    io.saxi.readData.valid := false.B
  }
  .otherwise {
    // assign data from reg
    for (off <- cfg.regs.keys.toList.sorted) {
      when (r_addr === off.U) {
        cfg.regs(off).read() map { v => r_data := v; io.saxi.readData.bits.resp := 0.U }
      }
    }

    // address receive state
    when (r_state === ready && io.saxi.readAddr.valid) {
      assert(io.saxi.readAddr.bits.prot.prot === 0.U, "Axi4LiteRegisterFile: read does not support PROT")
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
  val w_state = RegInit(ready)             // write state
  val w_data  = Reg(UInt(axi.dataWidth))   // write data buffer
  val w_addr  = Reg(UInt(axi.addrWidth))   // write address
  val w_resp  = Reg(UInt(2.W))             // write response

  w_resp                       := Response.slverr
  io.saxi.writeResp.bits.bresp := w_resp
  io.saxi.writeResp.valid      := w_state === response
  io.saxi.writeData.ready      := w_state === transfer
  io.saxi.writeAddr.ready      := w_state === ready

  when (reset) {
    w_data                  := "hDEADBEEF".U
    w_state                 := ready
    io.saxi.writeAddr.ready := false.B
    io.saxi.writeData.ready := false.B
    io.saxi.writeResp.valid := false.B
  }
  .otherwise {
    // address receive state
    when (w_state === ready) {
      when (io.saxi.writeAddr.valid) {
        assert(io.saxi.readAddr.bits.prot.prot === 0.U, "Axi4LiteRegisterFile: write does not support PROT")
        w_addr  := io.saxi.writeAddr.bits.addr
        w_state := transfer
        printf("Axi4LiteRegisterFile: received write address 0x%x\n", io.saxi.writeAddr.bits.addr)
      }
    }
    // data transfer state
    when (w_state === transfer && io.saxi.writeData.valid) {
      // TODO assert strobes; implement logic to return slverr when strobes not set
      w_state := response
      // assign data to reg
      for (off <- cfg.regs.keys.toList.sorted) {
        when (w_addr === off.U) {
          printf("Axi4LiteRegisterFile: writing 0x%x to register with offset %d\n", w_data, off.U)
          w_resp := Mux(cfg.regs(off).write(io.saxi.writeData.bits.data).B, Response.okay, Response.slverr)
        }
      }
    }
    // write response state
    when (w_state === response && io.saxi.writeResp.ready) { w_state := ready }
  }
}
