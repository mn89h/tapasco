package chisel.miscutils
import Chisel._
import org.scalatest.junit.JUnitSuite
import org.junit.Test
import org.junit.Assert._
import scala.math._
import java.nio.file.Paths

/**
 * DataWidthConverterHarness: Correctness test harness.
 * A DecoupledDataSource with random data is connected to a pair
 * of data width converters with inverted params. This circuit
 * must behave exactly like a delay on the input stream (where
 * the length of the delay is 2 * in/out-width-ratio).
 **/
class DataWidthConverterHarness(inWidth: Int, outWidth: Int, littleEndian: Boolean) extends Module {
  val io = new Bundle
  val dwc  = Module(new DataWidthConverter(inWidth, outWidth, littleEndian))
  val dsrc = Module(new DecoupledDataSource(UInt(width = inWidth),
                                            Seq(Seq(pow(2, inWidth).toInt, dwc.ratio).max, 10000).min,
                                            //n => UInt(n % pow(2, inWidth).toInt + 1, width = inWidth),
                                            n => UInt((scala.math.random * pow(2, inWidth)).toInt, width = inWidth),
                                            repeat = false))
  val dwc2 = Module(new DataWidthConverter(outWidth, inWidth, littleEndian))
  dwc.io.inq       <> dsrc.io.out
  dwc2.io.inq      <> dwc.io.deq
  dwc2.io.deq.ready := !reset
}

/**
 * Generic tester for DataWidthConverterHarness:
 * Uses DataWidthConverterHarness class to check output correctness.
 * Tracks incoming data from the data source in expecteds list.
 * Whenever output is valid, it is compared to the expecteds,
 * mismatches are reported accordingly.
 * Does NOT check timing, only correctness of the output values.
 **/
class DataWidthConverter_OutputCheck[T <: UInt](m: DataWidthConverterHarness) extends Tester(m, false) {
  import scala.util.Properties.{lineSeparator => NL}

  // returns binary string for Int, e.g., 0011 for 3, width 4
  private def toBinaryString(n: BigInt, width: Int) =
    "%%%ds".format(width).format(n.toString(2)).replace(' ', '0')

  /** Performs data correctness check. **/
  def check() = {
    var i = 0
    var expecteds: List[BigInt] = List()
    def running = peek(m.dsrc.io.out.valid) > 0 ||
                  peek(m.dwc.io.inq.valid) > 0 ||
                  peek(m.dwc.io.deq.valid) > 0 ||
                  peek(m.dwc2.io.inq.valid) > 0 ||
                  peek(m.dwc2.io.deq.valid) > 0
    while (running) {
      // scan output element and add to end of expected list
      if (peek(m.dsrc.io.out.valid) > 0 && peek(m.dwc.io.inq.ready) > 0) {
        val e = peek(m.dsrc.io.out.bits)
        expecteds = expecteds :+ e
        println ("adding expected value: %d (%s)".format(e, toBinaryString(e, m.dwc.inWidth)))
      }

      // check output element: must match head of expecteds
      if (peek(m.dwc2.io.deq.valid) > 0 && peek(m.dwc2.io.deq.ready) > 0) {
        val v = peek(m.dwc2.io.deq.bits)
        if (expecteds.isEmpty) {
          val errmsg = "received value output value %d (%s), but none expected yet".format(
            v, toBinaryString(v, m.dwc.inWidth))
          println (errmsg)
          expect(false, errmsg)
        } else {
          if (v == expecteds.head) {
            println ("element #%d ok!".format(i))
          } else  {
            val errmsg = "element #%d wrong: expected %d (%s), found %d (%s)".format(
                i, expecteds.head, toBinaryString(expecteds.head, m.dwc.inWidth),
                v, toBinaryString(v, m.dwc.inWidth))
            println (errmsg)
            expect(v == expecteds.head, errmsg)
          }
          expecteds = expecteds.tail
        }
        i += 1
      }

      // advance sim
      step (1)
    }
  }

  reset(10) // reset for 10 cycles
  check()
  step (20) // settle output
}


/**
 * Checks timing assumptions:
 * Cores must be capable of handling a continuous stream of data, i.e.,
 * output stream must always be continuous, if the input stream is.
 * This class checks this assumption by stepping through two data elems
 * in a continuous fashion, then inserts a short pause and repeats.
 * Does NOT check validity of the data, see other checks above.
 **/
class DataWidthConverter_DataMustBeAvailableImmediately(m: DataWidthConverter) extends Tester(m, true) {
  val v = new java.math.BigInteger("1" * m.inWidth, 2)
  reset (10)
  expect(peek(m.io.inq.ready) != 0, "must be ready immediately after reset")
  for (_ <- 0 to 1) {
  poke(m.io.inq.bits, v)
  poke(m.io.inq.valid, true)
  poke(m.io.deq.ready, true)
  if (m.inWidth > m.outWidth) {
    for (i <- 1 to m.ratio) {
      step (1)
      expect(peek(m.io.deq.valid) != 0, "nibble #%d must be ready after one cycle".format(i))
      if (i != m.ratio)
        expect (peek(m.io.inq.ready) == 0, "input cannot be ready at nibble #%d".format(i))
    }
    expect(peek(m.io.inq.ready) != 0, "must be ready immediately after first word was consumed")
    poke(m.io.inq.bits, 0)
    for (i <- 1 to m.ratio) {
      step (1)
      expect(peek(m.io.deq.valid) != 0, "nibble #%d must be ready after one cycle".format(i))
      if (i != m.ratio)
        expect (peek(m.io.inq.ready) == 0, "input cannot be ready at nibble #%d".format(i))
    }
    poke(m.io.inq.valid, false)
    expect(peek(m.io.inq.ready) != 0, "must be ready immediately after first word was consumed")
    step(1)
    expect(peek(m.io.deq.valid) == 0, "second word must be consumed after one cycle")
  } else {
    for (i <- 1 to m.ratio) {
      step(1)
      expect(peek(m.io.inq.ready) != 0, "word #%d must be consumed after one cycle".format(i))
      if (i != m.ratio)
        expect(peek(m.io.deq.valid) == 0, "output cannot be ready at word #%d".format(i))
    }
    expect(peek(m.io.deq.valid) != 0, "output must be valid with last word")
    expect(peek(m.io.inq.ready) != 0, "input must be ready, when output is dequeued immediately")
    poke(m.io.inq.bits, 0)
    for (i <- 1 to m.ratio) {
      step(1)
      expect(peek(m.io.inq.ready) != 0, "word #%d must be consumed after one cycle".format(i))
      if (i != m.ratio)
        expect(peek(m.io.deq.valid) == 0, "output cannot be ready at word #%d".format(i))
    }
    expect(peek(m.io.deq.valid) != 0, "output must be valid with last word")
    expect(peek(m.io.inq.ready) != 0, "input must be ready, when output is dequeued immediately")
    poke(m.io.inq.valid, false)
    step(1)
    expect(peek(m.io.deq.valid) == 0, "output is invalid immediately after last was consumed")
  }
  step (5)
  }
}


/** Unit test for DataWidthConverter hardware. **/
class DataWidthConverterSuite extends JUnitSuite {
  def resize(inWidth: Int, outWidth: Int, littleEndian: Boolean = true) = {
    println("testing conversion of %d bit to %d bit, %s ..."
        .format(inWidth, outWidth, if (littleEndian) "little-endian" else "big-endian"))
    val dir = Paths.get("test")
                   .resolve("DataWidthConverterSuite")
                   .resolve("%dto%d%s".format(inWidth, outWidth, if (littleEndian) "le" else "be"))
                   .toString
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", dir, "--compile", "--test"),
        () => Module(new DataWidthConverterHarness(inWidth, outWidth, littleEndian)))
      { m => new DataWidthConverter_OutputCheck(m) }
  }

  def dataMustBeAvailableImmediately(inWidth: Int, outWidth: Int, littleEndian: Boolean = true) = {
    val endian = if (littleEndian) "le" else "be"
    println ("testing immediate data availability (%d -> %d, %s) ...".format(inWidth, outWidth, endian))
    val dir = Paths.get("test")
                   .resolve("DataWidthConverterSuite")
                   .resolve("%dto%d%s_data".format(inWidth, outWidth, endian))
                   .toString
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", dir, "--compile", "--test"),
        () => Module(new DataWidthConverter(inWidth, outWidth, littleEndian)))
      { m => new DataWidthConverter_DataMustBeAvailableImmediately(m) }
  }

  // simple test group, can be used for waveform analysis
  /*@Test def data16to4le   { dataMustBeAvailableImmediately(16,  4, true) }
  @Test def data4to16le   { dataMustBeAvailableImmediately(4,  16, true) }
  @Test def check16to4le  { resize(16,  4, true) }
  @Test def check4to16le  { resize(4,  16, true) }
  @Test def check16to4be  { resize(16,  4, false) }
  @Test def check4to16be  { resize(4,  16, false) }*/

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

  // timing behavior checks
  @Test def data2to1le   { dataMustBeAvailableImmediately(2,   1, true) }
  @Test def data2to1be   { dataMustBeAvailableImmediately(2,   1, false) }
  @Test def data8to1le   { dataMustBeAvailableImmediately(8,   1, true) }
  @Test def data8to1be   { dataMustBeAvailableImmediately(8,   1, false) }
  @Test def data16to4le  { dataMustBeAvailableImmediately(16,  4, true) }
  @Test def data16to4be  { dataMustBeAvailableImmediately(16,  4, false) }
  @Test def data16to8le  { dataMustBeAvailableImmediately(16,  8, true) }
  @Test def data16to8be  { dataMustBeAvailableImmediately(16,  8, false) }
  @Test def data32to8le  { dataMustBeAvailableImmediately(32,  8, true) }
  @Test def data32to8be  { dataMustBeAvailableImmediately(32,  8, false) }
  @Test def data64ot8le  { dataMustBeAvailableImmediately(64,  8, true) }
  @Test def data64to8be  { dataMustBeAvailableImmediately(64,  8, false) }
  @Test def data64ot32le { dataMustBeAvailableImmediately(64, 32, true) }
  @Test def data64to32be { dataMustBeAvailableImmediately(64, 32, false) }
}
