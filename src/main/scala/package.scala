package de.tu_darmstadt.cs.esa.tapasco
import scala.language.implicitConversions
import org.scalactic.anyvals.PosInt

package object tapasco_status {
  final val NUM_SLOTS = 128

  final case class SlotId(id: Int) {
    require (id >= 0 && id < NUM_SLOTS, s"slot id $id is invalid, must be 0 <= $id < $NUM_SLOTS")
  }

  final case class KernelId(id: Int) {
    require (id > 0, s"kernel id $id is invalid, must be > 0")
  }

  final case class Size(size: Int) {
    require (size > 0, s"memory size $size invalid, must be > 0")
    require ((size & (~size + 1)) == size, s"memory size $size invalid, must be a power of 2")
  }

  sealed trait SlotConfig
  object SlotConfig {
    final case class Kernel(slot: SlotId, kernel: KernelId) extends SlotConfig
    final case class Memory(slot: SlotId, size: Size) extends SlotConfig
  }

  final case class Status(config: Set[SlotConfig]) {
    require (config.nonEmpty, "a status configuration must not be empty")
  }

  object Status {
    def apply(s: SlotConfig, ss: SlotConfig*): Status = Status((s +: ss).toSet)
  }

  implicit def intToSlot(i: Int): SlotId = SlotId(i)
  implicit def slotToInt(s: SlotId): Int = s.id

  implicit def intToKernel(i: Int): KernelId = KernelId(i)
  implicit def slotToKernel(s: KernelId): Int = s.id

  implicit def sizeToInt(s: Size): Int = s.size
  implicit def intToSize(i: Int): Size = Size(i)
}
