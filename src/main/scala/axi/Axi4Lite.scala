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

    def defaults {
      addr      := "h12345678".U
      prot.prot := Protection(Protection.Flag.NON_PRIVILEGED, Protection.Flag.NON_SECURE, Protection.Flag.DATA).U
      region    := 0.U
      user      := 0.U
    }

    override def cloneType = { new Address()(cfg).asInstanceOf[this.type] }
  }

  object Data {
    abstract private[axi] class DataChannel(implicit cfg: Configuration) extends Bundle {
      val data  = UInt(cfg.dataWidth)
      val user  = UInt(cfg.userWidth)

      def defaults {
        data := "hDEADBEEF".U
        user := "hDEADDEED".U
      }
    }

    class Read(implicit cfg: Configuration) extends DataChannel {
      val resp  = UInt(2.W)

      override def defaults {
        super.defaults
        resp := Response.slverr
      }

      override def cloneType = { new Read()(cfg).asInstanceOf[this.type] }
    }

    class Write(implicit cfg: Configuration) extends DataChannel {
      val strb  = new Strobe(cfg.dataWidth)

      override def defaults {
        super.defaults
        strb.strb := Strobe(0 until cfg.dataWidth / 8:_*)
      }

      override def cloneType = { new Write()(cfg).asInstanceOf[this.type] }
    }
  }

  class WriteResponse(implicit cfg: Configuration) extends Bundle {
    val buser = UInt(cfg.userWidth)
    val bresp = UInt(2.W)

    def defaults {
      buser := 0.U
      bresp := Response.slverr
    }

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
