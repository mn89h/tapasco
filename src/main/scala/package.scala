package de.tu_darmstadt.cs.esa.tapasco
import scala.language.implicitConversions

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

  final case class Versions(tapasco: Versions.Tapasco, vivado: Versions.Vivado)
  object Versions {
    sealed trait Version {
      require(year > 0, s"year $year is invalid, must be > 0")
      require(release > 0, s"release $release is invalid, must be > 0")
      def year: Int
      def release: Int
      def toHex: String = "0x%04x%04x".format(year, release)
      def unapply: (String, Int, Int)
    }
    final case class Tapasco(year: Int, release: Int) extends Version {
      def unapply = ("TaPaSCo", year, release)
    }
    final case class Vivado(year: Int, release: Int) extends Version {
      def unapply = ("Vivado", year, release)
    }
  }

  final case class Clocks(host: Clocks.HostFreq, design: Clocks.DesignFreq, memory: Clocks.MemFreq)

  object Clocks {
    sealed trait Frequency {
      require(frequency > 0, "frequency $frequency is invalid, must be > 0")
      def frequency: Double
      def unapply: (String, Double)
    }
    final case class HostFreq(frequency: Double) extends Frequency {
      def unapply = ("Host", frequency)
    }
    final case class DesignFreq(frequency: Double) extends Frequency {
      def unapply = ("Design", frequency)
    }
    final case class MemFreq(frequency: Double) extends Frequency {
      def unapply = ("Memory", frequency)
    }
  }

  sealed trait Slot {
    def slot: SlotId
  }
  object Slot {
    final case class Kernel(slot: SlotId, kernel: KernelId) extends Slot
    final case class Memory(slot: SlotId, size: Size) extends Slot
  }

  final case class Status(config: Seq[Slot],
                          timestamp: Int,
                          interruptControllers: Int,
                          versions: Versions,
                          clocks: Clocks) {
    require (config.nonEmpty, "a status configuration must not be empty")
    require ((config map (_.slot)).toSet.size == config.length, "slot ids must be unique")
  }

  implicit def intToSlot(i: Int): SlotId = SlotId(i)
  implicit def slotToInt(s: SlotId): Int = s.id

  implicit def intToKernel(i: Int): KernelId = KernelId(i)
  implicit def slotToKernel(s: KernelId): Int = s.id

  implicit def sizeToInt(s: Size): Int = s.size
  implicit def intToSize(i: Int): Size = Size(i)
}
