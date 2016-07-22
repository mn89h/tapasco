package chisel.axiutils
import Chisel._
import AXIDefs._

class FifoAxiAdapterIO(addrWidth: Int, dataWidth: Int, idWidth: Int) extends Bundle {
  val maxi = new AXIMasterIF(addrWidth, dataWidth, idWidth)
  val enq = Decoupled(UInt(width = dataWidth)).flip()
  val base = UInt(INPUT, width = addrWidth)
}

class FifoAxiAdapter(fifoDepth: Int,
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
  require (bsz <= fifoDepth,
           "burst size (%d) must be smaller than fifo depth (%d)"
           .format(bsz, fifoDepth))

  println ("FifoAxiAdapter: fifoDepth = %d, address bits = %d, data bits = %d, id bits = %d%s%s"
           .format(fifoDepth, addrWidth, dataWidth, idWidth,
                   burstSize.map(", burst size = %d".format(_)).getOrElse(""),
                   size.map(", size = %d".format(_)).getOrElse("")))

  val io = new FifoAxiAdapterIO(addrWidth, dataWidth, idWidth)

  val fifo = Module(new Queue(UInt(width = dataWidth), fifoDepth))
  val axi_write :: axi_wait :: Nil = Enum(UInt(), 2)
  val state = Reg(init = axi_wait)
  val len = Reg(UInt(width = log2Up(bsz)))
  val maxi_wlast = len === UInt(0)
  val maxi_waddr = Reg(init = io.base)
  val maxi_wavalid = state === axi_write && maxi_wlast
  val maxi_waready = io.maxi.writeAddr.ready
  val maxi_wready = state === axi_write && io.maxi.writeData.ready
  val maxi_wvalid = state === axi_write && fifo.io.deq.valid

  io.enq                       <> fifo.io.enq
  io.maxi.writeData.bits.last  := maxi_wlast
  io.maxi.writeData.bits.data  := fifo.io.deq.bits
  io.maxi.writeData.valid      := maxi_wvalid
  io.maxi.writeAddr.valid      := maxi_wavalid
  fifo.io.deq.ready            := state === axi_write && io.maxi.writeData.ready

  // AXI boilerplate
  io.maxi.writeAddr.bits.addr  := maxi_waddr
  io.maxi.writeAddr.bits.size  := UInt(if (dataWidth > 8) log2Up(dataWidth / 8) else 0)
  io.maxi.writeAddr.bits.len   := UInt(bsz - 1)
  io.maxi.writeAddr.bits.burst := UInt("b01") // INCR
  io.maxi.writeAddr.bits.id    := UInt(0)
  io.maxi.writeAddr.bits.lock  := UInt(0)
  io.maxi.writeAddr.bits.cache := UInt("b1110") // write-through, RW allocate
  io.maxi.writeAddr.bits.prot  := UInt(0)
  io.maxi.writeAddr.bits.qos   := UInt(0)
  io.maxi.writeData.bits.strb  := UInt("b" + ("1" * (dataWidth / 8)))
  io.maxi.writeResp.ready      := UInt(1) // ignore responses

  // read channel tie-offs
  io.maxi.readAddr.valid       := Bool(false)
  io.maxi.readData.ready       := Bool(false)

  when (reset) {
    state := axi_wait
    len   := UInt(0)
  }
  .otherwise {
    when (state === axi_wait && fifo.io.count >= UInt(bsz)) { state := axi_write }
    when (state === axi_write) {
      when (maxi_wavalid && maxi_waready) {
        maxi_waddr := maxi_waddr + UInt(bsz * (dataWidth / 8))
        len := UInt(bsz - 1)
      }
      when (maxi_wready && maxi_wvalid) {
        when (maxi_wlast) { state := Mux(fifo.io.count >= UInt(bsz), state, axi_wait) }
        .otherwise { len := len - UInt(1) }
      }
    }
  }
}
