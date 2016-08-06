package chisel.miscutils
import Chisel._

/**
 * Interface for DecoupledDataSource.
 **/
class DecoupledDataSourceIO[T <: Data](gen: T) extends Bundle {
  val out = Decoupled(gen.cloneType)
}

/**
 * Data source providing fixed data via Decoupled interface.
 * Provides the data given via Decoupled handshakes; if repeat
 * is true, data is wrapped around.
 * @param gen Type.
 * @param size Total number of elements.
 * @param data Function providing data for each index
 * @param repeat If true, will always have data via wrap-around,
                 otherwise valid will go low after data was
		 consumed.
 **/
class DecoupledDataSource[T <: Data](gen: T, val size : Int, data: (Int) => T, val repeat: Boolean = true) extends Module {

  println ("DecoupledDataSource: size = %d, repeat = %s".format(size, if (repeat) "true" else "false"))
  println("  width = %d".format(log2Up(if (repeat) size else size + 1)))


  val ds  = for (i <- 0 until size) yield data(i) // evaluate data to array
  val io  = new DecoupledDataSourceIO(gen) // interface
  val i   = Reg(UInt(width = log2Up(if (repeat) size else size + 1))) // index
  val rom = Vec.tabulate(size)(n => ds(n)) // ROM with data
  io.out.bits  := rom(i) // current index data
  io.out.valid := !reset && i < UInt(size) // valid until exceeded
  when (reset) {
    i := UInt(0)
  }
  .otherwise {
    if (repeat)
      when (io.out.ready && io.out.valid) { i := i + UInt(1) }
    else
      when (io.out.ready && io.out.valid && i < UInt(size)) { i := i + UInt(1) }
  }
}
