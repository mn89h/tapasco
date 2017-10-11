package chisel.axi
import  chisel.miscutils.generators._
import  org.scalacheck._

package object generators {
  val addrWidthGen: Gen[AddrWidth]     = genLimited(1, 64) map (AddrWidth(_))
  val dataWidthGen: Gen[DataWidth]     = genLimited(1, 4096) map (DataWidth(_))
  val userWidthGen: Gen[UserWidth]     = Gen.frequency(
    90 -> UserWidth(0),
    10 -> (genLimited(1, 15) map (UserWidth(_)))
  )
  val idWidthGen: Gen[IdWidth]         = genLimited(0, 15) map (IdWidth(_))
  val regionWidthGen: Gen[RegionWidth] = genLimited(0, 4) map (RegionWidth(_))
}
