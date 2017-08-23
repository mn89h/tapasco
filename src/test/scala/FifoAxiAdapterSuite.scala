package chisel.axiutils
import  chisel3._
import  chisel3.util._
import  chisel3.iotesters.{ChiselFlatSpec, Driver, PeekPokeTester}
import  chisel.miscutils.DecoupledDataSource
import  chisel.axi._

class FifoAxiAdapterModule1(size: Int)(implicit val axi: Axi4.Configuration) extends Module {
  val io = IO(new Bundle {
    val datasrc_out_valid = Output(Bool())
    val fifo_count        = Output(UInt(log2Ceil(size).W))
  })
  val cfg = AxiSlaveModelConfiguration(size = Some(size))
  val datasrc = Module (new DecoupledDataSource(UInt(axi.dataWidth), size = 256, n => n.U, false))
  val naxi = Axi4.Configuration(AddrWidth(log2Ceil(size)), DataWidth(axi.dataWidth))
  val fad = Module (new FifoAxiAdapter(fifoDepth = size, burstSize = Some(16))(naxi))
  val saxi = Module (new AxiSlaveModel(cfg))

  fad.io.base          := 0.U
  fad.io.enq           <> datasrc.io.out
  fad.io.maxi          <> saxi.io.saxi
  io.datasrc_out_valid := datasrc.io.out.valid
  io.fifo_count        := fad.io.count
}

class FifoAxiAdapterSuite extends ChiselFlatSpec {
  "test1" should "be ok" in {
    implicit val axi = Axi4.Configuration(AddrWidth(8), DataWidth(8))
    Driver.execute(Array("--fint-write-vcd", "--target-dir", "test/fad"),
        () => new FifoAxiAdapterModule1(size = 256))
      { m => new FifoAxiAdapterModule1Test(m) }
  }
}

class FifoAxiAdapterModule1Test(fad: FifoAxiAdapterModule1) extends PeekPokeTester(fad) {
  import scala.util.Properties.{lineSeparator => NL}
  private var cc = 0

  // re-define step to output progress info
  override def step(n: Int) {
    super.step(n)
    cc += n
    if (cc % 1000 == 0) println("clock cycle: " + cc)
  }

  def toBinaryString(v: BigInt) =
      "b%%%ds".format(fad.axi.dataWidth:Int).format(v.toString(2)).replace(' ', '0')

  reset(10)
  while (peek(fad.io.datasrc_out_valid) != 0 || peek(fad.io.fifo_count) > 0) step(1)
  step(10) // settle

  // check
  for (i <- 0 until 256) {
    val v = peekAt(fad.saxi.mem, i)
    expect(peekAt(fad.saxi.mem, i) == i, "Mem[%03d] = %d (%s), expected: %d (%s)"
        .format(i, v, toBinaryString(v), i, toBinaryString(i)))
  }
}
