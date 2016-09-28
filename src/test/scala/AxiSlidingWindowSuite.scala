package chisel.axiutils
import Chisel._
import org.scalatest.junit.JUnitSuite
import org.scalatest.Assertions._
import org.junit.Test
/**
 * Test module for AxiSlidingWindow:
 * Connects AxiSlidingWindow instance to AXI slave model.
 **/
class AxiSlidingWindowTestModule[T <: Data](cfg: AxiSlidingWindowConfiguration[T])(implicit axi: AxiConfiguration) extends Module {
  val io = new Bundle

  /** AXI memory model **/
  val saxi = Module(new AxiSlaveModel(AxiSlaveModelConfiguration(
      addrWidth = Some(axi.addrWidth),
      dataWidth = axi.dataWidth,
      idWidth = axi.idWidth,
      size = Some(1024)
    )))
  /** AxiSlidingWindow instance (DUT) **/
  val asw = Module(new AxiSlidingWindow(cfg))
  asw.io.maxi <> saxi.io.saxi
  val ready = Reg(init = Bool(false))
  asw.io.data.ready := ready
  val base = Reg(init = UInt(0, width = cfg.afa.axi.addrWidth))
  asw.io.base := base
}

/**
 * Tester class for AxiSlidingWindow:
 * Fills memory model with increasing integers of configured element width,
 * then checks sliding window against expected values at each step.
 * Does not operate at full speed, each step has at least one cycle delay.
 **/
class AxiSlidingWindowTester[T <: Data](m: AxiSlidingWindowTestModule[T], isTrace: Boolean = false) extends Tester(m, isTrace) {
  // fill memory model
  AxiSlaveModel.fillWithLinearSeq(m.saxi, m.asw.cfg.width)(this)
  reset(10) // reset
  
  var noErrors = true
  var start = 0
  val maxData = scala.math.pow(2, m.asw.cfg.width).toInt
  val totalSteps = (m.saxi.cfg.size * m.saxi.cfg.dataWidth) / m.asw.cfg.width - m.asw.cfg.depth
  printf("mem size = %d bytes, total steps = %d".format(m.saxi.cfg.size, totalSteps))
  // wait for data to be valid
  while (peek(m.asw.io.data.valid) == 0) step(1)
  // check all sliding windows within size of memory slave (no border handling)
  for (i <- 0 until totalSteps if noErrors) {
    val expected = (0 until m.asw.cfg.depth) map (i => (i + start) % maxData)
    val found = (0 until m.asw.cfg.depth) map (i => peek(m.asw.io.data.bits)(m.asw.cfg.depth - i - 1))
    noErrors = expected.equals(found)
    if (!noErrors)
      println("Mismatch at step #%d: expected %s, found %s".format(start, expected.toString, found.toString))
    expect(noErrors, "sliding window #%d should match".format(i))
    start += 1
    // advance simulation with handshake
    poke(m.ready, true)
    step(1)
    poke(m.ready, false)
    // wait for next valid
    while (peek(m.asw.io.data.valid) == 0) step(1)
  }
}

/** Unit test suite for AxiSlidingWindow. **/
class AxiSlidingWindowSuite extends JUnitSuite {
  val chiselArgs = Array("--backend", "c", "--genHarness", "--compile", "--test", "--vcd")
  implicit val axi: AxiConfiguration = AxiConfiguration(addrWidth = 32, dataWidth = 64, idWidth = 1)
  implicit val afa: AxiFifoAdapterConfiguration = AxiFifoAdapterConfiguration(
      axi = axi,
      fifoDepth = 16
    )

  private def slidingWindow(width: Int, depth: Int)(implicit afa: AxiFifoAdapterConfiguration) = {
    val args = chiselArgs ++ Array("--targetDir", "test/slidingWindow/%dx%d".format(width, depth))
    val cfg = AxiSlidingWindowConfiguration(
        gen = UInt(width = width),
        depth = depth,
        width = width,
        afa = afa
      )

    chiselMainTest(args, () => Module(new AxiSlidingWindowTestModule(cfg)))
      { m => new AxiSlidingWindowTester(m, true) }
  }

  @Test def slidingWindow_8_3    { slidingWindow(8, 3) }
  @Test def slidingWindow_16_8   { slidingWindow(16, 3) }
  @Test def slidingWindow_32_8   { slidingWindow(32, 3) }
  @Test def slidingWindow_8_10   { slidingWindow(8, 10) }
  @Test def slidingWindow_16_10  { slidingWindow(16, 10) }
  @Test def slidingWindow_32_10  { slidingWindow(32, 10) }
  @Test def slidingWindow_8_16   { slidingWindow(8, 16) }
  @Test def slidingWindow_16_16  { slidingWindow(16, 16) }
  @Test def slidingWindow_32_16  { slidingWindow(32, 16) }
}
