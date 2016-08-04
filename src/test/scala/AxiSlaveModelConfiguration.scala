package chisel.axiutils
import Chisel._

/**
 * AxiSlaveModelConfiguration configures an AxiSlaveModel instance.
 * @param addrWidth address bits for AXI4 interface.
 * @param dataWidth word width for AXI4 interface.
 * @param idWidth id bits for AXI4 interface.
 * @param size size of memory to model (in bytes).
 * @param readDelay simulated delay between read address handshake and data.
 * @param writeDelay simulated delay between write address handshake and data.
 **/
class AxiSlaveModelConfiguration(
  val addrWidth: Int,
  val dataWidth: Int,
  val idWidth: Int,
  val size: Int,
  val readDelay: Int,
  val writeDelay: Int
) {
  require (addrWidth > 0 && addrWidth <= 64, "addrWidth (%d) must be 0 < addrWidth <= 64".format(addrWidth))
  require (dataWidth > 0 && dataWidth <= 256, "dataWidth (%d) must be 0 < dataWidth <= 256".format(dataWidth))
  require (idWidth == 1, "id width (%d) is not supported, use 1bit".format(idWidth))
  require (readDelay >= 0, "read delay (%d) must be >= 0".format(readDelay))
  require (writeDelay >= 0, "write delay (%d) must be >= 0".format(writeDelay))

  override def toString: String =
    "addrWidth = %d, dataWidth = %d, idWidth = %d, size = %d, readDelay = %d, writeDelay = %d"
    .format(addrWidth, dataWidth, idWidth, size, readDelay, writeDelay)
}

object AxiSlaveModelConfiguration {
  /**
   * Construct an AxiSlaveModelConfiguration. Size and address width are optional,
   * but one needs to be supplied to determine simulated memory size.
   * @param addrWidth address bits for AXI4 interface (optional).
   * @param dataWidth word width for AXI4 interface.
   * @param idWidth id bits for AXI4 interface (default: 1).
   * @param size size of memory to model in bytes (optional).
   * @param readDelay simulated delay between read address handshake and data (default: 0).
   * @param writeDelay simulated delay between write address handshake and data (default: 0).
   **/
  def apply(addrWidth: Option[Int] = None, dataWidth: Int, idWidth: Int = 1,
      size: Option[Int] = None, readDelay: Int = 30, writeDelay: Int = 120) = {
    require (!size.isEmpty || !addrWidth.isEmpty, "specify size or addrWidth, or both")
    val sz: Int = size.getOrElse(scala.math.pow(2, addrWidth.get).toInt)
    val aw: Int = addrWidth.getOrElse(log2Up(size.get * dataWidth / 8).toInt)
    new AxiSlaveModelConfiguration(addrWidth = aw, dataWidth = dataWidth, idWidth = idWidth,
        size = sz, readDelay = readDelay, writeDelay = writeDelay)
  }
}
