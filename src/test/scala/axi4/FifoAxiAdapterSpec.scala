package chisel.axiutils.axi4
import  generators._, chisel.miscutils.generators._
import  chisel.miscutils._
import  chisel.axi._
import  chisel3._
import  chisel3.iotesters.{ChiselFlatSpec, Driver, PeekPokeTester}
import  org.scalatest.prop.Checkers
import  org.scalacheck._, org.scalacheck.Prop._

class FifoAxiAdapterTest(fifoDepth: Int, val data: Seq[BigInt], repeat: Boolean)
                        (implicit axi: Axi4.Configuration,
                         logLevel: Logging.Level) extends Module {
  val m   = Module(new FifoAxiAdapter(fifoDepth))
  val src = Module(new DecoupledDataSource(UInt(axi.dataWidth), data.length, data map (_.U), repeat))
  val dst = Module(new SlaveModel(SlaveModel.Configuration(readDelay = 0, writeDelay = 0)))
  val io  = IO(new Bundle {
    val debug = dst.io.debug.cloneType
  })

  src.io.out <> m.io.enq
  m.io.base := 0.U
  m.io.maxi <> dst.io.saxi
  dst.io.debug <> io.debug
}

class FifoAxiAdapterTester(m: FifoAxiAdapterTest) extends PeekPokeTester(m) {
  implicit val tester = this
  poke(m.io.debug.w, false)
  poke(m.io.debug.r, false)

  reset(10)
  step(m.data.length * 50)

  poke(m.io.debug.r, true)
  0 until m.data.length foreach { i =>
    poke(m.io.debug.ra, i)
    step(1)
    expect(m.io.debug.dout, m.data(i), s"wrong data at $i")
  }
  step(10)
}

class FifoAxiAdapterSpec extends ChiselFlatSpec with Checkers {
  implicit val logLevel = Logging.Level.Info
  behavior of "FifoAxiAdapter"

  it should "say hello" in {
    check({ println("hello!"); true })
  }

  it should "work with arbitrary configurations" in
    check(forAll(axi4CfgGen, fifoDepthGen) { case (axi4, fd)  =>
      forAllNoShrink(dataGen(BitWidth(axi4.dataWidth.width)(1024))) { data =>
        implicit val a = axi4
        try {
        Driver.execute(Array("--fint-write-vcd", "--target-dir", "test/axi4/FifoAxiAdapter"),
            () => new FifoAxiAdapterTest(fd, data, false))
          { m => new FifoAxiAdapterTester(m) }
        } catch { case t: Throwable =>
          t.getStackTrace() foreach (println(_))
          throw t
        }
    }})
}
