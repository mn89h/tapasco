package chisel.miscutils
import Chisel._

sealed case class Signal(value: Boolean, periods: Int = 1) extends Ordered[Signal] {
  import scala.math.Ordered.orderingToOrdered
  def compare(that: Signal): Int = periods compare that.periods
}

object SignalGenerator {
  type Waveform = List[Signal]
  implicit def makeSignal(sd: (Boolean, Int)): Signal = Signal(sd._1, sd._2)
  implicit def makeWaveform(ls: List[(Boolean, Int)]): Waveform = ls map makeSignal
}

class SignalGenerator(signals: SignalGenerator.Waveform, useInputAsClock: Boolean = false) extends Module {
  require (signals.length > 0, "Waveform must not be empty.")
  require (signals map (_.periods > 1) reduce (_&&_),
      "All signals must have at least two clock cycles length.")
  val io = new Bundle { val v = Bool(OUTPUT); val in = Bool(INPUT) }
  val cnts_rom = Vec(signals map (n => UInt(n.periods - 1)))
  val vals_rom = Vec(signals map (n => Bool(n.value)))
  val cnt      = Reg(UInt(width = log2Up(signals.max.periods)))
  val curr_idx = Reg(UInt(width = log2Up(signals.length)))
  val vreg     = Reg(Bool())

  io.v := vreg

  when (reset) {
    curr_idx := UInt(0)
    cnt      := cnts_rom(0)
    vreg     := UInt(0)
  }
  .otherwise {
    vreg := vals_rom(curr_idx)
    // trigger on either clock or pos input edge
    when (if (useInputAsClock) io.in && !RegNext(io.in) else Bool(true)) {
      when (cnt === UInt(0)) {
        val next_idx = Mux(curr_idx < UInt(signals.length - 1), curr_idx + UInt(1), UInt(0))
        curr_idx    := next_idx
        cnt         := cnts_rom(next_idx)
      }
      .otherwise {
        cnt := cnt - UInt(1)
      }
    }
  }
}
