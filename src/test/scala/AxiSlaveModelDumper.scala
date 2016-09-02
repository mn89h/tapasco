package chisel.axiutils
import Chisel._

/**
 * Helper companion: Dump complete memory of slave into file.
 **/
object AxiSlaveModelDumper {
  /**
   * Dumps the complete data of the AXI slave mode to a file.
   * @param m The slave model to dump.
   * @param filename Filename of dump file (paths will be created).
   * @param lineWidth Number of bytes per line in file (default: 16).
   * @param t Tester instance.
   **/
  def writeHexDump(m: AxiSlaveModel, filename: String, lineWidth: Int = 16)(implicit t: Tester[_]) {
    require (lineWidth >= m.cfg.dataWidth / 8, "lineWidth (%d) must be >= dataWidth / 8 (%d)"
        .format(lineWidth, m.cfg.dataWidth / 8))
    require ((lineWidth * 8) % m.cfg.dataWidth == 0,
        "lineWidth (%d) must be evenly divisible by word width (%d)"
        .format(lineWidth * 8, m.cfg.dataWidth))

    def hexAddr(addr: Int): String = "%%0%dx".format(m.cfg.addrWidth / 4).format(addr)
    def hexByte(v: Int): String = "%02x ".format(v)
    def asciiByte(v: Int): String = "%c".format(v) take 1
    def toBytes(v: BigInt): Seq[Int] = (for (i <- 0 until m.cfg.dataWidth / 8) yield ((v >> (i * 8)) & 0xFF).toInt).reverse
    def hexStr(vs: Seq[BigInt]): String = vs map toBytes reduce (_++_) map hexByte reduce (_++_)
    def asciiStr(vs: Seq[BigInt]): String = vs map toBytes reduce (_++_) map asciiByte reduce (_++_)
    def addrToIdx(addr: Int): Int = addr / (m.cfg.dataWidth / 8)
    def idxToAddr(idx: Int): Int = idx * (m.cfg.dataWidth / 8)

    java.nio.file.Paths.get(filename).toAbsolutePath.getParent.toFile.mkdirs()
    val fw = new java.io.FileWriter(filename)

    val lwords = (lineWidth * 8 / m.cfg.dataWidth)
    println("m.cfg.size = %d, lwords = %d".format(m.cfg.size, lwords))

    for (idx <- 0 until m.cfg.size if idx % lwords == 0;
         val words = for (i <- 0 until lwords) yield t.peekAt(m.mem, idx + i)) {
      fw.append("%s\t%s\t%s\n".format(hexAddr(idxToAddr(idx)), hexStr(words), asciiStr(words)))
    }

    fw.flush()
    fw.close()
  }
}
