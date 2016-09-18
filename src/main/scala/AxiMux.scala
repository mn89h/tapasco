package chisel.axiutils
import AXIDefs._
import Chisel._

/**
 * I/O Bundle for AXI mux.
 * @param n Number of slave interfaces.
 * @param axi Implicit AXI interface configuration.
 **/
class AxiMuxIO(n: Int)(implicit axi: AxiConfiguration) extends Bundle {
  val saxi = (Vec.fill(n) { new AXIMasterIF(axi.addrWidth, axi.dataWidth, axi.idWidth) }).flip
  val maxi = new AXIMasterIF(axi.addrWidth, axi.dataWidth, axi.idWidth)

  def renameSignals() = {
    for (i <- 0 until n)
      saxi(i).renameSignals(Some("S%02d_".format(i)), None)
    maxi.renameSignals(None, None)
  }
}

/**
 * AxiMux: Connect n AXI-MM masters to one AXI-MM slave.
 * @param n Number of slave interfaces.
 * @param axi Implicit AXI interface configuration.
 **/
class AxiMux(n: Int)(implicit axi: AxiConfiguration) extends Module {
  val io = new AxiMuxIO(n)
  io.renameSignals()

  val waiting :: in_burst :: Nil = Enum(UInt(), 2)

  val r_curr = Reg(UInt(width = log2Up(n)))
  val w_curr = Reg(UInt(width = log2Up(n)))
  val r_state = Reg(init = waiting)
  val w_state = Reg(init = waiting)

  def next_r() = r_curr := Mux(r_curr === UInt(n - 1), UInt(0), r_curr + UInt(1))
  def next_w() = w_curr := Mux(w_curr === UInt(n - 1), UInt(0), w_curr + UInt(1))

  /* tie-offs / wire defaults for connected slaves */
  for (s <- io.saxi) {
    /* READ ADDR */
    s.readAddr.ready     := Bool(false)
    /* READ DATA */
    s.readData.valid     := Bool(false)
    s.readData.bits.data := UInt(0)
    s.readData.bits.id   := UInt(0)
    s.readData.bits.last := Bool(false)
    s.readData.bits.resp := UInt(0)
    /* WRITE ADDR */
    s.writeAddr.ready    := Bool(false)
    /* WRITE DATA */
    s.writeData.ready    := Bool(false)
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
  io.saxi(w_curr).writeAddr.ready := io.maxi.writeAddr.ready
  io.maxi.writeAddr.valid         := io.saxi(w_curr).writeAddr.valid
  io.maxi.writeAddr.bits          := io.saxi(w_curr).writeAddr.bits

  /* WRITE DATA */
  io.saxi(w_curr).writeData.ready := io.maxi.writeData.ready
  io.maxi.writeData.valid         := io.saxi(w_curr).writeData.valid
  io.maxi.writeData.bits          := io.saxi(w_curr).writeData.bits

  when (reset) {
    r_curr := UInt(0)
    w_curr := UInt(0)
  }
  .otherwise {
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
}
