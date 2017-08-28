package chisel.axiutils.axi4
import  chisel.axi._
import  chisel.axiutils._
import  chisel.miscutils.Logging
import  chisel3._
import  chisel3.util._
import  chisel3.iotesters.{ChiselFlatSpec, Driver, PeekPokeTester}

/** Test module for SlidingWindow:
 *  Connects SlidingWindow instance to AXI slave model.
 **/
class SlidingWindowTestModule[T <: Data](cfg: SlidingWindow.Configuration[T])
                                        (implicit val axi: Axi4.Configuration,
                                         logLevel: Logging.Level) extends Module {
  val io = IO(new Bundle {
    val ready          = Input(Bool())
    val asw_data_valid = Output(Bool())
    val asw_data_bits  = Output(UInt(axi.dataWidth))
  })

  /** AXI memory model **/
  val saxi = Module(new SlaveModel(SlaveModel.Configuration(size = Some(1024))))
  /** AxiSlidingWindow instance (DUT) **/
  val asw = Module(new SlidingWindow(cfg))
  asw.io.maxi <> saxi.io.saxi
  val ready = RegInit(false.B)
  ready := io.ready
  asw.io.data.ready := ready
  val base = RegInit(0.U(axi.addrWidth: chisel3.internal.firrtl.Width))
  asw.io.base := base
  io.asw_data_valid := asw.io.data.valid
  io.asw_data_bits  := asw.io.data.bits
}

/** Tester class for SlidingWindow:
 *  Fills memory model with increasing integers of configured element width,
 *  then checks sliding window against expected values at each step.
 *  Does not operate at full speed, each step has at least one cycle delay.
 **/
class SlidingWindowTester[T <: Data](m: SlidingWindowTestModule[T]) extends PeekPokeTester(m) {
  // fill memory model
  SlaveModel.fillWithLinearSeq(m.saxi, m.axi.dataWidth)(m.axi, this)
  reset(10) // reset
  
  var noErrors = true
  var start = 0
  val maxData = scala.math.pow(2, m.asw.cfg.width).toInt
  val totalSteps = (m.saxi.cfg.size * m.axi.dataWidth) / m.asw.cfg.width - m.asw.cfg.depth
  printf("mem size = %d bytes, total steps = %d".format(m.saxi.cfg.size, totalSteps))
  // wait for data to be valid
  while (peek(m.io.asw_data_valid) == 0) step(1)
  // check all sliding windows within size of memory slave (no border handling)
  for (i <- 0 until totalSteps if noErrors) {
    val expected = (0 until m.asw.cfg.depth) map (i => (i + start) % maxData)
    val found = (0 until m.asw.cfg.depth) map (i => peek(m.io.asw_data_bits) & (1 << (m.asw.cfg.depth - i - 1)))
    noErrors = expected.equals(found)
    if (!noErrors)
      println("Mismatch at step #%d: expected %s, found %s".format(start, expected.toString, found.toString))
    assert(noErrors, "sliding window #%d should match".format(i))
    start += 1
    // advance simulation with handshake
    poke(m.io.ready, true)
    step(1)
    poke(m.io.ready, false)
    // wait for next valid
    while (peek(m.io.asw_data_valid) == 0) step(1)
  }
}

/** Unit test suite for AxiSlidingWindow. **/
class SlidingWindowSuite extends ChiselFlatSpec {
  implicit val logLevel = Logging.Level.Info
  val chiselArgs = Array("--fint-write-vcd")
  implicit val axi: Axi4.Configuration = Axi4.Configuration(addrWidth = AddrWidth(32), dataWidth = DataWidth(64))
  implicit val afa: AxiFifoAdapter.Configuration = AxiFifoAdapter.Configuration(fifoDepth = 16)

  private def slidingWindow(width: Int, depth: Int)(implicit afa: AxiFifoAdapter.Configuration) = {
    val args = chiselArgs ++ Array("--target-dir", "test/slidingWindow/%dx%d".format(width, depth))
    val cfg = SlidingWindow.Configuration(gen = UInt(width.W),
                                          depth = depth,
                                          width = width,
                                          afa = afa)
    Driver.execute(args, () => new SlidingWindowTestModule(cfg))
      { m => new SlidingWindowTester(m) }
  }

  "slidingWindow_8_3" should "be ok" in    { slidingWindow(8, 3) }
  "slidingWindow_16_8" should "be ok" in   { slidingWindow(16, 3) }
  "slidingWindow_32_8" should "be ok" in   { slidingWindow(32, 3) }
  "slidingWindow_8_10" should "be ok" in   { slidingWindow(8, 10) }
  "slidingWindow_16_10" should "be ok" in  { slidingWindow(16, 10) }
  "slidingWindow_32_10" should "be ok" in  { slidingWindow(32, 10) }
  "slidingWindow_8_16" should "be ok" in   { slidingWindow(8, 16) }
  "slidingWindow_16_16" should "be ok" in  { slidingWindow(16, 16) }
  "slidingWindow_32_16" should "be ok" in  { slidingWindow(32, 16) }
}
