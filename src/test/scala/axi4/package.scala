package chisel.axiutils.axi4
import  chisel.axi._
import  chisel.axi.Axi4._
import  chisel.miscutils.generators._
import  org.scalacheck._

package object generators {
  val axi4CfgGen: Gen[Axi4.Configuration] = for {
    aw <- bitWidthGen(64)
    dw <- bitWidthGen(128)
  } yield Axi4.Configuration(addrWidth = AddrWidth(aw), dataWidth = DataWidth(dw))

  val fifoDepthGen: Gen[Limited[Int]] = genLimited(1, 16)

  def bitStringGen(width: BitWidth): Gen[String] =
    Gen.buildableOfN[String, Char](width, Gen.oneOf('0', '1'))

  def dataGen(width: BitWidth, minElems: Int = 1, maxElems: Int = 1024): Gen[Seq[BigInt]] = for {
    n <- genLimited(minElems, maxElems)
    d <- Gen.buildableOfN[Seq[BigInt], BigInt](n, bitStringGen(width) map (BigInt(_, 2)))
  } yield d
}
