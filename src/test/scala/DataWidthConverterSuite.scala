import Chisel._
import org.scalatest.junit.JUnitSuite
import org.junit.Test
import org.junit.Assert._
import scala.math._

/**
 * DataWidthConverterHarness: Attaches data source to DWC.
 **/
class DataWidthConverterHarness(inWidth: Int, outWidth: Int, littleEndian: Boolean) extends Module {
  val io = new Bundle
  val dwc  = Module(new DataWidthConverter(inWidth, outWidth, false))
  val dsrc = Module(new DecoupledDataSource(UInt(width = inWidth),
                                            Seq(pow(2, inWidth).toInt, 100000).min,
                                            n => UInt(n, width = inWidth),
                                            littleEndian))
  dwc.io.inq       <> dsrc.io.out
  dwc.io.deq.ready := !reset
}

/**
 * Generic tester for DataWidthConverterHarness:
 * Checks that the output matches the input.
 **/
class DataWidthConverter_OutputCheck[T <: UInt](m: DataWidthConverterHarness) extends Tester(m, false) {
  import scala.util.Properties.{lineSeparator => NL}

  var errors: List[String] = List()
  var curr_val = 0
  var curr_byt = if (m.dwc.littleEndian) 0 else m.dwc.ratio - 1
  var curr_idx = 0
  while (curr_idx < m.dsrc.size) {
    if (peek(m.dwc.io.deq.valid) > 0) {
      val v = m.dwc.io.deq.bits
      //println("read %d (0b%s)".format(peek(v).toInt, Integer.toBinaryString(peek(v).toInt)))
      curr_val += peek(v).toInt << (curr_byt * m.dwc.outWidth)
      if (m.dwc.littleEndian)
        curr_byt += 1
      else
        curr_byt -= 1
    }
    if (curr_byt == m.dwc.ratio || curr_byt == -1) {
      if (curr_val != curr_idx) {
       errors = "element #%d should be %d (%d, 0b%s)".format(
           curr_idx,
           curr_idx,
           curr_val,
           Integer.toBinaryString(curr_val)
         ) :: errors
      }
      //println("read whole: %d (0b%s)".format(curr_val, Integer.toBinaryString(curr_val)))
      curr_idx += 1
      curr_val = 0
      if (m.dwc.littleEndian)
        curr_byt = 0
      else
        curr_byt = m.dwc.ratio - 1
    }
    step(1)
  }
  step (20)
  assertTrue (("all elements should match, errors: " :: errors).mkString(NL), errors.length == 0)
}

class DataWidthConverterSuite extends JUnitSuite {
  def downsize(inWidth: Int, outWidth: Int, littleEndian: Boolean = true) = {
    println("testing conversion of %d bit to %d bit, %s ...".format(inWidth, outWidth, if (littleEndian) "little-endian" else "big-endian"))
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test", "--compile", "--test"),
        () => Module(new DataWidthConverterHarness(inWidth, outWidth, littleEndian)))
      { m => new DataWidthConverter_OutputCheck(m) }
  }

  @Test def check2to1le   { downsize(2,   1, true) }
  @Test def check2to1be   { downsize(2,   1, false) }
  @Test def check8to1le   { downsize(8,   1, true) }
  @Test def check8to1be   { downsize(8,   1, false) }
  @Test def check16to4le  { downsize(16,  4, true) }
  @Test def check16to4be  { downsize(16,  4, false) }
  @Test def check16to8le  { downsize(16,  8, true) }
  @Test def check16to8be  { downsize(16,  8, false) }
  @Test def check32to8le  { downsize(32,  8, true) }
  @Test def check32to8be  { downsize(32,  8, false) }
  @Test def check64ot8le  { downsize(64,  8, true) }
  @Test def check64to8be  { downsize(64,  8, false) }
  @Test def check64ot32le { downsize(64, 32, true) }
  @Test def check64to32be { downsize(64, 32, false) }

  //@Test def check2to4le   { downsize(2,  4, true) }
  //@Test def check2to4be   { downsize(2,  4, false) }

  /*@Test def check2to1le   { downsize(2,   1, true) }
  @Test def check2to1be   { downsize(2,   1, false) }
  @Test def check8to1le   { downsize(8,   1, true) }
  @Test def check8to1be   { downsize(8,   1, false) }
  @Test def check16to4le  { downsize(16,  4, true) }
  @Test def check16to4be  { downsize(16,  4, false) }
  @Test def check16to8le  { downsize(16,  8, true) }
  @Test def check16to8be  { downsize(16,  8, false) }
  @Test def check32to8le  { downsize(32,  8, true) }
  @Test def check32to8be  { downsize(32,  8, false) }
  @Test def check64ot8le  { downsize(64,  8, true) }
  @Test def check64to8be  { downsize(64,  8, false) }
  @Test def check64ot32le { downsize(64, 32, true) }
  @Test def check64to32be { downsize(64, 32, false) }*/
}
