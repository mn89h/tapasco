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
  val d_w = if (inWidth > outWidth) inWidth else outWidth // data register width

  if (inWidth > outWidth)
    downsize()
  else
    upsize()

  private def upsize() = {
    val i = Reg(UInt(width = log2Up(ratio + 1)))
    val d = Reg(UInt(width = outWidth))

    io.inq.ready := !reset && (i =/= UInt(0) || (io.inq.valid && io.deq.ready))
    io.deq.bits  := d
    io.deq.valid := !reset && i === UInt(0)

    when (reset) {
      i := UInt(ratio)
      d := UInt(0)
    }
    .otherwise {
      when (io.inq.ready && io.inq.valid) {
        if (littleEndian)
          d := Cat(io.inq.bits, d) >> UInt(inWidth)
        else
          d := (d << UInt(inWidth)) | io.inq.bits
        i := i - UInt(1)
      }
      when (io.deq.valid && io.deq.ready) {
        i := Mux(io.inq.valid, UInt(ratio - 1), UInt(ratio))
      }
    }
  }

  private def downsize() = {
    val i = Reg(UInt(width = log2Up(ratio + 1)))
    val d = Reg(UInt(width = inWidth))

    io.inq.ready := !reset && (i === UInt(0) || (i === UInt(1) && io.deq.ready))
    if (littleEndian)
      io.deq.bits := d(outWidth - 1, 0)
    else
      io.deq.bits := d(inWidth - 1, inWidth - outWidth)
    io.deq.valid := !reset && i > UInt(0)

    when (reset) {
      i := UInt(0)
      d := UInt(0)
    }
    .otherwise {
      when (i > UInt(0) && io.deq.ready) {
        if (littleEndian)
          d := d >> UInt(outWidth)
        else
          d := d << UInt(outWidth)
        i := i - UInt(1)
      }
      when (io.inq.ready && io.inq.valid) {
        d := io.inq.bits
        i := UInt(ratio)
      }
    }
  }
}

