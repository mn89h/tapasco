package chisel.axiutils.axi4
import  chisel.axiutils._
import  chisel.miscutils.Logging
import  chisel3._
import  chisel3.util._
import  chisel3.iotesters.{ChiselFlatSpec, Driver, PeekPokeTester}
import  chisel.axi._

/**
 * Read test module for AxiMux:
 * Checks parallel reads from multiple AXI-MM masters.
 * @param n Number of parallel masters.
 * @param axi Implicit AXI interface configuration.
 **/
class AxiMuxReadTestModule(val n: Int)
                          (implicit axi: Axi4.Configuration,
                           logLevel: Logging.Level) extends Module {
  val io = IO(new Bundle {
    val afa_deq_ready = Output(UInt(n.W))
    val afa_deq_valid = Output(UInt(n.W))
    val afa_deq_bits  = Input(Vec(n, UInt(axi.dataWidth)))
  })
  val mux = Module(new AxiMux(n))
  private val asmcfg = SlaveModel.Configuration(size = Some(n * 128))
  val saxi = Module(new SlaveModel(asmcfg))
  private val afacfg = AxiFifoAdapter.Configuration(fifoDepth = 8, burstSize = Some(4))
  val afa = for (i <- 0 until n) yield Module(new AxiFifoAdapter(afacfg))
  val bases = (0 until n) map (_ * 128 * (axi.dataWidth / 8))

  mux.io.maxi <> saxi.io.saxi
  ((afa zip mux.io.saxi) zip bases) map { case ((a, s), b) => {
    a.io.maxi      <> s
    a.io.base      := b.U
    a.io.deq.ready := true.B
  }}
  afa.zipWithIndex map { case (a, i) =>
    io.afa_deq_ready(i) := a.io.deq.ready
    io.afa_deq_valid(i) := a.io.deq.valid
    io.afa_deq_bits(i)  <> a.io.deq.bits
  }
}

/**
 * Unit test for reading across an AxiMux module:
 * Connects multiple AxiFifoAdapters with increasing base addresses 
 * to single SlaveModel and checks the data for correctness.
 * No performance measurement!
 * @param m Test module.
 * @param isTrace if true, will enable tracing in Chisel PeekPokeTester.
 **/
class AxiMuxReadTester(m: AxiMuxReadTestModule)
                      (implicit axi: Axi4.Configuration) extends PeekPokeTester(m) {
  implicit val tester = this
  SlaveModel.fillWithLinearSeq(m.saxi, axi.dataWidth)
  reset(10)

  var counter: Array[Int] = Array.fill[Int](m.n)(0)
  def finished: Boolean = counter map (_ >= 128) reduce (_&&_)
  def handshake(i: Int) = peek(m.io.afa_deq_ready) != 0 && peek(m.io.afa_deq_valid) != 0
  
  while (! finished) {
    for (i <- 0 until m.n if handshake(i)) {
      val ok = peek(m.io.afa_deq_bits(i)) == counter(i) + i * 128
      assert(ok)
      if (ok) counter(i) += 1
    }
    step(1)
  }
}

/**
 * Unit test suit for AxiMux.
 **/
class AxiMuxSuite extends ChiselFlatSpec {
  implicit val logLevel = Logging.Level.Info
  val chiselArgs = Array("--fint-write-vcd")
  implicit val axi = Axi4.Configuration(addrWidth = AddrWidth(32), dataWidth = DataWidth(64))

  private def testMuxRead(n: Int) = {
    val args = chiselArgs ++ Array("--target-dir", "test/AxiMuxSuite/%02d".format(n))
    Driver.execute(args, () => new AxiMuxReadTestModule(n))
      { m => new AxiMuxReadTester(m) }
  }

  "testMuxRead1" should "be ok" in  { testMuxRead( 1) }
  "testMuxRead2" should "be ok" in  { testMuxRead( 2) }
  "testMuxRead3" should "be ok" in  { testMuxRead( 3) }
  "testMuxRead10" should "be ok" in { testMuxRead(10) }
}
