package chisel.axi.axi4
import  chisel.axi.generators._
import  org.scalacheck.{Arbitrary, Gen}

package object generators {
  object Axi4 {
    val configurationGen: Gen[chisel.axi.Axi4.Configuration] = for {
      addrWidth   <- addrWidthGen
      dataWidth   <- dataWidthGen
      userWidth   <- userWidthGen
      idWidth     <- idWidthGen
      regionWidth <- regionWidthGen
      hasQoS      <- Arbitrary.arbBool.arbitrary
    } yield chisel.axi.Axi4.Configuration(addrWidth, dataWidth, idWidth, userWidth, regionWidth, hasQoS)
  }

  object Axi4Lite {
    val dataWidthGen: Gen[chisel.axi.Axi4Lite.DataWidth] = Gen.oneOf(
      chisel.axi.Axi4Lite.Width32,
      chisel.axi.Axi4Lite.Width64
    )

    val configurationGen: Gen[chisel.axi.Axi4Lite.Configuration] = for {
      addrWidth   <- addrWidthGen
      dataWidth   <- dataWidthGen
      userWidth   <- userWidthGen
      regionWidth <- regionWidthGen
    } yield chisel.axi.Axi4Lite.Configuration(addrWidth, dataWidth, userWidth, regionWidth)
  }
}
