package chisel.axi
import  chisel3._
import  chisel3.util._

object Axi4 {
  class Configuration(val addrWidth:   AddrWidth,
                      val dataWidth:   DataWidth,
                      val idWidth:     IdWidth     = IdWidth(1),
                      val userWidth:   UserWidth   = UserWidth(0),
                      val regionWidth: RegionWidth = RegionWidth(0),
                      val hasQoS:      Boolean     = false)

  object Configuration {
    def apply(addrWidth:   AddrWidth,
              dataWidth:   DataWidth,
              idWidth:     IdWidth     = IdWidth(1),
              userWidth:   UserWidth   = UserWidth(0),
              regionWidth: RegionWidth = RegionWidth(0),
              hasQoS:      Boolean     = false): Configuration =
      new Configuration(addrWidth, dataWidth, idWidth, userWidth, regionWidth, hasQoS)

    def unapply(c: Configuration): Option[Tuple6[AddrWidth, DataWidth, IdWidth, UserWidth, RegionWidth, Boolean]] =
      Some((c.addrWidth, c.dataWidth, c.idWidth, c.userWidth, c.regionWidth, c.hasQoS))
  }

  implicit class fromIntToSize(size: Int) {
    import Burst.Size._
    def BSZ: UInt = size match {
      case 1   => s1
      case 4   => s4
      case 8   => s8
      case 16  => s16
      case 32  => s32
      case 64  => s64
      case 128 => s128
      case _   => throw new Exception("invalid size, only 0 < powers of 2 <= 128")
    }
  }

  class Burst extends Bundle {
    val burst = UInt(2.W)
    val len   = UInt(8.W)
    val size  = UInt(3.W)
  }

  object Burst extends Bundle {
    object Type {
      val fixed :: incr :: wrap :: Nil = Enum(3)
    }
    object Size {
      val s1 :: s2 :: s4 :: s8 :: s16 :: s32 :: s64 :: s128 :: Nil = Enum(8)
    }
  }

  class Lock extends Bundle {
    val lock = UInt(2.W)
  }

  object Lock extends Bundle {
    object Access {
      val normal :: exclusive :: Nil = Enum(2)
    }
  }

  class Cache extends Bundle {
    val cache = UInt(4.W)
  }

  object Cache {
    object Read {
      final val DEVICE_NON_BUFFERABLE: UInt               = "b0000".U(4.W)
      final val DEVICE_BUFFERABLE: UInt                   = "b0001".U(4.W)
      final val NORMAL_NON_CACHEABLE_NON_BUFFERABLE: UInt = "b0010".U(4.W)
      final val NORMAL_NON_CACHEABLE_BUFFERABLE: UInt     = "b0011".U(4.W)
      final val WRITE_THROUGH_NO_ALLOCATE: UInt           = "b0110".U(4.W)
      final val WRITE_THROUGH_READ_ALLOCATE: UInt         = "b0110".U(4.W)
      final val WRITE_THROUGH_WRITE_ALLOCATE: UInt        = "b0110".U(4.W)
      final val WRITE_THROUGH_RW_ALLOCATE: UInt           = "b1110".U(4.W)
      final val WRITE_BACK_NO_ALLOCATE: UInt              = "b0111".U(4.W)
      final val WRITE_BACK_READ_ALLOCATE: UInt            = "b0111".U(4.W)
      final val WRITE_BACK_WRITE_ALLOCATE: UInt           = "b1111".U(4.W)
      final val WRITE_BACK_RW_ALLOCATE: UInt              = "b1111".U(4.W)
    }

    object Write {
      final val DEVICE_NON_BUFFERABLE: UInt               = "b0000".U(4.W)
      final val DEVICE_BUFFERABLE: UInt                   = "b0001".U(4.W)
      final val NORMAL_NON_CACHEABLE_NON_BUFFERABLE: UInt = "b0010".U(4.W)
      final val NORMAL_NON_CACHEABLE_BUFFERABLE: UInt     = "b0011".U(4.W)
      final val WRITE_THROUGH_NO_ALLOCATE: UInt           = "b1010".U(4.W)
      final val WRITE_THROUGH_READ_ALLOCATE: UInt         = "b1110".U(4.W)
      final val WRITE_THROUGH_WRITE_ALLOCATE: UInt        = "b1010".U(4.W)
      final val WRITE_THROUGH_RW_ALLOCATE: UInt           = "b1110".U(4.W)
      final val WRITE_BACK_NO_ALLOCATE: UInt              = "b1011".U(4.W)
      final val WRITE_BACK_READ_ALLOCATE: UInt            = "b1111".U(4.W)
      final val WRITE_BACK_WRITE_ALLOCATE: UInt           = "b1011".U(4.W)
      final val WRITE_BACK_RW_ALLOCATE: UInt              = "b1111".U(4.W)
    }
  }

  class Protection extends Bundle {
    val prot = UInt(3.W)
  }

  object Protection {
    sealed trait Flag extends Function[Int, Int]  { def apply(i: Int): Int }
    object Flag {
      final case object NON_PRIVILEGED extends Flag { def apply(i: Int): Int = i & ~(1 << 0) }
      final case object PRIVILEGED extends Flag     { def apply(i: Int): Int = i |  (1 << 0) }
      final case object SECURE extends Flag         { def apply(i: Int): Int = i & ~(1 << 1) }
      final case object NON_SECURE extends Flag     { def apply(i: Int): Int = i |  (1 << 1) }
      final case object DATA extends Flag           { def apply(i: Int): Int = i & ~(1 << 2) }
      final case object INSTRUCTION extends Flag    { def apply(i: Int): Int = i |  (1 << 2) }
    }
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
    val id     = UInt(cfg.idWidth)
    val addr   = UInt(cfg.addrWidth)
    val burst  = new Burst
    val lock   = new Lock
    val cache  = new Cache
    val prot   = new Protection
    val qos    = UInt(if (cfg.hasQoS) 4.W else 0.W)
    val region = UInt(cfg.regionWidth)
    val user   = UInt(cfg.userWidth)

    override def cloneType = { new Address()(cfg).asInstanceOf[this.type] }
  }

  object Data {
    abstract private[axi] class DataChannel(implicit cfg: Configuration) extends Bundle {
      val id    = UInt(cfg.idWidth)
      val data  = UInt(cfg.dataWidth)
      val last  = Bool()
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
    val bid   = UInt(cfg.idWidth)
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
    private implicit val cfg = Configuration(AddrWidth(32), DataWidth(64), IdWidth(3), UserWidth(1), RegionWidth(2))
    val io = IO(new Bundle {
      val m_axi = Master(cfg)
      val s_axi = Slave(cfg)
    })
    io.s_axi <> io.m_axi
  }
}
