package chisel.miscutils
import Chisel._

/**
 * DataWidthConverter converts the data width of a Queue.
 * Output is provided via a Queue, with increased or decreased
 * data rate, depending on the direction of the conversion.
 * Note: This would be much more useful, if the two Queues
 *       could use different clocks, but multi-clock support
 *       in Chisel is currently unstable.
 * @param inWidth Data width of input Decoupled (bits).
 * @param outWidth Data width of output Decoupled (bits); must
 *                 be integer multiples of each other.
 * @param littleEndian if inWidth &gt; outWidth, determines
 *                     the order of the nibbles (low to high)
 **/
class DataWidthConverter(
    val inWidth: Int,
    val outWidth: Int,
    val littleEndian: Boolean = true
  ) extends Module {

  require (inWidth > 0, "inWidth must be > 0")
  require (outWidth > 0, "inWidth must be > 0")
  require (inWidth != outWidth, "inWidth (%d) must be different from outWidth (%d)"
             .format(inWidth, outWidth))
  require (inWidth % outWidth == 0 || outWidth % inWidth == 0,
           "inWidth (%d) and outWidth (%d) must be integer multiples of each other"
             .format(inWidth, outWidth))

  val io = new Bundle {
    val inq = Decoupled(UInt(width = inWidth)).flip()
    val deq = Decoupled(UInt(width = outWidth))
  }

  val ratio: Int = if (inWidth > outWidth) inWidth / outWidth else outWidth / inWidth
  val d_w = if (inWidth > outWidth) inWidth else outWidth // data register
  val d = Reg(UInt(width = d_w))           // current value
  val d_hs = Reg(Bool())                   // handshake input
  val i = Reg(UInt(width = log2Up(ratio))) // current byte index

  val inq_ready = Reg(Bool())              // input data ready
  val inq_valid = RegNext(io.inq.valid)    // input data valid?
  val deq_ready = RegNext(io.deq.ready)    // output data ready?
  val deq_valid = Reg(Bool())              // output data valid

  inq_ready := !reset && !d_hs
  deq_valid := !reset && d_hs
  
  io.inq.ready := inq_ready
  io.deq.valid := deq_valid

  when (reset) {
    d         := UInt(0)
    d_hs      := Bool(false)
    i         := UInt(if (littleEndian) 0 else ratio - 1)
    inq_ready := Bool(false)
    deq_valid := Bool(false)
  }

  if (inWidth > outWidth) {
    val outFifo = Module(new Queue(UInt(width = outWidth), ratio))
    outFifo.io.deq       <> io.deq
    outFifo.io.enq.bits  := d(i * UInt(outWidth) + UInt(outWidth), i * UInt(outWidth))
    outFifo.io.enq.valid := d_hs
    val out_ready = RegNext(outFifo.io.enq.ready)

    when (reset) {}
    .otherwise {
      when (inq_ready && inq_valid) {
        d := io.inq.bits
        d_hs := Bool(true)
        inq_ready := Bool(false)
      }
      when (d_hs) {
        when (out_ready) {
          if (littleEndian) {
            i := Mux(i === UInt(ratio - 1), UInt(0), i + UInt(1))
            when (i === UInt(ratio - 1)) { d_hs := Bool(false) }
          } else {
            i := Mux(i === UInt(0), UInt(ratio - 1), i - UInt(1))
            when (i === UInt(0)) { d_hs := Bool(false) }
          }
        }
      }
    }
  } else {
    io.deq.bits  := d
    io.deq.valid := d_hs
    val out_ready = RegNext(io.deq.ready)
    when (!d_hs && inq_ready && inq_valid) {
      if (littleEndian) {
        d := (d << UInt(inWidth)) | io.inq.bits
        i := Mux(i === UInt(ratio - 1), UInt(0), i + UInt(1))
        when (i === UInt(ratio - 1)) {
          d_hs      := Bool(true)
          inq_ready := Bool(false)
        }
      } else {
        d := Cat(io.inq.bits, d) >> UInt(inWidth)
        i := Mux(i === UInt(0), UInt(ratio - 1), i - UInt(1))
        when (i === UInt(0)) {
          d_hs      := Bool(true)
          inq_ready := Bool(false)
        }
      }
    }
    when (d_hs && out_ready) {
      d_hs := Bool(false)
      d    := UInt(0)
    }
  }
}

