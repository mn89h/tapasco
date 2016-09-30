package chisel.axiutils.registers
import chisel.axiutils.{AxiConfiguration, Axi4LiteProgrammableMaster, MasterAction}
import org.scalatest.junit.JUnitSuite
import org.scalatest.Assertions._
import org.junit.Test
import Chisel._

/**
 * Harness for Axi4LiteRegisterFile:
 * Creates a register file using the specified register map, connects an Axi4LiteProgrammableMaster
 * to the register file and programs it with the specified actions.
 * Read data is queued in a FIFO and can be accessed from the outside.
 * When all actions are processed, the `finished` flag is driven high.
 * @param size number of registers
 * @param distance byte distance of registers
 * @param regs register map for register file
 * @param actions master actions to perform
 **/
class RegFileTest(
  val size: Int,
  val off: Int,
  regs: Map[Int, ControlRegister],
  actions: Seq[MasterAction]
)(implicit axi: AxiConfiguration) extends Module {
  val io = new Bundle { val out = Decoupled(UInt(width = axi.dataWidth)); val finished = Bool(OUTPUT) }
  val cfg = new Axi4LiteRegisterFileConfiguration(width = axi.dataWidth, regs = regs)
  val saxi = Module(new Axi4LiteRegisterFile(cfg))
  val m = Module(new Axi4LiteProgrammableMaster(actions))
  m.io.maxi <> saxi.io.saxi
  io.out <> m.io.out
  io.finished := m.io.finished
  m.io.w_resp.ready := Bool(true)
}

/**
 * ReadTester checks attempts to read from all registers.
 * @param m configured RegFileTest module
 * @param isTrace turns on debug output (default: true)
 **/
class ReadTester(m: RegFileTest, isTrace: Boolean = true) extends Tester(m, isTrace) {
  reset(10)
  poke(m.io.out.ready, true)
  var steps = m.size * 10 // no more than 10 clock cycles per read
  for (i <- 1 until m.size + 1 if steps > 0) {
    // wait til output queue is ready
    while (steps > 0 && peek(m.io.out.ready) == 0 || peek(m.io.out.valid) == 0) {
      steps -= 1
      step(1)
    }
    val v = peek(m.io.out.bits)
    val e = BigInt("%02x".format(i) * 4, 16)
    val resp = peek(m.m.io.maxi.readData.bits.resp)
    expect (resp == 0, "read #%d: resp is 0x%x (%d), should be 0 (OKAY)".format(i, resp, resp))
    expect(v == e, "at action #%d, expected: 0x%x (%d) but found %x (%d)".format(i, e, e, v, v))
    step(1)
  }
  expect(peek(m.io.finished) != 0, "finished signal should be true at end of test")
}

/**
 * WriteTester checks attempts to write to all registers.
 * @param m configured RegFileTest module
 * @param isTrace turns on debug output (default: true)
 **/
class WriteTester(m: RegFileTest, isTrace: Boolean = true) extends Tester(m, isTrace) {
  reset(10)
  poke(m.io.out.ready, true)
  println("running for a total of %d steps max ...".format(m.size * 20))
  var steps = m.size * 20 // no more than 10 clock cycles per read+write
  for (i <- 1 until m.size + 1 if steps > 0) {
    while (steps > 0 && (peek(m.io.out.ready) == 0 || peek(m.io.out.valid) == 0)) {
      steps -= 1
      step(1)
    }
    val v = peek(m.io.out.bits)
    val e = BigInt("%02x".format(i) * 4, 16)
    expect(v == e, "at output #%d, expected: 0x%x (%d), found %x (%d)".format(i, e, e, v, v))
    step(1)
  }
  expect(peek(m.io.finished) != 0, "finished signal should be true at end of test")
}

/**
 * InvalidReadTester checks invalid read attempts for proper return code.
 * @param m configured RegFileTest module
 * @param reads number of invalid reads to perform
 * @param isTrace turns on debug output (default: true)
 **/
class InvalidReadTester(m: RegFileTest, reads: Int, isTrace: Boolean = true) extends Tester(m, isTrace) {
  reset(10)
  println("performing %d invalid reads ...")
  var steps = reads * 10
  for (i <- 1 until reads + 1 if steps > 0) {
    while (steps > 0 && (peek(m.m.io.maxi.readData.valid) == 0 || peek(m.m.io.maxi.readData.ready) == 0)) {
      steps -= 1
      step(1)
    }
    val resp = peek(m.m.io.maxi.readData.bits.resp)
    expect (resp == 2, "read #%d: resp is 0x%x (%d), should be 2 (SLVERR)".format(i, resp, resp))
    step(1)
  }
  expect(peek(m.io.finished) != 0, "finished signal should be true at end of test")
}

/**
 * InvalidWriteTester checks invalid write attempts for proper return code.
 * @param m configured RegFileTest module
 * @param writes number of invalid writes to perform
 * @param isTrace turns on debug output (default: true)
 **/
class InvalidWriteTester(m: RegFileTest, writes: Int, isTrace: Boolean = true) extends Tester(m, isTrace) {
  reset(10)
    println("performing %d invalid writes ...".format(writes))
  var steps = writes * 10
  for (i <- 1 until writes + 1 if steps > 0) {
    while (steps > 0 && peek(m.m.io.w_resp.valid) == 0) {
      steps -= 1
      step(1)
    }
    val resp = peek(m.m.io.w_resp.bits)
    expect(resp == 2, "write #%d: resp is 0x%x (%d), should be 2 (SLVERR)".format(i, resp, resp))
    step(1)
  }
  expect(peek(m.io.finished) != 0, "finished signal should be true at end of test")
}

/** Unit test suite for Axi4LiteRegisterFile module. **/
class Axi4LiteRegisterFileSuite extends JUnitSuite {
  // basic Chisel arguments
  val chiselArgs = Array("--backend", "c", "--compile", "--genHarness", "--test", "--vcd")
  // implicit AXI configuration
  implicit val axi = AxiConfiguration(dataWidth = 32, addrWidth = 32, idWidth = 1)

  /** Attempts to read from all registers. **/
  private def readTest(size: Int, off: Int) =  {
    val args = chiselArgs ++ Array("--targetDir", "test/Axi4RegisterFileSuite/read/size_%d_off_%d".format(size, off))
    // fill constant registers with pattern
    val regs = (for (i <- 1 until size + 1) yield
      off * i -> new ConstantRegister(value = BigInt("%02x".format(i) * 4, 16))
    ) toMap
    // read each of the registers in sequence
    val actions = for (i <- 1 until size + 1) yield MasterAction(true, off * i, None)
    // run test
    chiselMainTest(args, () => Module(new RegFileTest(size, off, regs, actions)))
      { m => new ReadTester(m, true) }
  }

  /** Attempts to write to all registers. **/
  private def writeTest(size: Int, off: Int) =  {
    val args = chiselArgs ++ Array("--targetDir", "test/Axi4RegisterFileSuite/write/size_%d_off_%d".format(size, off))
    // fill constant registers with pattern
    val regs = (for (i <- 1 until size + 1) yield
      off * i -> new Register(width = axi.dataWidth)
    ) toMap
    // read each of the registers in sequence
    val actions = (for (i <- 1 until size + 1) yield Seq(
      // first write the register
      MasterAction(false, off * i, Some(BigInt("%02x".format(i) * (axi.dataWidth/8), 16))),
      // then read the new value
      MasterAction(true, off * i, None)
    )) reduce (_++_)
    // run test
    chiselMainTest(args, () => Module(new RegFileTest(size, off, regs, actions)))
      { m => new WriteTester(m, true) }
  }

  /** Attempts to perform invalid reads and checks return code. **/
  private def invalidReads(reads: Int) = {
    val args = chiselArgs ++ Array("--targetDir", "test/Axi4RegisterFileSuite/invalidReads/%d".format(reads))
    // only zero is valid register
    val regs = Map( 0 -> new ConstantRegister(value = 0) )
    // read from increasing addresses (all above 0 are invalid)
    val actions = for (i <- 1 until reads + 1) yield MasterAction(true, i * (axi.dataWidth / 8), None)
    // run test
    chiselMainTest(args, () => Module(new RegFileTest(1, 4, regs, actions)))
      { m => new InvalidReadTester(m, reads, true) }
  }

  /** Attempts to perform invalid writes and checks return code. **/
  private def invalidWrites(writes: Int) = {
    val args = chiselArgs ++ Array("--targetDir", "test/Axi4RegisterFileSuite/invalidWrites/%d".format(writes))
    // only zero is valid register
    val regs = Map( 0 -> new ConstantRegister(value = 0) )
    // write from increasing addresses (all above 0 are invalid)
    val actions = for (i <- 1 until writes + 1) yield MasterAction(false, i * (axi.dataWidth / 8), Some(42))
    // run test
    chiselMainTest(args, () => Module(new RegFileTest(1, 4, regs, actions)))
      { m => new InvalidWriteTester(m, writes, true) }
  }

  /* READ TESTS */
  @Test def read_255_4 { readTest(255, 4) }
  @Test def read_16_16 { readTest(16, 16) }
  @Test def read_4_4 { readTest(4, 4) }
  @Test def read_7_13 { readTest(7, 13) }

  /* WRITE TESTS */
  @Test def write_255_4 { writeTest(255,   4) }
  @Test def write_16_16 { writeTest( 16,  16) }
  @Test def write_4_4   { writeTest(  4,   4) }
  @Test def write_7_13  { writeTest(  7,  13) }

  /* INVALID R/W TESTS */
  @Test def invalidReads_16  { invalidReads(16) }
  @Test def invalidWrites_16 { invalidWrites(16) }
}
