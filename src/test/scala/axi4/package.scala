package chisel.axiutils.axi4
import  chisel.axi._
import  chisel.miscutils.generators._
import  org.scalacheck._

package object generators {
  val axi4CfgGen: Gen[Axi4.Configuration] = for {
    aw <- bitWidthGen(64)
    dw <- bitWidthGen(1024)
  } yield Axi4.Configuration(addrWidth = AddrWidth(aw), dataWidth = DataWidth(dw))

  val fifoDepthGen: Gen[Limited[Int]] = genLimited(1, 16)
}
