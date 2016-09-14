package chisel.axiutils
import chisel.miscutils.DataWidthConverter
import AXIDefs.AXIMasterIF
import Chisel._

/**
 * Configuration parameters for an AxiSlidingWindow.
 * @param gen Underlying element type.
 * @param width Width of gen type in bits (TODO infer bitwidth of gen)
 * @param depth Depth of the sliding window (accessible elements).
 * @param axicfg AXI interface configuration.
 **/
sealed case class AxiSlidingWindowConfiguration[T](
  gen: T,
  width: Int,
  depth: Int,
  afa: AxiFifoAdapterConfiguration
)

/**
 * I/O Bundle for an AxiSlidingWindow:
 * Consists of base address input, AXI master interface and access
 * to the elements of the sliding window.
 * @param cfg Configuration parameters.
 **/
class AxiSlidingWindowIO[T <: Data](cfg: AxiSlidingWindowConfiguration[T]) extends Bundle {
  val base = UInt(INPUT, width = cfg.afa.axi.addrWidth)
  val maxi = new AXIMasterIF(cfg.afa.axi.addrWidth, cfg.afa.axi.dataWidth, cfg.afa.axi.idWidth)
  val data = Decoupled(Vec.fill(cfg.depth) { cfg.gen.cloneType.asOutput })

  def renameSignals() = {
    base.setName("BASE")
    data.ready.setName("DATA_READY")
    data.valid.setName("DATA_VALID")
    for (i <- 0 until cfg.depth) data.bits(i).setName("DATA_%02d".format(i))
    maxi.renameSignals(None, None)
  }
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
class AxiSlidingWindow[T <: Data](val cfg: AxiSlidingWindowConfiguration[T]) extends Module {
  val io = new AxiSlidingWindowIO(cfg)
  io.renameSignals()

  /** AXI DMA engine **/
  val afa = Module(AxiFifoAdapter(cfg.afa))
  /** insert data width conversion step, if required **/
  val data_in = if (cfg.afa.axi.dataWidth == cfg.width) {
      afa.io.deq
    } else {
      val dwc = Module(new DataWidthConverter(cfg.afa.axi.dataWidth, cfg.width, littleEndian = false))
      dwc.io.inq <> afa.io.deq
      dwc.io.deq
    }
  /** backing buffer for accessible elements **/
  val mem = Reg(Vec.fill(cfg.depth) { cfg.gen.cloneType })

  /** States: initial filling of buffer, full **/
  val init :: full :: Nil = Enum(UInt(), 2)
  /** state register **/
  val state = Reg(init = init)
  /** fill level **/
  val cnt = Reg(UInt(width = log2Up(cfg.depth)))

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
      mem(0) := data_in.bits
      for (i <- 1 until cfg.depth)
        mem(i) := mem(i - 1)

      when (state === init) {
        cnt := cnt + UInt(1)
        when (cnt === UInt(cfg.depth - 1)) { state := full }
      }
    }
  }
}

/** AxiSlidingWindow companion object: Factory methods. **/
object AxiSlidingWindow {
  def apply[T <: Data](cfg: AxiSlidingWindowConfiguration[T]): AxiSlidingWindow[T] =
    new AxiSlidingWindow(cfg)
}
