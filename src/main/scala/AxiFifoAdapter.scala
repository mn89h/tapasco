package chisel.axiutils
import Chisel._
import AXIDefs._

class AxiFifoAdapter(
    fifoDepth: Int,
    addrWidth: Int,
    dataWidth: Int,
    idWidth  : Int = 1
  ) extends Module {

  require (fifoDepth > 0, "FIFO depth (%d) must be > 0".format(fifoDepth))
  require (fifoDepth <= 256, "FIFO depth (%d) must be <= 256".format(fifoDepth))
  require (addrWidth > 0 && addrWidth <= 64, "AXI address width (%d) must 0 < width <= 64".format(addrWidth))
  require (dataWidth >= 8 && dataWidth <= 256, "AXI data width (%d) must be 8 <= width <= 256".format(dataWidth))
  require ((for (i <- 1 to 7) yield scala.math.pow(2, i).toInt).contains(dataWidth), "AXI data width (%d) must be a power of 2".format(dataWidth))
  require ((idWidth > 0), "AXI id width (%d) must be > 0".format(idWidth))

  val io = new Bundle {
    val maxi = new AXIMasterIF(addrWidthBits = addrWidth, dataWidthBits = dataWidth, idBits = idWidth)
    val deq  = Decoupled(UInt(width = dataWidth))
    val base = UInt(INPUT, width = addrWidth)
    maxi.renameSignals()
    base.setName("base")
  }

  val axi_fetch :: axi_wait :: Nil = Enum(UInt(), 2)
  val axi_state        = Reg(init = axi_wait)

  val fifo_a           = Module(new Queue(UInt(width = dataWidth), fifoDepth))
  val fifo_b           = Module(new Queue(UInt(width = dataWidth), fifoDepth))
  val fifo_sel         = Reg(Bool())

  io.deq.valid        := Mux(!fifo_sel, fifo_a.io.deq.valid, fifo_b.io.deq.valid)
  io.deq.bits         := Mux(!fifo_sel, fifo_a.io.deq.bits, fifo_b.io.deq.bits)
  fifo_a.io.deq.ready := !fifo_sel && io.deq.ready
  fifo_b.io.deq.ready :=  fifo_sel && io.deq.ready

  val maxi_rdata       = (io.maxi.readData.bits.data)
  val maxi_rlast       = (io.maxi.readData.bits.last)
  val maxi_rvalid      = (io.maxi.readData.valid)
  val maxi_rready      = (Mux(fifo_sel, fifo_a.io.enq.ready, fifo_b.io.enq.ready))

  fifo_a.io.enq.bits  := (maxi_rdata)
  fifo_a.io.enq.valid :=  fifo_sel && maxi_rready && maxi_rvalid

  fifo_b.io.enq.bits  := (maxi_rdata)
  fifo_b.io.enq.valid := !fifo_sel && maxi_rready && maxi_rvalid

  val maxi_raddr       = Reg(init = io.base)
  val maxi_raddr_hs    = Reg(Bool())
  val maxi_ravalid     = axi_state === axi_fetch && !maxi_raddr_hs
  val maxi_raready     = (io.maxi.readAddr.ready)

  io.maxi.readAddr.bits.addr := maxi_raddr
  io.maxi.readAddr.valid     := maxi_ravalid

  io.maxi.readAddr.bits.size := UInt(log2Up(dataWidth / 8 - 1))
  io.maxi.readAddr.bits.len  := UInt(fifoDepth - 1)
  io.maxi.readAddr.bits.burst:= UInt("b01") // INCR
  io.maxi.readAddr.bits.id   := UInt(0)
  io.maxi.readAddr.bits.lock := UInt(0)
  io.maxi.readAddr.bits.cache:= UInt("b1110") // write-through, RW alloc
  io.maxi.readAddr.bits.prot := UInt(0)
  io.maxi.readAddr.bits.qos  := UInt(0)

  io.maxi.readData.ready     := maxi_rready

  when (reset) {
    fifo_sel          := Bool(false)
    axi_state         := axi_wait
    maxi_raddr        := UInt(0)
    maxi_raddr_hs     := Bool(false)
  }
  .otherwise {
    when (axi_state === axi_fetch) {  // fetch data state
      // handshake current address
      when (maxi_raready && maxi_ravalid) {
        maxi_raddr_hs := Bool(true)
        maxi_raddr    := maxi_raddr + UInt((dataWidth * fifoDepth) / 8)
      }
      // when read data is valid, enq fifo is ready and last is set
      when (maxi_rready && maxi_rvalid && maxi_rlast) {
        // go to wait state
        axi_state     := axi_wait
        maxi_raddr_hs := Bool(false)
      }
    }
    .otherwise { // wait-for-consumption state 
      // check fill state of deq FIFO: if empty, flip FIFOs
      when (Mux(!fifo_sel, !fifo_a.io.deq.valid, !fifo_b.io.deq.valid)) {
        fifo_sel      := !fifo_sel
      }
      // check fill state of other FIFO
      when (Mux( fifo_sel, !fifo_a.io.deq.valid, !fifo_b.io.deq.valid)) {
        // if empty, start fetch
        axi_state     := axi_fetch
      }
    }
  }
}

