package chisel
import  chisel3._
import  chisel3.internal.firrtl.Width

package object axi {
  sealed trait WidthLike { def width: Int }
  final case class AddrWidth(width: Int) extends WidthLike {
    require (width > 0 && width <= 64, "addrWidth (%d) must be 0 < addrWidth <= 64".format(width))
  }
  final case class DataWidth(width: Int) extends WidthLike {
    require (width > 0 && width <= 4096, "dataWidth (%d) must be 0 < dataWidth <= 4096".format(width))
  }
  final case class IdWidth(width: Int) extends WidthLike
  final case class UserWidth(width: Int) extends WidthLike
  final case class RegionWidth(width: Int) extends WidthLike

  implicit def fromWidthLikeToWidth(wl: WidthLike): Width = wl.width.W
  implicit def fromWidthLikeToInt(wl: WidthLike): Int     = wl.width
}
