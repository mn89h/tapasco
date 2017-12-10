package chisel.axi
import  chisel.miscutils.generators._
import  org.scalacheck.{Arbitrary, Gen}

package object generators {
  val addrWidthGen: Gen[AddrWidth]     = genLimited(1, 64) map (AddrWidth(_))
  val userWidthGen: Gen[UserWidth]     = Gen.frequency(
    90 -> UserWidth(0),
    10 -> (genLimited(1, 15) map (UserWidth(_)))
  )
  val idWidthGen: Gen[IdWidth]         = genLimited(0, 15) map (IdWidth(_))
  val regionWidthGen: Gen[RegionWidth] = genLimited(0, 4) map (RegionWidth(_))

  object Axi4 {
    import chisel.axi.Axi4._
    val dataWidthGen: Gen[DataWidth]   = genLimited(1, 4096) map (DataWidth(_))

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
    import chisel.axi.Axi4Lite._
    import chisel.axi.axi4lite._ // FIXME
    import chisel3._

    val dataWidthGen: Gen[DataWidth] = Gen.oneOf(Width32, Width64)

    val configurationGen: Gen[chisel.axi.Axi4Lite.Configuration] = for {
      addrWidth   <- addrWidthGen
      dataWidth   <- dataWidthGen
      userWidth   <- userWidthGen
      regionWidth <- regionWidthGen
    } yield chisel.axi.Axi4Lite.Configuration(addrWidth, dataWidth, userWidth, regionWidth)

    def valueGen(width: DataWidth): Gen[BigInt] = BigInt(numbits = width, scala.util.Random)

    def constRegGen(width: DataWidth): Gen[ConstantRegister] = for {
      v <- valueGen(width)
    } yield new ConstantRegister(value = v)

    def basicRegGen[T <: UInt](width: DataWidth): Gen[Register[T]] = new Register[T](width = width)

    def maybeRegGen[T <: UInt](width: DataWidth): Gen[Option[ControlRegister]] =
      Gen.option(Gen.oneOf(basicRegGen[T](width), constRegGen(width)))

    def registerMapGen[T <: UInt](width: DataWidth): Gen[Map[Int, Option[ControlRegister]]] =
      Gen.nonEmptyListOf(maybeRegGen[T](width)) 
        .map (_.zipWithIndex) 
        .map { _ map { case (or, i) => i * (width / 8) -> or } }
        .map (_.toMap)
        .retryUntil (l => (l map (_._2.nonEmpty) fold false) (_ || _))
  }
}
