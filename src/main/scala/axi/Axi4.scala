package chisel.axi
import  chisel3._
import  chisel3.util._

object Axi4 {
  class Configuration(val addrWidth:   AddrWidth,
                      val dataWidth:   DataWidth,
                      val idWidth:     IdWidth     = IdWidth(1),
                      val userWidth:   UserWidth   = UserWidth(0),
                      val regionWidth: RegionWidth = RegionWidth(0),
                      val hasQoS:      Boolean     = false) {
    override def toString: String =
      s"Axi4($addrWidth $dataWidth $idWidth $userWidth $regionWidth $hasQoS)"
  }

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
      val s1 :: s2 :: s4 :: s8 :: s16 :: s32 :: s64 :: s128 :: s256 :: Nil = Enum(9)
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

  class Address(implicit cfg: Configuration) extends Bundle {
    val id     = UInt(cfg.idWidth)
    val addr   = UInt(cfg.addrWidth)
    val burst  = new Burst
    val lock   = new Lock
    val cache  = new Cache
    val prot   = new Protection
    // FIXME: how to represent optional signals?
    val qos    = if (cfg.hasQoS) UInt(4.W) else UInt(1.W)
    val region = if (cfg.regionWidth > 0) UInt(cfg.regionWidth) else UInt(1.W)
    val user   = if (cfg.userWidth > 0) UInt(cfg.userWidth) else UInt(1.W)

    override def cloneType = { new Address()(cfg).asInstanceOf[this.type] }
  }

  implicit class AddToAddress(a: Address) {
    def read(address: Int,
             len: Int,
             id: Int,
             burst: UInt = Burst.Type.incr,
             lock: UInt = Lock.Access.normal,
             cache: UInt = Cache.Read.NORMAL_NON_CACHEABLE_BUFFERABLE,
             prot: UInt = Protection(Protection.Flag.NON_SECURE,
                                     Protection.Flag.NON_PRIVILEGED,
                                     Protection.Flag.DATA).U)
            (implicit axi: Configuration) = {
      a.id := id.U
      a.addr := address.U
      a.burst.len := (len - 1).U
      a.burst.size := (axi.dataWidth:Int).U
      a.burst.burst := burst
      a.lock.lock := lock
      a.cache.cache := cache
      a.prot.prot := prot
      a.region := 0.U
      a.user := 0.U
      a.qos := 0.U
    }

    def write(address: Int,
              len: Int,
              id: Int,
              burst: UInt = Burst.Type.incr,
              lock: UInt = Lock.Access.normal,
              cache: UInt = Cache.Write.NORMAL_NON_CACHEABLE_BUFFERABLE,
              prot: UInt = Protection(Protection.Flag.NON_SECURE,
                                      Protection.Flag.NON_PRIVILEGED,
                                      Protection.Flag.DATA).U)
             (implicit axi: Configuration) = {
      a.id := id.U
      a.addr := address.U
      a.burst.len := (len - 1).U
      a.burst.size := (axi.dataWidth:Int).U
      a.burst.burst := burst
      a.lock.lock := lock
      a.cache.cache := cache
      a.prot.prot := prot
      a.region := 0.U
      a.user := 0.U
      a.qos := 0.U
    }
  }

  object Data {
    abstract private[axi] class DataChannel(implicit cfg: Configuration) extends Bundle {
      // FIXME signals are optional
      val id    = if (cfg.idWidth > 0) UInt(cfg.idWidth) else UInt(1.W)
      val data  = if (cfg.dataWidth > 0) UInt(cfg.dataWidth) else UInt(1.W)
      val last  = Bool()
      val user  = if (cfg.userWidth > 0) UInt(cfg.userWidth) else UInt(1.W)
    }

    class Read(implicit cfg: Configuration) extends DataChannel {
      val resp  = UInt(2.W)

      override def cloneType = { new Read()(cfg).asInstanceOf[this.type] }
    }

    class Write(implicit cfg: Configuration) extends DataChannel {
      val strb  = new Strobe(cfg.dataWidth)

      override def cloneType = { new Write()(cfg).asInstanceOf[this.type] }
    }
  }

  class WriteResponse(implicit cfg: Configuration) extends Bundle {
    val bid   = UInt(cfg.idWidth)
    val buser = UInt(cfg.userWidth)
    val bresp = UInt(2.W)

    override def cloneType = { new WriteResponse()(cfg).asInstanceOf[this.type] }
  }

  class Master private (implicit cfg: Configuration) extends Bundle {
    val writeAddr = Irrevocable(new Address)
    val writeData = Irrevocable(new Data.Write)
    val writeResp = Flipped(Irrevocable(new WriteResponse))
    val readAddr  = Irrevocable(new Address)
    val readData  = Flipped(Irrevocable(new Data.Read))

    override def cloneType = { new Master()(cfg).asInstanceOf[this.type] }
  }

  implicit class AddToMaster(m: Master) {
    def read(a: Address) {
      m.readAddr.bits  := a
      m.readAddr.valid := true.B
    }

    def write(a: Address) {
      m.writeAddr.bits  := a
      m.writeAddr.valid := true.B
    }
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
