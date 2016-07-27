package chisel.axiutils
import Chisel._
import chisel.miscutils.DecoupledDataSource
import org.scalatest.junit.JUnitSuite
import org.junit.Test
import org.junit.Assert._

class FifoAxiAdapterModule1(val dataWidth : Int, size: Int) extends Module {
  val io = new Bundle
  val cfg = AxiSlaveModelConfiguration(dataWidth = dataWidth, size = Some(size))
  val datasrc = Module (new DecoupledDataSource(UInt(width = dataWidth), size = 256, n => UInt(n), false))
  val fad = Module (new FifoAxiAdapter(fifoDepth = size,
                                       addrWidth = log2Up(size),
                                       dataWidth = dataWidth,
                                       burstSize = Some(16)))
  val saxi = Module (new AxiSlaveModel(cfg))

  fad.io.base := UInt(0)
  fad.io.enq  <> datasrc.io.out
  fad.io.maxi <> saxi.io.saxi
}

class FifoAxiAdapterSuite extends JUnitSuite {
  @Test def test1 {
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test/fad", "--compile", "--test"),
        () => Module(new FifoAxiAdapterModule1(dataWidth = 8, size = 256))) { m => new FifoAxiAdapterModule1Test(m) }
  }
}

class FifoAxiAdapterModule1Test(fad: FifoAxiAdapterModule1) extends Tester(fad, isTrace = true) {
  import scala.util.Properties.{lineSeparator => NL}
  private var cc = 0

  // re-define step to output progress info
  override def step(n: Int) {
    super.step(n)
    cc += n
    if (cc % 1000 == 0) println("clock cycle: " + cc)
  }

  def toBinaryString(v: BigInt) =
      "b%%%ds".format(fad.dataWidth).format(v.toString(2)).replace(' ', '0')

  reset(10)
  while (peek(fad.datasrc.io.out.valid) != 0 || peek(fad.fad.fifo.io.count) > 0) step(1)
  step(10) // settle

  // check
  for (i <- 0 until 256) {
    val v = peekAt(fad.saxi.mem, i)
    expect(peekAt(fad.saxi.mem, i) == i, "Mem[%03d] = %d (%s), expected: %d (%s)"
        .format(i, v, toBinaryString(v), i, toBinaryString(i)))
  }
}
