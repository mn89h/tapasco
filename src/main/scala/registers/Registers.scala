package chisel.axiutils.registers
import Chisel.{Reg, UInt}

/**
 * Abstract base class for control registers.
 * Provides base methods for describing and accessing control register data.
 * @param _name Name of the register (optional).
 * @param bitfield Bit partitioning of the value (optional).
 **/
sealed abstract class ControlRegister(_name: Option[String], bitfield: BitfieldMap = Map()) {
  /** Format description string for bitfield (if any). **/
  private def bf: String = bitfield.toList.sortWith((a, b) => a._2.to > b._2.to) map (e =>
      "_%d-%d:_ %s".format(e._2.to, e._2.from, e._1)
    ) mkString (" ")

  /** Name of the register. **/
  def name: Option[String] = _name

  /** Description of the register. **/
  def description: String  = if (bitfield.size > 0) bf else _name.getOrElse("N/A")

  /** Access to named bit range. **/
  def apply(s: String): Option[UInt] = read() map { v =>
    bitfield getOrElse (s, None) match { case BitRange(to, from) => v(to, from) }
  }
  /** Perform Chisel wiring to value. **/
  def write(v: UInt): Boolean = false

  /** Perform Chisel read on value. **/
  def read(): Option[UInt]
}

/**
 * Control register with an constant value (no write).
 * @param name Name of the register (optional).
 * @param bitfield Bit partitioning of the value (optional).
 * @param value Constant value for the register.
 **/
class ConstantRegister(name: Option[String] = None, bitfield: BitfieldMap = Map(), value: BigInt)
extends ControlRegister(name, bitfield) {
  override def description: String = "%s - _const:_ 0x%x (%d)".format(super.description, value, value)
  def read(): Option[UInt] = Some(UInt(value))
}

/**
 * Basic register with internal Chisel Reg (read/write).
 * @param name Name of the register (optional).
 * @param bitfield Bit partitioning of the value (optional).
 **/
class Register[T <: UInt](name: Option[String] = None, bitfield: BitfieldMap = Map(), width: Int)
extends ControlRegister(name, bitfield) {
  private lazy val _r = Reg(UInt(width = width))
  def read(): Option[UInt] = Some(_r)
  override def write(v: UInt) = {
    _r := v
    true
  }
}

/**
 * Virtual register: read and write callbacks are triggered on access.
 * @param name Name of the register (optional).
 * @param bitfield Bit partitioning of the value (optional).
 * @param onRead Callback for read access.
 * @param onWrite Callback for write access.
 **/
class VirtualRegister(name: Option[String] = None, bitfield: BitfieldMap = Map(), onRead: () => Option[UInt], onWrite: UInt => Boolean)
extends ControlRegister(name, bitfield) {
  def read() = onRead()
  override def write(v: UInt) = onWrite(v)
}

