package de.tu_darmstadt.cs.esa.tapasco.tapasco_status
import  chisel.axi._, chisel.axi.axi4lite._
import  chisel.miscutils.Logging
import  generators._
import  chisel3.iotesters.ChiselFlatSpec
import  org.scalatest.prop.Checkers
import  org.scalacheck.Prop._

class StatusSpec extends ChiselFlatSpec with Checkers {
  implicit val axi = Axi4Lite.Configuration(dataWidth = Axi4Lite.Width32, addrWidth = AddrWidth(12))
  implicit val llv = Logging.Level.Info
  val chiselArgs = Array("--fint-write-vcd")

  behavior of "tapasco_status"

  it should "behave correctly in generic test" in check(forAllNoShrink(genStatus) { status =>
    val regs = Builder.makeConfiguration(status).regs map { case (addr, reg) => (addr, Some(reg)) }
    RegisterFileSpec.genericTest(chiselArgs, axi.dataWidth,  regs)
  })
}
