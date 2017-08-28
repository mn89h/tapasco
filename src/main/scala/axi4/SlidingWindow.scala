package chisel.axiutils
import  chisel.miscutils.{DataWidthConverter, Logging}
import  chisel.axi._
import  chisel3._
import  chisel3.util._

object SlidingWindow {
  /** Configuration parameters for a SlidingWindow.
   *  @param gen Underlying element type.
   *  @param width Width of gen type in bits (TODO infer bitwidth of gen)
   *  @param depth Depth of the sliding window (accessible elements).
   *  @param axicfg AXI interface configuration.
   **/
  sealed case class Configuration[T <: Data](gen: T,
                                             width: Int,
                                             depth: Int,
                                             afa: AxiFifoAdapter.Configuration)

  /**
   * I/O Bundle for an AxiSlidingWindow:
   * Consists of base address input, AXI master interface and access
   * to the elements of the sliding window.
   * @param cfg Configuration parameters.
   **/
  class IO[T <: Data](cfg: Configuration[T])
                     (implicit axi: Axi4.Configuration) extends Bundle {
    val base = Input(UInt(axi.addrWidth))
    val maxi = Axi4.Master(axi)
    val data = Decoupled(Vec(cfg.depth, cfg.gen))
  }

  def apply[T <: Data](cfg: SlidingWindow.Configuration[T])
                      (implicit axi: Axi4.Configuration,
                       logLevel: Logging.Level): SlidingWindow[T] =
    new SlidingWindow(cfg)
}

/**
 * AxiSlidingWindow provides a one-dimensional, fixed-size sliding 
 * window backed by an AXI-MM master DMA engine:
 * Starting at a programmable base address, the module will fetch
 * data via its AXI master interface and provide a window of
 * configurable depth; at each handshake, the window is shifted by
 * one element.
 * @param cfg Configuration parameters.
 **/
class SlidingWindow[T <: Data](val cfg: SlidingWindow.Configuration[T])
                              (implicit axi: Axi4.Configuration,
                               logLevel: Logging.Level) extends Module {
  val io = IO(new SlidingWindow.IO(cfg))

  /** AXI DMA engine **/
  val afa = Module(AxiFifoAdapter(cfg.afa))
  /** insert data width conversion step, if required **/
  val data_in = if ((axi.dataWidth:Int) == cfg.width) {
      afa.io.deq
    } else {
      val dwc = Module(new DataWidthConverter(axi.dataWidth, cfg.width, littleEndian = false))
      dwc.io.inq <> afa.io.deq
      dwc.io.deq
    }
  /** backing buffer for accessible elements **/
  val mem = Reg(Vec(cfg.depth, cfg.gen))

  /** States: initial filling of buffer, full **/
  val init :: full :: Nil = Enum(2)
  /** state register **/
  val state = RegInit(init)
  /** fill level **/
  val cnt = Reg(UInt(log2Ceil(cfg.depth).W))

  // input readiness is wired through to data input
  data_in.ready := Mux(state === init, !reset, io.data.ready)
  io.data.valid := state === full && data_in.valid

  for (i <- 0 until cfg.depth)
    io.data.bits(i) := mem(i)

  // base is wired through
  afa.io.base := io.base

  // connect AFA M-AXI to outside
  io.maxi <> afa.io.maxi

  when (!reset) {
    // shift data on handshake
    when (data_in.ready && data_in.valid) {
      mem(cfg.depth - 1) := data_in.bits
      for (i <- 0 until cfg.depth - 1)
        mem(i) := mem(i + 1)

      when (state === init) {
        cnt := cnt + 1.U
        when (cnt === (cfg.depth - 1).U) { state := full }
      }
    }
  }
}
