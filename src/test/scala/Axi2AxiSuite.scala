package chisel.axiutils
import Chisel._
import org.scalatest.junit.JUnitSuite
import org.junit.Test
import org.junit.Assert._
import chisel.miscutils.DecoupledDataSource
import scala.math.{random, pow}

/**
 * Composite test module:
 * Uses FifoAxiAdapter to fill AxiSlaveModel; then reads data from
 * AxiSlaveModel via AxiFifoAdapter.
 **/
class Axi2AxiModule(val dataWidth: Int,
                    val fifoDepth: Int = 16,
                    val size: Option[Int],
                    val addrWidth: Option[Int]) extends Module {

  require (!size.isEmpty || !addrWidth.isEmpty, "specify either size, or addrWidth, or both")

  val io = new Bundle {
    val deq = Decoupled(UInt(width = dataWidth))
  }

  val sz = size.getOrElse(pow(2, addrWidth.get).toInt)
  val aw = addrWidth.getOrElse(log2Up(sz * (dataWidth / 8)))
  println ("Axi2AxiModule: address bits = %d, size = %d".format(aw, sz))
  val cfg = AxiSlaveModelConfiguration(addrWidth = Some(aw), dataWidth = dataWidth, size = size)

  val dsrc = Module(new DecoupledDataSource(
      gen = UInt(width = dataWidth),
      size = sz, 
      //data = n => UInt((random * pow(2, dataWidth)).toInt),
      data = n => UInt(n % pow(2, dataWidth).toInt),
      repeat = false))

  val fad = Module(new FifoAxiAdapter(
      fifoDepth = sz,
      addrWidth = aw,
      dataWidth = dataWidth,
      burstSize = Some(fifoDepth)))

  val saxi = Module(new AxiSlaveModel(cfg))

  val afa = Module(AxiFifoAdapter(
      addrWidth = aw,
      dataWidth = dataWidth,
      idWidth = 1,
      fifoDepth = fifoDepth))

  val base = UInt(0, width = aw)

  fad.io.enq <> dsrc.io.out
  saxi.io.saxi.writeAddr <> fad.io.maxi.writeAddr
  saxi.io.saxi.writeData <> fad.io.maxi.writeData
  saxi.io.saxi.writeResp <> fad.io.maxi.writeResp
  saxi.io.saxi.readAddr  <> afa.io.maxi.readAddr
  saxi.io.saxi.readData  <> afa.io.maxi.readData
  afa.reset := dsrc.io.out.valid || fad.fifo.io.count > UInt(0)
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
class Axi2AxiTester(m: Axi2AxiModule) extends Tester(m) {
  def toBinaryString(v: BigInt): String =
    "b%%%ds".format(m.dataWidth).format(v.toString(2)).replace(' ', '0')
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
    while (peek(m.afa.io.deq.valid) == 0) step (1)
    val v = peek(m.afa.io.deq.bits)
    val e = peek(m.dsrc.ds(i))
    expect (v == e, "mem[%08d] = %d (%s), expected: %d (%s)"
            .format(i, v, toBinaryString(v), e, toBinaryString(e)))
    step(1) // advance sim
  }
  step (20)
}

/** Test suite using both AxiFifoAdapter and FifoAxiAdapter. **/
class Axi2AxiSuite extends JUnitSuite {
  def run(size: Int, fifoDepth: Int, addrWidth: Int, dataWidth: Int) {
    val dir = java.nio.file.Paths.get("test").resolve("s%d_aw%d_dw%d".format(size, addrWidth, dataWidth)).toString
    val args = Array("--backend", "c", "--compile", "--test", "--vcd", "--genHarness", "--targetDir", dir)
    chiselMainTest(args, () => Module(new Axi2AxiModule(
        fifoDepth = fifoDepth,
        dataWidth = dataWidth,
        size = Some(size),
        addrWidth = Some(addrWidth))))
      { m => new Axi2AxiTester(m) }
  }

  @Test def run8bit()  { run (size = 256, fifoDepth = 4, addrWidth = 32, dataWidth = 8) }
  @Test def run16bit() { run (size = 256, fifoDepth = 8, addrWidth = 32, dataWidth = 16) }
  @Test def run32bit() { run (size = 256, fifoDepth = 8, addrWidth = 32, dataWidth = 32) }
  @Test def run64bit() { run (size = 1024, fifoDepth = 256, addrWidth = 32, dataWidth = 64) }
}

