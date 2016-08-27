package chisel.miscutils
import Chisel._
import org.scalatest.junit.JUnitSuite
import org.junit.Test
import org.junit.Assert._

/**
 * Tester class for DecoupledDataSource.
 * Automatically exhausts the internal data of the instance, checks that
 * each dequeued output matches the expected value. Also checks whether
 * or not the module wraps correctly (in case repeat is true).
 **/
class DecoupledDataSource_OutputCheck[T <: UInt](m: DecoupledDataSource[T]) extends Tester(m, false) {
  import scala.util.Properties.{lineSeparator => NL}

  poke(m.io.out.ready, true)
  var errors: List[String] = List()
  var i = 0
  while (peek(m.io.out.valid) > 0 && i <= m.size) {
    if (i >= m.size) {
      if (! m.repeat)
        errors = "repeat is false, but index (%d) exceeds size(%d)".format(i, m.size) :: errors
    } else {
      if (peek(m.io.out.bits) != peek(m.ds(i))) {
        errors = "output #%d: expected %d, found %d".format(i, peek(m.ds(i)), peek(m.io.out.bits)) :: errors
      } else {
        // wait for random time up to 10 cycles
	val wait = (scala.math.random * 10).toInt
	poke(m.io.out.ready, false)
	step(wait)
	poke(m.io.out.ready, true)
      }
    }
    i += 1
    step(1)
  }
  assertTrue (("all elements should match, errors: " :: errors).mkString(NL), errors.length == 0)
}

class DecoupledDataSourceSuite extends JUnitSuite {
  /** Performs randomized tests with random data of random size. **/
  @Test def checkRandomOutputs {
    for (i <- 0 until 1) {
      val cnt    = Seq(1, (scala.math.random * 10000).toInt).max
      val width  = Seq(1, (scala.math.random * 64).toInt).max
      val repeat = scala.math.random > 0.5
      println("testing cnt = %d, width = %d, repeat = %b ...".format(cnt, width, repeat))
      chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test/DecoupledDataSourceSuite/checkRandomOutputs", "--compile", "--test"),
          () => Module(new DecoupledDataSource(UInt(width = width), cnt, i => UInt((scala.math.random * scala.math.pow(2, width)).toInt), repeat)))
        { m => new DecoupledDataSource_OutputCheck(m) }
    }
  }

  /** Performs test for 8bit wide sequential data with repeat. **/
  @Test def checkSequentialOutputsWithRepeat {
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test/DecoupledDataSourceSuite/checkSequentialOutputsWithRepeat", "--compile", "--test"),
      () => Module(new DecoupledDataSource(UInt(width = 8), 256, i => UInt(i), true)))
      { m => new DecoupledDataSource_OutputCheck(m) }
  }

  /** Performs test for 8bit wide sequential data without repeat. **/
  @Test def checkSequentialOutputsWithoutRepeat {
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test/DecoupledDataSourceSuite/checkSequentialOutputWithoutRepeat", "--compile", "--test"),
      () => Module(new DecoupledDataSource(UInt(width = 8), 256, i => UInt(i), false)))
      { m => new DecoupledDataSource_OutputCheck(m) }
  }
}
