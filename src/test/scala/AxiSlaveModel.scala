import Chisel._
import AXIDefs._

class AxiSlaveModelIO(addrWidth: Int, dataWidth: Int, idWidth: Int) extends Bundle {
  val saxi = new AXIMasterIF(addrWidth, dataWidth, idWidth).flip()
  val mem  = new Bundle {
    val d = UInt(OUTPUT, width = dataWidth)
    val addr = UInt(INPUT, width = addrWidth)
  }
}

class AxiSlaveModel(addrWidth: Int, dataWidth: Int, idWidth: Int) extends Module {
  val io = new AxiSlaveModelIO(addrWidth = addrWidth, dataWidth = dataWidth, idWidth = idWidth)
  val mem = Mem(scala.math.pow(2, addrWidth).toInt, UInt(width = dataWidth))

  val wa_valid = RegNext(io.saxi.writeAddr.valid)
  val wd_valid = RegNext(io.saxi.writeData.valid)
  val wr_ready = RegNext(io.saxi.writeResp.ready)
  val wa_addr  = RegNext(io.saxi.writeAddr.bits.addr)
  val wd_data  = RegNext(io.saxi.writeData.bits.data)

  val wa = Reg(UInt(width = addrWidth))
  val wd = Reg(UInt(width = dataWidth))
  val wr = Reg(UInt(width = 2))

  val wa_hs = Reg(Bool()) // address handshake complete?
  val wd_hs = Reg(Bool()) // data handshake complete?
  val wr_hs = Reg(Bool()) // response handshake complete?
  val wr_valid = Reg(Bool()) // response valid

  val raddr = RegNext(io.mem.addr)

  io.saxi.writeAddr.ready     := !wa_hs
  io.saxi.writeData.ready     := !wd_hs
  io.saxi.writeResp.bits.resp := wr
  io.saxi.writeResp.bits.id   := UInt(0)
  io.saxi.writeResp.valid     := wr_valid

  io.mem.d                    := mem(raddr)

  when (reset) {
    wa       := UInt(0)
    wd       := UInt(0)
    wr       := UInt(0) // OK
    wr_valid := Bool(false)
    wa_hs    := Bool(false)
    wd_hs    := Bool(false)
    wr_hs    := Bool(false)
    raddr    := UInt(0)
  }
  .otherwise {
    when (wa_valid) {
      wa     := wa_addr
      wa_hs  := Bool(true)
    }
    when (wd_valid) {
      wd      := wd_data
      wd_hs   := Bool(true)
    }
    when (wa_hs && wd_hs) {
      mem(wa)  := wd
      wr_valid := Bool(true)
    }
    when (wa_hs && wd_hs && wr_valid && wr_ready) {
      wa_hs    := Bool(false)
      wd_hs    := Bool(false)
      wr_valid := Bool(false)
    }
  }
}
