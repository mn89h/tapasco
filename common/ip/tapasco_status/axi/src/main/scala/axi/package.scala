package chisel
import  chisel3._
import  chisel3.util.Enum
import  chisel3.internal.firrtl.Width

package object axi {
  private[axi] trait WidthLike { def width: Int; def toInt: Int = this }
  final case class AddrWidth(width: Int) extends WidthLike {
    require (width > 0 && width <= 64, "addrWidth (%d) must be 0 < addrWidth <= 64".format(width))
  }
  final case class IdWidth(width: Int) extends WidthLike
  final case class UserWidth(width: Int) extends WidthLike
  final case class RegionWidth(width: Int) extends WidthLike

  implicit def fromWidthLikeToWidth(wl: WidthLike): Width = wl.width.W
  implicit def fromWidthLikeToInt(wl: WidthLike): Int     = wl.width

  class Protection extends Bundle {
    val prot = UInt(3.W)

    def defaults {
      prot := Protection(Protection.Flag.NON_PRIVILEGED, Protection.Flag.NON_SECURE).U
    }
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

  object Response {
    val okay :: exokay :: slverr :: decerr :: Nil = Enum(4)
  }

  class Strobe(dataWidth: Int) extends Bundle {
    val strb = UInt((dataWidth / 8).W)

    def defaults {
      strb := Strobe(0 until dataWidth / 8 :_*)
    }

    override def cloneType = { new Strobe(dataWidth).asInstanceOf[this.type] }
  }

  object Strobe {
    def apply(byteEnables: Int*): UInt = ((byteEnables map (i => (1 << i)) fold 0) (_ | _)).U
  }
}
