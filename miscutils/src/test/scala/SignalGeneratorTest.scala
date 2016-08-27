package chisel.miscutils
import Chisel._
import SignalGenerator._
import org.scalatest.junit.JUnitSuite
import org.junit.Test
import org.junit.Assert._

class SignalGeneratorComposition1 extends Module {
  val waveform: SignalGenerator.Waveform =
      (for (i <- 2 until 30) yield List((false, 5), (true, i))) reduce (_++_)
  val clock_sg = Module(new SignalGenerator(List((true, 2), (false, 2))))
  val test_sg  = Module(new SignalGenerator(waveform, true))
  val io       = new Bundle { val v = Bool(OUTPUT) }
  test_sg.io.in := clock_sg.io.v
  io.v          := test_sg.io.v
}

class SignalGeneratorSuite extends JUnitSuite {
  @Test def test1 {
    val waveform: SignalGenerator.Waveform =
        (for (i <- 2 until 30) yield List((false, 5), (true, i))) reduce (_++_)
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test/signalgenerator", "--compile", "--test"), () =>
        Module(new SignalGenerator(waveform))
      ) { m => new SignalGeneratorTest(m) }
  }

  @Test def test2 { // same as test1, but with user supplied clock
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test/signalgenerator", "--compile", "--test"), () =>
        Module(new SignalGeneratorComposition1)
      ) { m => new SignalGeneratorComposition1Test(m) }
  }
}

class SignalGeneratorTest(sg: SignalGenerator) extends Tester(sg, false) {
  import scala.util.Properties.{lineSeparator => NL}
  private var cc = 0

  // re-define step to output progress info
  override def step(n: Int) {
    super.step(n)
    cc += n
    if (cc % 1000 == 0) println("clock cycle: " + cc)
  }

  // waits for next positive edge on signal
  def waitForPosEdge[T <: Chisel.Bits](s: T) {
    while(peek(s) > 0) step(1)
    while(peek(s) == 0) step(1)
  }

  // waits for next positive edge on signal
  def waitForNegEdge[T <: Chisel.Bits](s: T) {
    while(peek(s) == 0) step(1)
    while(peek(s) > 0) step(1)
  }

  // the actual test: wait until reset is off
  waitForNegEdge(sg.reset)

  for (j <- 0 to 1) {
    for (i <- 2 until 30) {
      waitForPosEdge(sg.io.v)
      val cc_start = cc
      waitForNegEdge(sg.io.v)
      assertTrue (cc - cc_start == i)
    }
  }
}

class SignalGeneratorComposition1Test(sg: SignalGeneratorComposition1) extends Tester(sg, false) {
  private var cc = 0

  // re-define step to output progress info
  override def step(n: Int) {
    super.step(n)
    cc += n
    if (cc % 1000 == 0) println("clock cycle: " + cc)
  }

  // waits for next positive edge on signal
  def waitForPosEdge[T <: Chisel.Bits](s: T) {
    while(peek(s) > 0) step(1)
    while(peek(s) == 0) step(1)
  }

  // waits for next positive edge on signal
  def waitForNegEdge[T <: Chisel.Bits](s: T) {
    while(peek(s) == 0) step(1)
    while(peek(s) > 0) step(1)
  }

  // the actual test: wait until reset is off
  waitForNegEdge(sg.reset)

  for (j <- 0 to 1) {
    for (i <- 2 until 30) {
      waitForPosEdge(sg.io.v)
      val cc_start = cc
      waitForNegEdge(sg.io.v)
      assertTrue (cc - cc_start == i * 4)
    }
  }
}
