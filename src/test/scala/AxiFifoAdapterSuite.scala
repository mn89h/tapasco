package chisel.axiutils
import Chisel._
import org.scalatest.junit.JUnitSuite
import org.junit.Test
import org.junit.Assert._
import java.nio.file.Paths

class AxiFifoAdapterModule1(
    val dataWidth: Int,
    val fifoDepth: Int,
    val blockSize: Int
  ) extends Module {

  val addrWidth = log2Up(dataWidth * fifoDepth * blockSize / 8)
  val cfg = AxiSlaveModelConfiguration(addrWidth = Some(addrWidth), dataWidth = dataWidth)
  val io = new Bundle
  val afa = Module (AxiFifoAdapter(addrWidth = addrWidth,
      dataWidth = dataWidth, idWidth = 1, fifoDepth = fifoDepth))
  val saxi = Module (new AxiSlaveModel(cfg))
  val dqr = Reg(init = Bool(true))

  afa.io.base      := UInt(0)
  //afa.io.deq.ready := Bool(true)
  afa.io.deq.ready := dqr
  afa.io.maxi      <> saxi.io.saxi
}

class AxiFifoAdapterModule1Test(m: AxiFifoAdapterModule1) extends Tester(m, false) {
  import scala.util.Properties.{lineSeparator => NL}
  private var _cc = 0

  // re-define step to output progress info
  override def step(n: Int) {
    super.step(n)
    _cc += n
    if (cc % 1000 == 0) println("clock cycle: " + _cc)
  }

  // setup data
  println("prepping %d (%d x %d) mem elements ...".format(m.fifoDepth * m.blockSize, m.fifoDepth, m.blockSize))
  for (i <- 0 until m.fifoDepth * m.blockSize)
    pokeAt(m.saxi.mem, i % scala.math.pow(2, m.dataWidth).toInt, i)

  var res: List[BigInt] = List()
  var cc: Int = m.fifoDepth * m.blockSize * 10 // upper bound on cycles

  reset(10)
  poke(m.dqr, true)
  while (cc > 0 && res.length < m.fifoDepth * m.blockSize) {
    if (peek(m.afa.io.deq.valid) != 0) {
      val v = peek(m.afa.io.deq.bits)
      res ++= List(v)
      poke(m.dqr, false)
      step(res.length % 20)
      poke(m.dqr, true)
    }
    step(1)
    cc -= 1
  }
  step(10) // settle

  res.zipWithIndex map (_ match { case (v, i) =>
      println("#%d: 0x%x (0b%s)".format(i, v, v.toString(2)))
    })
  
  for (i <- 0 until res.length if res(i) != peekAt(m.saxi.mem, i)) {
    val msg = "Mem[%03d] = %d (expected %d)".format(i, res(i), peekAt(m.saxi.mem, i))
    println(msg)
    expect(res(i) == peekAt(m.saxi.mem, i), msg)
  }
}

class AxiFifoAdapterSuite extends JUnitSuite {
  def runTest(dataWidth: Int, fifoDepth: Int, blockSize: Int) {
    val dir = Paths.get("test").resolve("dw%d_fd%d_bs%d".format(dataWidth, fifoDepth, blockSize)).toString
    chiselMainTest(Array("--genHarness", "--backend", "c", "--vcd", "--targetDir", dir, "--compile", "--test"),
        () => Module(new AxiFifoAdapterModule1(dataWidth = dataWidth, fifoDepth = fifoDepth, blockSize = blockSize))) { m => new AxiFifoAdapterModule1Test(m) }
  }

  @Test def checkDw32Fd1Bs256     { runTest(dataWidth = 32,  fifoDepth = 1,   blockSize = 256/1) }
  @Test def checkDw32Fd8Bs32      { runTest(dataWidth = 32,  fifoDepth = 8,   blockSize = 256/8) }
  @Test def checkDw8Fd8Bs32       { runTest(dataWidth = 8,   fifoDepth = 8,   blockSize = 256/8) }
  @Test def checkDw8Fd2Bs128      { runTest(dataWidth = 8,   fifoDepth = 2,   blockSize = 256/2) }
  @Test def checkDw64Fd16Bs512    { runTest(dataWidth = 64,  fifoDepth = 16,  blockSize = 512) }
  @Test def checkDw128Fd128Bs1024 { runTest(dataWidth = 128, fifoDepth = 128, blockSize = 1024/128) }
  // FIXME seems to work, but too slow
  // @Test def checkDw8Fd1080Bs480   { runTest(dataWidth = 8,   fifoDepth = 256, blockSize = 480*4) }
}

