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
  val dwc  = Module(new DataWidthConverter(inWidth, outWidth, littleEndian))
  val dsrc = Module(new DecoupledDataSource(UInt(width = inWidth),
                                            Seq(Seq(pow(2, inWidth).toInt, dwc.ratio).max, 10000).min,
                                            n => UInt(n % pow(2, inWidth).toInt, width = inWidth),
                                            repeat = false))
  dwc.io.inq       <> dsrc.io.out
  dwc.io.deq.ready := !reset
}

/**
 * Generic tester for DataWidthConverterHarness:
 * Checks that the output matches the input and selected endianess.
 **/
class DataWidthConverter_OutputCheck[T <: UInt](m: DataWidthConverterHarness) extends Tester(m, false) {
  import scala.util.Properties.{lineSeparator => NL}
  var errors: List[String] = List() // error list

  // returns binary string for Int, e.g., 0011 for 3, width 4
  private def toBinaryString(n: BigInt, width: Int) =
    "%%%ds".format(width).format(n.toString(2)).replace(' ', '0')

  // check downsizing mode (inWidth > outWidth)
  def checkDownsizing() = {
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
  }

  // check upsizing mode (inWidth < outWidth)
  def checkUpsizing() = {
    //println("size = %d, ratio = %d".format(m.dsrc.size, m.dwc.ratio))
    var received: List[BigInt] = List() // received words
    var cc: Int = m.dsrc.size * m.dwc.ratio * 100 // upper bound
    // println("cc = %d, %d".format(cc, m.dsrc.size / m.dwc.ratio))
    while (received.length < m.dsrc.size / m.dwc.ratio && cc > 0) {
      if (peek(m.dwc.io.deq.valid) != 0) {
        val v = peek(m.dwc.io.deq.bits)
        received ++= List(v)
        println("received: 0x%x (%s)".format(v, toBinaryString(v, m.dwc.outWidth)))
      }
      step(1)
      cc -= 1
    }
    // now split into its constituents
    val cs = received map (d => toBinaryString(d, m.dwc.outWidth)) map { s =>
        for (i <- 0 until s.length / m.dwc.inWidth)
          yield Integer.parseInt(s.drop(i * m.dwc.inWidth).take(m.dwc.inWidth), 2)
      }
    // order constituents, flatten into error list
    val es = cs map (x => if (m.dwc.littleEndian) x else x.reverse) reduce (_++_) zip (m.dsrc.ds map (v => peek(v).toInt))
    // convert mismatches into errors
    errors = (for (i <- 0 until es.length if es(i)._1 != es(i)._2)
      yield "element #%d: expected 0x%x (%s), found 0x%x (%s)".format(
          i,
          es(i)._2,
          toBinaryString(es(i)._2, m.dwc.inWidth),
          es(i)._1,
          toBinaryString(es(i)._1, m.dwc.inWidth)
        )).toList
  }

  reset(10) // reset for 10 cycles
  if (m.dwc.inWidth > m.dwc.outWidth)
    checkDownsizing()
  else
    checkUpsizing()
  step (20) // settle output

  assertTrue (("all elements should match, errors: " :: errors).mkString(NL), errors.length == 0)
}


class DataWidthConverterSuite extends JUnitSuite {
  def resize(inWidth: Int, outWidth: Int, littleEndian: Boolean = true) = {
    println("testing conversion of %d bit to %d bit, %s ..."
        .format(inWidth, outWidth, if (littleEndian) "little-endian" else "big-endian"))
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", "test", "--compile", "--test"),
        () => Module(new DataWidthConverterHarness(inWidth, outWidth, littleEndian)))
      { m => new DataWidthConverter_OutputCheck(m) }
  }

  // downsizing tests
  @Test def check2to1le   { resize(2,   1, true) }
  @Test def check2to1be   { resize(2,   1, false) }
  @Test def check8to1le   { resize(8,   1, true) }
  @Test def check8to1be   { resize(8,   1, false) }
  @Test def check16to4le  { resize(16,  4, true) }
  @Test def check16to4be  { resize(16,  4, false) }
  @Test def check16to8le  { resize(16,  8, true) }
  @Test def check16to8be  { resize(16,  8, false) }
  @Test def check32to8le  { resize(32,  8, true) }
  @Test def check32to8be  { resize(32,  8, false) }
  @Test def check64ot8le  { resize(64,  8, true) }
  @Test def check64to8be  { resize(64,  8, false) }
  @Test def check64ot32le { resize(64, 32, true) }
  @Test def check64to32be { resize(64, 32, false) }

  // upsizing tests
  @Test def check1to2le   { resize(1,   2, true) }
  @Test def check1to2be   { resize(1,   2, false) }
  @Test def check1to8le   { resize(1,   8, true) }
  @Test def check1to8be   { resize(1,   8, false) }

  @Test def check4to16le  { resize(4,  16, true) }
  @Test def check4to16be  { resize(4,  16, false) }
  @Test def check8to16le  { resize(8,  16, true) }
  @Test def check8to16be  { resize(8,  16, false) }
  @Test def check8to32le  { resize(8,  32, true) }
  @Test def check8to32be  { resize(8,  32, false) }

  @Test def check8ot64le  { resize(8,  64, true) }
  @Test def check8to64be  { resize(8,  64, false) }
  @Test def check32ot64le { resize(32, 64, true) }
  @Test def check32to64be { resize(32, 64, false) }
}
