import Chisel._
import chisel.axiutils.FifoAxiAdapter
import chisel.miscutils.DecoupledDataSource
import org.scalatest.junit.JUnitSuite
import org.junit.Test
import org.junit.Assert._

class FifoAxiAdapterModule1(dataWidth : Int, size: Int) extends Module {
  val io = new Bundle
  val datasrc = Module (new DecoupledDataSource(UInt(width = dataWidth), size = 256, n => UInt(n), false))
  val fad = Module (new FifoAxiAdapter(addrWidth = log2Up(size),
      dataWidth = dataWidth, idWidth = 1, size = size))
  val saxi = Module (new AxiSlaveModel(addrWidth = log2Up(size),
      dataWidth = dataWidth, idWidth = 1))

  fad.io.base := UInt(0)
  fad.io.inq  <> datasrc.io.out
  fad.io.maxi <> saxi.io.saxi
}

class FifoAxiAdapterSuite extends JUnitSuite {
  @Test def test1 {
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test", "--compile", "--test"),
        () => Module(new FifoAxiAdapterModule1(dataWidth = 8, size = 256))) { m => new FifoAxiAdapterModule1Test(m) }
  }
}

class FifoAxiAdapterModule1Test(fad: FifoAxiAdapterModule1) extends Tester(fad, false) {
  import scala.util.Properties.{lineSeparator => NL}
  private var cc = 0

  // re-define step to output progress info
  override def step(n: Int) {
    super.step(n)
    cc += n
    if (cc % 1000 == 0) println("clock cycle: " + cc)
  }

  reset(10)
  while (peek(fad.datasrc.io.out.valid) != 0) step(1)
  step(10) // settle

  // check
  var errors: List[String] = List()
  for (i <- 0 until 256) {
    if (peekAt(fad.saxi.mem, i) != i)
      errors = "Mem[%03d] = %d (expected: %d)".format(i, peekAt(fad.saxi.mem, i), i) :: errors
  }
  assertTrue (("mem does not match, errors: " :: errors).mkString(NL), errors.length == 0)
}
