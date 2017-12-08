package chisel.axiutils.axi4lite
import  chisel.axi._
import  chisel.miscutils.Logging
import  chisel3._
import  chisel3.util._
import  chisel3.iotesters.{ChiselFlatSpec, Driver, PeekPokeTester}

/**
 * Harness for Axi4Lite RegisterFile:
 * Creates a register file using the specified register map, connects an ProgrammableMaster
 * to the register file and programs it with the specified actions.
 * Read data is queued in a FIFO and can be accessed from the outside.
 * When all actions are processed, the `finished` flag is driven high.
 * @param size number of registers
 * @param distance byte distance of registers
 * @param regs register map for register file
 * @param actions master actions to perform
 **/
class RegFileTest(val size: Int, val off: Int, regs: Map[Int, ControlRegister], actions: Seq[MasterAction])
                 (implicit axi: Axi4Lite.Configuration, logLevel: Logging.Level) extends Module {
  val io = IO(new Bundle {
    val out = Decoupled(UInt(axi.dataWidth))
    val finished = Output(Bool())
    val rresp = Output(chisel.axi.Response.okay.cloneType)
    val wresp = Irrevocable(new chisel.axi.Axi4Lite.WriteResponse)
  })
  val cfg = new RegisterFile.Configuration(regs = regs)
  val saxi = Module(new RegisterFile(cfg))
  val m = Module(new ProgrammableMaster(actions))
  m.io.maxi         <> saxi.io.saxi
  io.out            <> m.io.out
  io.finished       := m.io.finished
  m.io.w_resp.ready := true.B
  io.rresp          := m.io.maxi.readData.bits.resp
  io.wresp          <> saxi.io.saxi.writeResp
}

/**
 * ReadTester checks attempts to read from all registers.
 * @param m configured RegFileTest module
 * @param isTrace turns on debug output (default: true)
 **/
class ReadTester(m: RegFileTest) extends PeekPokeTester(m) {
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
    val resp = peek(m.io.rresp)
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
class WriteTester(m: RegFileTest) extends PeekPokeTester(m) {
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
class InvalidReadTester(m: RegFileTest, reads: Int) extends PeekPokeTester(m) {
  reset(10)
  println("performing %d invalid reads ...")
  var steps = reads * 10
  for (i <- 1 until reads + 1 if steps > 0) {
    while (steps > 0 && (peek(m.io.out.ready) == 0 || peek(m.io.out.valid) == 0)) {
      steps -= 1
      step(1)
    }
    val resp = peek(m.io.out.bits)
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
class InvalidWriteTester(m: RegFileTest, writes: Int) extends PeekPokeTester(m) {
  reset(10)
  println("performing %d invalid writes ...".format(writes))
  var steps = writes * 10
  for (i <- 1 until writes + 1 if steps > 0) {
    while (steps > 0 && peek(m.io.wresp.valid) == 0) {
      steps -= 1
      step(1)
    }
    val resp = peek(m.io.wresp.bits.bresp)
    expect(resp == 2, "write #%d: resp is 0x%x (%d), should be 2 (SLVERR)".format(i, resp, resp))
    step(1)
  }
  expect(peek(m.io.finished) != 0, "finished signal should be true at end of test")
}

/** Unit test suite for Axi4LiteRegisterFile module. **/
class RegisterFileSpec extends ChiselFlatSpec {
  implicit val logLevel = Logging.Level.Info
  // basic Chisel arguments
  val chiselArgs = Array("--fint-write-vcd")
  // implicit AXI configuration
  implicit val axi = Axi4Lite.Configuration(dataWidth = Axi4Lite.Width32, addrWidth = AddrWidth(32))

  /** Attempts to read from all registers. **/
  private def readTest(size: Int, off: Int) =  {
    val args = chiselArgs ++ Array("--target-dir", "test/Axi4RegisterFileSuite/read/size_%d_off_%d".format(size, off))
    // fill constant registers with pattern
    val regs = (for (i <- 1 until size + 1) yield
      off * i -> new ConstantRegister(value = BigInt("%02x".format(i) * 4, 16))
    ).toMap
    // read each of the registers in sequence
    val actions = for (i <- 1 until size + 1) yield MasterAction(true, off * i, None)
    // run test
    Driver.execute(args, () => new RegFileTest(size, off, regs, actions))
      { m => new ReadTester(m) }
  }

  /** Attempts to write to all registers. **/
  private def writeTest(size: Int, off: Int) =  {
    val args = chiselArgs ++ Array("--target-dir", "test/Axi4RegisterFileSuite/write/size_%d_off_%d".format(size, off))
    // fill constant registers with pattern
    val regs = (for (i <- 1 until size + 1) yield
      off * i -> new Register(width = axi.dataWidth)
    ).toMap
    // read each of the registers in sequence
    val actions = (for (i <- 1 until size + 1) yield Seq(
      // first write the register
      MasterAction(false, off * i, Some(BigInt("%02x".format(i) * (axi.dataWidth/8), 16))),
      // then read the new value
      MasterAction(true, off * i, None)
    )) reduce (_++_)
    // run test
    Driver.execute(args, () => new RegFileTest(size, off, regs, actions))
      { m => new WriteTester(m) }
  }

  /** Attempts to perform invalid reads and checks return code. **/
  private def invalidReads(reads: Int) = {
    val args = chiselArgs ++ Array("--target-dir", "test/Axi4RegisterFileSuite/invalidReads/%d".format(reads))
    // only zero is valid register
    val regs = Map( 0 -> new ConstantRegister(value = 0) )
    // read from increasing addresses (all above 0 are invalid)
    val actions = for (i <- 1 until reads + 1) yield MasterAction(true, i * (axi.dataWidth / 8), None)
    // run test
    Driver.execute(args, () => new RegFileTest(1, 4, regs, actions))
      { m => new InvalidReadTester(m, reads) }
  }

  /** Attempts to perform invalid writes and checks return code. **/
  private def invalidWrites(writes: Int) = {
    val args = chiselArgs ++ Array("--target-dir", "test/Axi4RegisterFileSuite/invalidWrites/%d".format(writes))
    // only zero is valid register
    val regs = Map( 0 -> new ConstantRegister(value = 0) )
    // write from increasing addresses (all above 0 are invalid)
    val actions = for (i <- 1 until writes + 1) yield MasterAction(false, i * (axi.dataWidth / 8), Some(42))
    // run test
    Driver.execute(args, () => new RegFileTest(1, 4, regs, actions))
      { m => new InvalidWriteTester(m, writes) }
  }

  /* READ TESTS */
  "read_255_4" should "be ok" in { readTest(255, 4) }
  "read_16_16" should "be ok" in { readTest(16, 16) }
  "read_4_4" should "be ok" in   { readTest(4, 4) }
  "read_7_13" should "be ok" in  { readTest(7, 13) }

  /* WRITE TESTS */
  "write_255_4" should "be ok" in { writeTest(255,   4) }
  "write_16_16" should "be ok" in { writeTest( 16,  16) }
  "write_4_4" should "be ok" in   { writeTest(  4,   4) }
  "write_7_13" should "be ok" in  { writeTest(  7,  13) }

  /* INVALID R/W TESTS */
  "invalidReads_16" should "be ok" in  { invalidReads(16) }
  "invalidWrites_16" should "be ok" in { invalidWrites(16) }
}
