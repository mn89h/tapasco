package chisel.axi

package object axi4lite {
  /** Tuple-type for bit ranges. */
  sealed case class BitRange(to: Int, from: Int) {
    require (to >= from && from >= 0, "BitRange: invalid range (%d, %d)".format(to, from))
    def overlapsWith(other: BitRange): Boolean = !(to < other.from || from > other.to)
  }

  /** Short-hand for single bit BitRanges. */
  object Bit {
    def apply(bit: Int): BitRange = {
      require (bit >= 0, s"BitRange: invalid bit ($bit)")
      BitRange(bit, bit)
    }
  }

  /** Names for bit ranges. **/
  type BitfieldMap = Map[String, BitRange]
}
