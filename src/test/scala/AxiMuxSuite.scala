package chisel.axiutils
import Chisel._
import org.scalatest.junit.JUnitSuite
import org.scalatest.Assertions._
import org.junit.Test
/**
 * Read test module for AxiMux:
 * Checks parallel reads from multiple AXI-MM masters.
 * @param n Number of parallel masters.
 * @param axi Implicit AXI interface configuration.
 **/
class AxiMuxReadTestModule(val n: Int)(implicit axi: AxiConfiguration) extends Module {
  val io = new Bundle
  val mux = Module(new AxiMux(n))
  private val asmcfg = AxiSlaveModelConfiguration(
    addrWidth = Some(axi.addrWidth),
    dataWidth = axi.dataWidth,
    idWidth   = axi.idWidth,
    size      = Some(n * 128)
  )
  val saxi = Module(new AxiSlaveModel(asmcfg))
  private val afacfg = AxiFifoAdapterConfiguration(
    axi = axi,
    fifoDepth = 8,
    burstSize = Some(4)
  )
  val afa = for (i <- 0 until n) yield Module(new AxiFifoAdapter(afacfg))
  val bases = (0 until n) map (_ * 128 * (axi.dataWidth / 8))

  mux.io.maxi <> saxi.io.saxi
  ((afa zip mux.io.saxi) zip bases) map { case ((a, s), b) => {
    a.io.maxi <> s
    a.io.base := UInt(b)
    a.io.deq.ready := Bool(true)
  }}
}

/**
 * Unit test for reading across an AxiMux module:
 * Connects multiple AxiFifoAdapters with increasing base addresses 
 * to single AxiSlaveModel and checks the data for correctness.
 * No performance measurement!
 * @param m Test module.
 * @param isTrace if true, will enable tracing in Chisel Tester.
 **/
class AxiMuxReadTester(m: AxiMuxReadTestModule, isTrace: Boolean = false) extends Tester(m, isTrace) {
  implicit val tester = this
  AxiSlaveModel.fillWithLinearSeq(m.saxi, m.saxi.cfg.dataWidth)
  reset(10)

  var counter: Array[Int] = Array.fill[Int](m.n)(0)
  def finished: Boolean = counter map (_ >= 128) reduce (_&&_)
  def handshake(i: Int) = peek(m.afa(i).io.deq.ready) != 0 && peek(m.afa(i).io.deq.valid) != 0
  
  while (! finished) {
    for (i <- 0 until m.n if handshake(i)) {
      val ok = peek(m.afa(i).io.deq.bits) == counter(i) + i * 128
      assert(ok)
      if (ok) counter(i) += 1
    }
    step(1)
  }
}

/**
 * Unit test suit for AxiMux.
 **/
class AxiMuxSuite extends JUnitSuite {
  val chiselArgs = Array("--backend", "c", "--genHarness", "--compile", "--test", "--vcd")
  implicit val axi = AxiConfiguration(addrWidth = 32, dataWidth = 64, idWidth = 1)

  private def testMuxRead(n: Int) = {
    val args = chiselArgs ++ Array("--targetDir", "test/AxiMuxSuite/%02d".format(n))
    chiselMainTest(args, () => Module(new AxiMuxReadTestModule(n)))
      { m => new AxiMuxReadTester(m, true) }
  }

  @Test def testMuxRead1  { testMuxRead( 1) }
  @Test def testMuxRead2  { testMuxRead( 2) }
  @Test def testMuxRead3  { testMuxRead( 3) }
  @Test def testMuxRead10 { testMuxRead(10) }
}
