package chisel.axi
import  chisel3._
import  chisel3.util._
import  chisel3.internal.firrtl.Width

object Axi4Lite {
  sealed trait WidthLike { def width: Int }
  final case class AddrWidth(width: Int) extends WidthLike
  sealed trait DataWidth extends WidthLike
  final case object Width32 extends DataWidth { def width = 32 }
  final case object Width64 extends DataWidth { def width = 64 }
  final case class IdWidth(width: Int) extends WidthLike
  final case class UserWidth(width: Int) extends WidthLike
  final case class RegionWidth(width: Int) extends WidthLike

  implicit def fromWidthLikeToWidth(wl: WidthLike): Width = wl.width.W
  implicit def fromWidthLikeToInt(wl: WidthLike): Int     = wl.width

  case class Configuration(addrWidth:   AddrWidth,
                           dataWidth:   DataWidth,
                           userWidth:   UserWidth   = UserWidth(0),
                           regionWidth: RegionWidth = RegionWidth(0))

  class Protection extends Bundle {
    val prot = UInt(3.W)
  }

  object Protection {
    sealed trait Flag extends Function[Int, Int]  { def apply(i: Int): Int }
    final case object NON_PRIVILEGED extends Flag { def apply(i: Int): Int = i & ~(1 << 0) }
    final case object PRIVILEGED extends Flag     { def apply(i: Int): Int = i |  (1 << 0) }
    final case object SECURE extends Flag         { def apply(i: Int): Int = i & ~(1 << 1) }
    final case object NON_SECURE extends Flag     { def apply(i: Int): Int = i |  (1 << 1) }
    final case object DATA extends Flag           { def apply(i: Int): Int = i & ~(1 << 2) }
    final case object INSTRUCTION extends Flag    { def apply(i: Int): Int = i |  (1 << 2) }
    def apply(fs: Flag*): Int = (fs fold (identity[Int] _)) (_ andThen _) (0)
  }

  class Strobe(implicit cfg: Configuration) extends Bundle {
    val strb = UInt((cfg.dataWidth / 8).W)

    override def cloneType = { new Strobe()(cfg).asInstanceOf[this.type] }
  }

  object Strobe {
    def apply(byteEnables: Int*): UInt = ((byteEnables map (i => (1 << i)) fold 0) (_ | _)).U
  }


  class Address(implicit cfg: Configuration) extends Bundle {
    val addr   = UInt(cfg.addrWidth)
    val prot   = new Protection
    val region = UInt(cfg.regionWidth)
    val user   = UInt(cfg.userWidth)

    override def cloneType = { new Address()(cfg).asInstanceOf[this.type] }
  }

  object Data {
    abstract private[axi] class DataChannel(implicit cfg: Configuration) extends Bundle {
      val data  = UInt(cfg.dataWidth)
      val user  = UInt(cfg.userWidth)
    }

    class Read(implicit cfg: Configuration) extends DataChannel {
      val resp  = UInt(2.W)

      override def cloneType = { new Read()(cfg).asInstanceOf[this.type] }
    }

    class Write(implicit cfg: Configuration) extends DataChannel {
      val strb  = new Strobe

      override def cloneType = { new Write()(cfg).asInstanceOf[this.type] }
    }
  }

  class WriteResponse(implicit cfg: Configuration) extends Bundle {
    val buser = UInt(cfg.userWidth)
    val bresp = UInt(2.W)

    override def cloneType = { new WriteResponse()(cfg).asInstanceOf[this.type] }
  }

  object Response {
    val okay :: exokay :: slverr :: decerr :: Nil = Enum(4)
  }

  class Master private (implicit cfg: Configuration) extends Bundle {
    val writeAddr = Decoupled(new Address)
    val writeData = Decoupled(new Data.Write)
    val writeResp = Flipped(Decoupled(new WriteResponse))
    val readAddr  = Decoupled(new Address)
    val readData  = Flipped(Decoupled(new Data.Read))

    override def cloneType = { new Master()(cfg).asInstanceOf[this.type] }
  }

  object Master {
    def apply(implicit cfg: Configuration): Master = new Master
  }

  object Slave {
    def apply(implicit cfg: Configuration) = Flipped(Master(cfg))
  }

  class Dummy extends Module {
    private implicit val cfg = Configuration(AddrWidth(32), Width64)
    val io = IO(new Bundle {
      val m_axi = Master(cfg)
      val s_axi = Slave(cfg)
    })
    io.s_axi <> io.m_axi
  }
}
