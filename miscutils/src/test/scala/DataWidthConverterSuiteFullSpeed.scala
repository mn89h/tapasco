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
class DataWidthConverterHarnessFullSpeed(val inWidth: Int, val outWidth: Int, val littleEndian: Boolean) extends Module {
  val io = new Bundle
  val dwc  = Module(new DataWidthConverter(inWidth, outWidth, littleEndian))
  val dsrc = Module(new DecoupledDataSource(UInt(width = inWidth),
                                            Seq(Seq(pow(2, inWidth).toLong, dwc.ratio).max, 10000.toLong).min.toInt,
                                            //n => UInt(n % pow(2, inWidth).toInt + 1, width = inWidth),
                                            n => UInt((scala.math.random * pow(2, inWidth)).toLong, width = inWidth),
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
class DataWidthConverterFullSpeed[T <: UInt](m: DataWidthConverterHarnessFullSpeed) extends Tester(m, false) {
  import scala.util.Properties.{lineSeparator => NL}

  // returns binary string for Int, e.g., 0011 for 3, width 4
  private def toBinaryString(n: BigInt, width: Int) =
    "%%%ds".format(width).format(n.toString(2)).replace(' ', '0')

  /** Performs data correctness at full speed check. **/
  def check() = {
    var i = 0
    var firstOutputReceived = false
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
        firstOutputReceived = true
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

      // check: if upsizing, inq may never block
      if (m.inWidth < m.outWidth) {
        val error = peek(m.dwc.io.inq.ready) == 0 && peek(m.dwc.io.inq.valid) != 0
        if (error)
          println("ERROR: input queue may never block while input is available")
        expect(!error, "upsizing: input queue may not block while input is available")
      }

      // check: if downsizing, deq must remain valid until end
      if (firstOutputReceived && !expecteds.isEmpty && m.inWidth > m.outWidth) {
        if (peek(m.dwc.io.deq.valid) == 0)
          println("ERROR: output queue must remain valid after first element")
        if (peek(m.dwc.io.deq.ready) == 0)
          println("ERROR: output queue must remain ready after first element")
        expect(peek(m.dwc.io.deq.ready) != 0, "downsizing: output queue must remain ready after first")
        expect(peek(m.dwc.io.deq.valid) != 0, "downsizing: output queue must remain valid after first")
      }

      // advance sim
      step (1)
    }
  }

  reset(10) // reset for 10 cycles
  check()
  step (20) // settle output
}


/** Unit test for DataWidthConverter hardware. **/
class DataWidthConverterSuiteFullSpeed extends JUnitSuite {
  def resize(inWidth: Int, outWidth: Int, littleEndian: Boolean = true) = {
    println("testing conversion of %d bit to %d bit, %s ..."
        .format(inWidth, outWidth, if (littleEndian) "little-endian" else "big-endian"))
    val dir = Paths.get("test")
                   .resolve("dwc_fullspeed")
                   .resolve("%dto%d%s".format(inWidth, outWidth, if (littleEndian) "le" else "be"))
                   .toString
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", dir, "--compile", "--test"),
        () => Module(new DataWidthConverterHarnessFullSpeed(inWidth, outWidth, littleEndian)))
      { m => new DataWidthConverterFullSpeed(m) }
  }

  // simple test group, can be used for waveform analysis
  /*@Test def check16to4le  { resize(16,  4, true) }
  @Test def check4to16le  { resize(4,  16, true) }
  @Test def check16to4be  { resize(16,  4, false) }
  @Test def check4to16be  { resize(4,  16, false) }
  @Test def check64to32be  { resize(64,  32, false) }
  @Test def check32to64be  { resize(32,  64, false) }*/

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
