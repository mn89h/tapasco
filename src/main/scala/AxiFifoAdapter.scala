package chisel.axiutils
import Chisel._
import AXIDefs._

class AxiFifoAdapterIO(addrWidth: Int, dataWidth: Int, idWidth: Int) extends Bundle {
  val maxi = new AXIMasterIF(addrWidth, dataWidth, idWidth)
  val deq = Decoupled(UInt(width = dataWidth))
  val base = UInt(INPUT, width = addrWidth)
}

class AxiFifoAdapter(fifoDepth: Int,
                     addrWidth: Int,
                     dataWidth: Int,
                     idWidth: Int = 1,
                     burstSize: Option[Int] = None,
                     size: Option[Int] = None) extends Module {

  val bsz = burstSize.getOrElse(fifoDepth)

  require (size.map(s => log2Up(s) <= addrWidth).getOrElse(true),
           "addrWidth (%d) must be large enough to address all %d element, at least %d bits"
           .format(addrWidth, size.get, log2Up(size.get)))
  require (size.isEmpty,
           "size parameter is not implemented")
  require (bsz > 0 && bsz <= fifoDepth && bsz <= 256,
           "burst size (%d) must be 0 < bsz <= FIFO depth (%d) <= 256"
           .format(bsz, fifoDepth))

  println ("AxiFifoAdapter: fifoDepth = %d, address bits = %d, data bits = %d, id bits = %d%s%s"
           .format(fifoDepth, addrWidth, dataWidth, idWidth,
                   burstSize.map(", burst size = %d".format(_)).getOrElse(""),
                   size.map(", size = %d".format(_)).getOrElse("")))

  val io = new AxiFifoAdapterIO(addrWidth, dataWidth, idWidth)

  val fifo = Module(new Queue(UInt(width = dataWidth), fifoDepth))
  val axi_read :: axi_wait :: Nil = Enum(UInt(), 2)
  val state = Reg(init = axi_wait)
  val len = Reg(UInt(width = log2Up(bsz)))
  val maxi_rlast = io.maxi.readData.bits.last
  val maxi_raddr = Reg(init = io.base)
  val maxi_ravalid = !reset
  val maxi_raready = io.maxi.readAddr.ready
  val maxi_rready = state === axi_read && fifo.io.enq.ready
  val maxi_rvalid = state === axi_read && io.maxi.readData.valid

  io.deq                       <> fifo.io.deq
  fifo.io.enq.bits             := io.maxi.readData.bits.data
  io.maxi.readData.ready       := maxi_rready
  io.maxi.readAddr.valid       := maxi_ravalid
  fifo.io.enq.valid            := state === axi_read && maxi_rready && io.maxi.readData.valid

  // AXI boilerplate
  io.maxi.readAddr.bits.addr   := maxi_raddr
  io.maxi.readAddr.bits.size   := UInt(if (dataWidth > 8) log2Up(dataWidth / 8) else 0)
  io.maxi.readAddr.bits.len    := UInt(bsz - 1)
  io.maxi.readAddr.bits.burst  := UInt("b01") // INCR
  io.maxi.readAddr.bits.id     := UInt(0)
  io.maxi.readAddr.bits.lock   := UInt(0)
  io.maxi.readAddr.bits.cache  := UInt("b1111") // bufferable, write-back RW allocate
  io.maxi.readAddr.bits.prot   := UInt(0)
  io.maxi.readAddr.bits.qos    := UInt(0)

  // write channel tie-offs
  io.maxi.writeAddr.valid      := Bool(false)
  io.maxi.writeData.valid      := Bool(false)
  io.maxi.writeResp.ready      := Bool(false)

  when (reset) {
    state := axi_wait
    len   := UInt(bsz - 1)
  }
  .otherwise {
    when (state === axi_wait && fifo.io.count <= UInt(bsz - fifoDepth)) { state := axi_read }
    when (maxi_ravalid && maxi_raready) {
      maxi_raddr := maxi_raddr + UInt(bsz * (dataWidth / 8))
    }
    when (state === axi_read) {
      when (maxi_rready && maxi_rvalid) {
        when (maxi_rlast) {
          state := Mux(fifo.io.count <= UInt(bsz - fifoDepth), state, axi_wait)
          len := UInt(bsz - 1)
        }
        .otherwise { len := len - UInt(1) }
      }
    }
  }
}
