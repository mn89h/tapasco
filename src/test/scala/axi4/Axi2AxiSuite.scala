package chisel.axiutils.axi4
import  chisel3._
import  chisel3.util._
import  chisel3.iotesters.{ChiselFlatSpec, Driver, PeekPokeTester}
import  chisel.axi._
import  chisel.axiutils._
import  org.scalatest.junit.JUnitSuite
import  chisel.miscutils.{DecoupledDataSource, Logging}
import  scala.math.{random, pow}

/**
 * Composite test module:
 * Uses FifoAxiAdapter to fill SlaveModel; then reads data from
 * SlaveModel via AxiFifoAdapter.
 **/
class Axi2AxiModule(val fifoDepth: Int = 16, val size: Option[Int])
                   (implicit axi: Axi4.Configuration, l: Logging.Level)
    extends Module with Logging {
  require (size.isEmpty || log2Ceil(size.get) <= axi.addrWidth,
           "size (%d) elements cannot be addressed by %d address bits".format(size.get, axi.addrWidth:Int))

  val io = IO(new Bundle {
    val deq = Decoupled(UInt(axi.dataWidth))
  })

  val sz = size.getOrElse(pow(2, axi.addrWidth.toDouble).toInt / axi.dataWidth)
  val aw = Seq(axi.addrWidth:Int, log2Ceil(sz * (axi.dataWidth / 8))).min
  cinfo ("Axi2AxiModule: address bits = %d, size = %d".format(aw, sz))
  val cfg = SlaveModel.Configuration()

  val data = 0 to sz map (n => n % pow(2, axi.dataWidth:Int).toInt)

  val dsrc = Module(new DecoupledDataSource(
      gen = UInt(axi.dataWidth),
      size = sz, 
      data = data map (_.U),
      repeat = false))

  val fad  = Module(new FifoAxiAdapter(fifoDepth = sz, burstSize = Some(fifoDepth)))
  val saxi = Module(new SlaveModel(cfg))
  val afa  = Module(AxiFifoAdapter(fifoDepth = fifoDepth))
  val base = 0.U(aw.W)

  fad.io.enq <> dsrc.io.out
  saxi.io.saxi.writeAddr <> fad.io.maxi.writeAddr
  saxi.io.saxi.writeData <> fad.io.maxi.writeData
  saxi.io.saxi.writeResp <> fad.io.maxi.writeResp
  saxi.io.saxi.readAddr  <> afa.io.maxi.readAddr
  saxi.io.saxi.readData  <> afa.io.maxi.readData
  // FIXME afa.reset := dsrc.io.out.valid || fad.fifo.io.count > 0.U
  fad.io.base := base
  afa.io.base := base
  io.deq <> afa.io.deq
}

/**
 * Axi2AxiTester uses Axi2AxiModule to test full AXI-M roundtrip:
 * Data is send to memory slave via FifoAxiAdapter, then retrieved
 * via AxiFifoAdapter and compared.
 * Does NOT perform any timing checks, only correctness.
 **/
class Axi2AxiTester(m: Axi2AxiModule)
                   (implicit axi: Axi4.Configuration, l: Logging.Level) extends PeekPokeTester(m) {
  def toBinaryString(v: BigInt): String =
    "b%%%ds".format(axi.dataWidth:Int).format(v.toString(2)).replace(' ', '0')
  private val O = 10000
  private var cc = 0
  private var ccc = O
  override def step(n: Int) = {
    super.step(n)
    cc += n
    ccc -= n
    if (ccc <= 0) {
      println ("cc = %d".format(cc))
      ccc = O
    }
  }

  reset (10)
  poke(m.io.deq.ready, true)
  for (i <- 0 until m.sz) {
    while (peek(m.io.deq.valid) == 0) step (1)
    val v = peek(m.io.deq.bits)
    val e = m.data(i)
    expect (v == e, "mem[%08d] = %d (%s), expected: %d (%s)"
            .format(i, v, toBinaryString(v), e, toBinaryString(e)))
    step(1) // advance sim
  }
  step (20)
}

/** Test suite using both AxiFifoAdapter and FifoAxiAdapter. **/
class Axi2AxiSuite extends ChiselFlatSpec {
  import java.nio.file._
  implicit val logLevel = chisel.miscutils.Logging.Level.Warn

  def run(size: Int, fifoDepth: Int, addrWidth: Int, dataWidth: Int) {
    implicit val axi = Axi4.Configuration(addrWidth = AddrWidth(addrWidth), dataWidth = DataWidth(dataWidth))
    val dir = Paths.get("test")
      .resolve("s%d_aw%d_dw%d".format(size, addrWidth, axi.dataWidth:Int))
      .toString
    Driver.execute(Array("--fint-write-vcd", "--target-dir", dir),
                   () => new Axi2AxiModule(fifoDepth = fifoDepth,
                                           size = Some(size)))
      { m => new Axi2AxiTester(m) }
  }

  "run8bit" should "be ok" in  { run (size = 256, fifoDepth = 4, addrWidth = 32, dataWidth = 8) }
  "run16bit" should "be ok" in { run (size = 256, fifoDepth = 8, addrWidth = 32, dataWidth = 16) }
  "run32bit" should "be ok" in { run (size = 256, fifoDepth = 8, addrWidth = 32, dataWidth = 32) }
  "run64bit" should "be ok" in { run (size = 1024, fifoDepth = 256, addrWidth = 32, dataWidth = 64) }
}
