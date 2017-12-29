package chisel.axi.axi4lite
import  chisel.axi._
import  chisel.axi.Axi4Lite, chisel.axi.Axi4Lite._
import  chisel.axi.generators.Axi4Lite._
import  chisel.miscutils.Logging
import  chisel3._
import  chisel3.util._
import  chisel3.iotesters.{ChiselFlatSpec, Driver, PeekPokeTester}
import  org.scalacheck._, org.scalacheck.Prop._
import  org.scalatest.prop.Checkers

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
class RegFileTest(val size: Int, val off: Int, regs: Map[Long, ControlRegister], actions: Seq[MasterAction])
                 (implicit axi: Axi4Lite.Configuration, logLevel: Logging.Level) extends Module {
  val cfg = new RegisterFile.Configuration(regs = regs)
  val saxi = Module(new RegisterFile(cfg))
  val m = Module(new ProgrammableMaster(actions))
  val io = IO(new Bundle {
    val rdata = Irrevocable(saxi.io.saxi.readData.bits.cloneType)
    val wresp = Irrevocable(new chisel.axi.Axi4Lite.WriteResponse)
    val finished = Output(Bool())
  })
  m.io.maxi         <> saxi.io.saxi
  io.finished       := m.io.finished
  io.wresp          <> saxi.io.saxi.writeResp
  io.rdata          <> saxi.io.saxi.readData
}

/** Unit test suite for Axi4LiteRegisterFile module. **/
class RegisterFileSpec extends ChiselFlatSpec with Checkers {
  implicit val logLevel = Logging.Level.Info
  // basic Chisel arguments
  val chiselArgs = Array("--fint-write-vcd")

  private def generateActionsFromRegMap(regs: Map[Long, Option[ControlRegister]]): Seq[MasterAction] =
    regs.toSeq.sortBy(_._1) map { _ match {
      case (i, Some(r)) => r match {
        case c: Register         => Seq(MasterWrite(i, i), MasterRead(i))
        case c: ConstantRegister => Seq(MasterRead(i))
        case _                   => Seq()
      }
      case (i, None) => Seq(MasterRead(i), MasterWrite(i, i))
    }} reduce (_ ++ _)

  private def genericTest(width: DataWidth, regs: Map[Long, Option[ControlRegister]])
                         (implicit axi: Axi4Lite.Configuration) = {
    val testDir = "test/axi4lite/RegisterFileSpec/generic/%d/%d".format(width: Int, scala.util.Random.nextInt)
    println(s"Test results here: $testDir, width = $width")
    val args = chiselArgs ++ Array("--target-dir", testDir)
    val actions = generateActionsFromRegMap(regs)
    Driver.execute(args, () => new RegFileTest(regs.size, width / 8, regs filter { case (_, or) => or.nonEmpty } map { case (i, or) => (i, or.get) }, actions))
      { m => new GenericTester(width, regs, m) }
  }

  private class GenericTester(width: DataWidth, regs: Map[Long, Option[ControlRegister]], m: RegFileTest) extends PeekPokeTester(m) {
    def waitForReadData {
      if (peek(m.io.rdata.valid) != 0) {
        println("read data is still valid at start of waitForReadData, waiting ...")
        var waitCycles = 0
        while (peek(m.io.rdata.valid) != 0) {
          waitCycles += 1
          step(1)
        }
        println(s"waited $waitCycles cycles for read data valid signal to go low")
      }
      println("waiting for read data ...")
      var steps = 100
      while (steps > 0 && peek(m.io.rdata.valid) == 0) { steps -= 1; step(1) }
      expect(m.io.rdata.valid, 1, "expected read data to arrive, but it did not")
      println(s"wait for read data took ${100 - steps} cycles")
    }

    def waitForWriteResp {
      if (peek(m.io.wresp.valid) != 0) {
        println("write resp is still valid at start of waitForReadData, waiting ...")
        var waitCycles = 0
        while (peek(m.io.wresp.valid) != 0) {
          waitCycles += 1
          step(1)
        }
        println(s"waited $waitCycles cycles for write resp valid signal to go low")
      }
      println("waiting for write response ...")
      var steps = 100
      while (steps > 0 && peek(m.io.wresp.valid) == 0) { steps -= 1; step(1) }
      expect(m.io.wresp.valid, 1, "expected write response to arrive, but it did not")
      println(s"wait for write response took ${100 - steps} cycles")
    }

    def test(r: Register, off: Int) {
      waitForWriteResp
      val bresp = peek(m.io.wresp.bits.bresp)
      expect (m.io.wresp.bits.bresp, Response.okay, s"[$off] write response is 0x%x (%d), should be 0 (OKAY)".format(bresp, bresp))
      waitForReadData
      val resp = peek(m.io.rdata.bits.resp)
      expect (m.io.rdata.bits.resp, Response.okay, s"[$off] read response is 0x%x (%d), should be 0 (OKAY)".format(resp, resp))
      val data = peek(m.io.rdata.bits.data)
      expect (m.io.rdata.bits.data, off, s"[$off] read data is 0x%x (%d), should be %d".format(data, data, off))
    }

    def test(r: ConstantRegister, off: Int) {
      waitForReadData
      val resp = peek(m.io.rdata.bits.resp)
      val data = peek(m.io.rdata.bits.data)
      expect (m.io.rdata.bits.resp, Response.okay, s"[$off] read response is 0x%x (%d), should be 0 (OKAY)".format(resp, resp))
      expect (m.io.rdata.bits.data, r.value, s"[$off] read data is 0x%x (%d), should be %d".format(data, data, r.value))
    }

    def testInvalid(off: Int) {
      println(s"[$off] expecting an invalid read ...")
      waitForReadData
      val resp = peek(m.io.rdata.bits.resp)
      expect (m.io.rdata.bits.resp, Response.slverr, s"[$off] read resp is 0x%x (%d), should be 2 (SLVERR)".format(resp, resp))
      println(s"[$off] expecting an invalid write ...")
      waitForWriteResp
      val bresp = peek(m.io.wresp.bits.bresp)
      expect (m.io.wresp.bits.bresp, Response.slverr, s"[$off] write resp is 0x%x (%d), should be 2 (SLVERR)".format(bresp, bresp))
    }

    println(s"data width = $width")

    println("Register Map:")
    regs.toSeq.sortBy(_._1) foreach { _ match { case (i, or) => println(s"$i -> $or") } }

    poke(m.io.wresp.ready, true)
    poke(m.io.rdata.ready, true)

    regs.toSeq.sortBy(_._1) foreach { _ match {
      case (i, or) => or match {
        case Some(r) => r match {
          case cr: ConstantRegister => test(cr, i)
          case rr: Register         => test(rr, i)
          case _                    => ()
        }
        case _                      => testInvalid(i)
      }
    }}
  }

  behavior of "RegisterFile"

  it should "behave correctly for arbitrary configurations" in
    check(forAll(chisel.axi.generators.Axi4Lite.configurationGen) { cfg =>
      forAllNoShrink(registerMapGen(cfg.dataWidth)) { regs =>
        implicit val axi = cfg.copy(addrWidth = chisel.axi.AddrWidth(32))
        genericTest(cfg.dataWidth, regs)
      }
    }, minSuccessful(100))
}
