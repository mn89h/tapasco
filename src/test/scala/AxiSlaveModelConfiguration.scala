package chisel.axiutils
import  chisel3._
import  chisel3.util._
import  chisel.axi._

/**
 * AxiSlaveModelConfiguration configures an AxiSlaveModel instance.
 * @param addrWidth address bits for AXI4 interface.
 * @param dataWidth word width for AXI4 interface.
 * @param idWidth id bits for AXI4 interface.
 * @param size size of memory to model (in dataWidth-sized elements).
 * @param readDelay simulated delay between read address handshake and data.
 * @param writeDelay simulated delay between write address handshake and data.
 **/
class AxiSlaveModelConfiguration(val size: Int,
                                 val readDelay: Int,
                                 val writeDelay: Int)
                                (implicit axi: Axi4.Configuration) {
  require (axi.dataWidth > 0 && axi.dataWidth <= 256, "dataWidth (%d) must be 0 < dataWidth <= 256".format(axi.dataWidth))
  require (axi.idWidth.toInt == 1, "id width (%d) is not supported, use 1bit".format(axi.idWidth))
  require (readDelay >= 0, "read delay (%d) must be >= 0".format(readDelay))
  require (writeDelay >= 0, "write delay (%d) must be >= 0".format(writeDelay))

  override def toString: String =
    "addrWidth = %d, dataWidth = %d, idWidth = %d, size = %d, readDelay = %d, writeDelay = %d"
    .format(axi.addrWidth:Int, axi.dataWidth:Int, axi.idWidth:Int, size, readDelay, writeDelay)
}

object AxiSlaveModelConfiguration {
  /**
   * Construct an AxiSlaveModelConfiguration. Size and address width are optional,
   * but one needs to be supplied to determine simulated memory size.
   * @param size size of memory to model in bytes (optional).
   * @param readDelay simulated delay between read address handshake and data (default: 0).
   * @param writeDelay simulated delay between write address handshake and data (default: 0).
   **/
  def apply(size: Option[Int] = None, readDelay: Int = 30, writeDelay: Int = 120)
           (implicit axi: Axi4.Configuration) = {
    val sz: Int = size.getOrElse(scala.math.pow(2, axi.addrWidth:Int).toInt / axi.dataWidth)
    val aw: Int = Seq(axi.addrWidth:Int, log2Ceil(sz * axi.dataWidth / 8).toInt).min
    new AxiSlaveModelConfiguration(size = sz, readDelay = readDelay, writeDelay = writeDelay)
  }
}
