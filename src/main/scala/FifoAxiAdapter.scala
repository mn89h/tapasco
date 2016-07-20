package chisel.axiutils
import Chisel._
import AXIDefs._

class FifoAxiAdapterIO(addrWidth: Int, dataWidth: Int, idWidth: Int) extends Bundle {
  val maxi = new AXIMasterIF(addrWidth, dataWidth, idWidth)
  val inq = Decoupled(UInt(width = dataWidth)).flip()
  val base = UInt(INPUT, width = addrWidth)
}

class FifoAxiAdapter(addrWidth: Int,
                     dataWidth: Int,
                     idWidth: Int,
                     size: Int,
                     stride: Int = 1) extends Module {
  require (log2Up(size) <= addrWidth, "addrWidth (%d) must be large enough to address all %d element, at least %d bits".format(addrWidth, size, log2Up(size)))

  val io = new FifoAxiAdapterIO(addrWidth, dataWidth, idWidth)
  val wdata_valid = /*RegNext(*/io.inq.valid/*)*/
  val offs = Reg(UInt(width = log2Up(size)))
  val addr = RegNext(io.base) + offs
  val data = io.inq.bits

  val wa_ready = RegNext(io.maxi.writeAddr.ready)
  val wd_ready = RegNext(io.maxi.writeData.ready)
  val wr_valid = RegNext(io.maxi.writeResp.valid)

  val addr_hs = Reg(Bool())
  val data_hs = Reg(Bool())
  val resp_hs = Reg(Bool())

  io.maxi.writeAddr.valid      := !reset && wdata_valid && !addr_hs
  io.maxi.writeAddr.bits.addr  := addr

  io.maxi.writeAddr.bits.size  := UInt(2) // one word (4 byte)
  io.maxi.writeAddr.bits.len   := UInt(0) // single word len
  io.maxi.writeAddr.bits.burst := UInt(0) // no burst
  io.maxi.writeAddr.bits.id    := UInt(0) // id=0
  io.maxi.writeAddr.bits.lock  := UInt(0) // no lock
  io.maxi.writeAddr.bits.cache := UInt(2) // no cache, modifiable
  io.maxi.writeAddr.bits.prot  := UInt(0) // no prot
  io.maxi.writeAddr.bits.qos   := UInt(0) // no qos

  io.maxi.writeData.bits.data  := data
  io.maxi.writeData.bits.last  := Bool(true)
  io.maxi.writeData.bits.strb  := UInt("b1111")
  io.maxi.writeData.valid      := !reset && wdata_valid && !data_hs

  io.maxi.writeResp.ready      := Bool(true)

  io.inq.ready := addr_hs && data_hs && resp_hs

  when (reset) {
    offs    := UInt(0)
    addr_hs := Bool(false)
    data_hs := Bool(false)
    resp_hs := Bool(false)
  }
  .otherwise {
    when (wdata_valid && wa_ready) { addr_hs := Bool(true) }
    when (wdata_valid && wd_ready) { data_hs := Bool(true) }
    when (wr_valid) { resp_hs := Bool(true) }
    when (addr_hs && data_hs && resp_hs) {
      offs    := offs + UInt(dataWidth / 8 * stride) // stride to bytes
      addr_hs := Bool(false)
      data_hs := Bool(false)
      resp_hs := Bool(false)
    }
  }
}
