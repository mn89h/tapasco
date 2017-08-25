package chisel.axi
import  chisel3._
import  chisel3.util._
import  chisel3.internal.firrtl.Width

object Axi4Lite {
  sealed trait DataWidth extends WidthLike
  final case object Width32 extends DataWidth { def width = 32 }
  final case object Width64 extends DataWidth { def width = 64 }


  case class Configuration(addrWidth:   AddrWidth,
                           dataWidth:   DataWidth,
                           userWidth:   UserWidth   = UserWidth(0),
                           regionWidth: RegionWidth = RegionWidth(0))

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
      val strb  = new Strobe(cfg.dataWidth)

      override def cloneType = { new Write()(cfg).asInstanceOf[this.type] }
    }
  }

  class WriteResponse(implicit cfg: Configuration) extends Bundle {
    val buser = UInt(cfg.userWidth)
    val bresp = UInt(2.W)

    override def cloneType = { new WriteResponse()(cfg).asInstanceOf[this.type] }
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
