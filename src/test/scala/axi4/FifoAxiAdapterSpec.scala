package chisel.axiutils.axi4
import  chisel3.iotesters.{ChiselFlatSpec, Driver, PeekPokeTester}
import  org.scalatest.prop.Checkers
import  org.scalacheck._, org.scalacheck.Prop._

class FifoAxiAdapterSpec extends ChiselFlatSpec with Checkers {
  behavior of "FifoAxiAdapter"

  it should "say hello" in {
    check({ println("hello!"); true })
  }

  // it should "work with arbitrary configurations"
}
