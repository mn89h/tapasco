package chisel.axi.axi4
import  chisel3._
import  chisel3.util._
import  chisel.axi.Axi4._

object AxiMux {
  /** I/O Bundle for AXI mux.
   *  @param n Number of slave interfaces.
   *  @param axi Implicit AXI interface configuration.
   **/
  class IO(n: Int)(implicit axi: Configuration) extends Bundle {
    val saxi = Vec(n, Slave(axi))
    val maxi = Master(axi)
  }
}

/** Connect n AXI-MM masters to one AXI-MM slave.
 *  @param n Number of slave interfaces.
 *  @param axi Implicit AXI interface configuration.
 **/
class AxiMux(n: Int)(implicit axi: Configuration) extends Module {
  val io = IO(new AxiMux.IO(n))

  // states of the FSM
  val waiting :: in_burst :: Nil = Enum(2)

  val r_curr  = RegInit(UInt(log2Ceil(n).W), 0.U)
  val w_curr  = RegInit(UInt(log2Ceil(n).W), 0.U)
  val r_state = RegInit(waiting)
  val w_state = RegInit(waiting)

  def next_r() = r_curr := Mux(r_curr === (n - 1).U, 0.U, r_curr + 1.U)
  def next_w() = w_curr := Mux(w_curr === (n - 1).U, 0.U, w_curr + 1.U)

  /* tie-offs / wire defaults for connected slaves */
  for (s <- io.saxi) {
    /* READ ADDR */
    s.readAddr.ready     := false.B
    /* READ DATA */
    s.readData.bits.defaults
    s.readData.valid     := false.B
    s.readData.bits.data := 0.U
    s.readData.bits.id   := 0.U
    s.readData.bits.last := false.B
    s.readData.bits.resp := 0.U
    /* WRITE ADDR */
    s.writeAddr.ready    := false.B
    /* WRITE DATA */
    s.writeData.ready    := false.B
    /* WRITE RESP */
    s.writeResp.valid    := false.B
    s.writeResp.bits.defaults
  }

  /* wiring for currently selected slaves */
  /* READ ADDRESS */
  io.saxi(r_curr).readAddr.ready := io.maxi.readAddr.ready
  io.maxi.readAddr.valid := io.saxi(r_curr).readAddr.valid
  io.maxi.readAddr.bits := io.saxi(r_curr).readAddr.bits

  /* READ DATA */
  io.maxi.readData.ready := io.saxi(r_curr).readData.ready
  io.saxi(r_curr).readData.valid := io.maxi.readData.valid
  io.saxi(r_curr).readData.bits := io.maxi.readData.bits

  /* WRITE ADDRESS */
  io.maxi.writeAddr.bits.defaults
  io.saxi(w_curr).writeAddr.ready := io.maxi.writeAddr.ready
  io.maxi.writeAddr.valid         := io.saxi(w_curr).writeAddr.valid
  io.maxi.writeAddr.bits          := io.saxi(w_curr).writeAddr.bits

  /* WRITE DATA */
  io.maxi.writeData.bits.defaults
  io.saxi(w_curr).writeData.ready := io.maxi.writeData.ready
  io.maxi.writeData.valid         := io.saxi(w_curr).writeData.valid
  io.maxi.writeData.bits          := io.saxi(w_curr).writeData.bits

  /* WRITE RESP */
  io.maxi.writeResp.ready := io.saxi(r_curr).writeResp.ready
  io.saxi(r_curr).writeResp.valid := io.maxi.writeResp.valid
  io.saxi(r_curr).writeResp.bits  := io.maxi.writeResp.bits

  when (r_state === waiting) {
    when (io.saxi(r_curr).readAddr.valid) { r_state := in_burst }
    .otherwise { next_r() }
  }
  .otherwise {
    when (io.saxi(r_curr).readData.bits.last) {
      next_r()
      r_state := waiting
    }
  }

  when (w_state === waiting) {
    when (io.saxi(w_curr).writeAddr.valid) { w_state := in_burst }
    .otherwise { next_w() }
  }
  .otherwise {
    when (io.saxi(w_curr).writeData.bits.last) {
      next_w()
      w_state := waiting
    }
  }
}
