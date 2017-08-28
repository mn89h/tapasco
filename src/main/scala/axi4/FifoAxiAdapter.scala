package chisel.axiutils
import  chisel3._
import  chisel3.util._
import  chisel.axi.Axi4._

class FifoAxiAdapterIO(fifoDepth: Int)(implicit axi: Configuration) extends Bundle {
  val maxi  = Master(axi)
  val enq   = Flipped(Decoupled(UInt(axi.dataWidth)))
  val base  = Input(UInt(axi.addrWidth))
  val count = Output(UInt(log2Ceil(fifoDepth).W))
}

class FifoAxiAdapter(fifoDepth: Int,
                     burstSize: Option[Int] = None,
                     size: Option[Int] = None)
                    (implicit axi: Configuration) extends Module {

  val bsz = burstSize getOrElse fifoDepth

  require (size.map(s => log2Ceil(s) <= axi.addrWidth).getOrElse(true),
           "addrWidth (%d) must be large enough to address all %d elements, at least %d bits"
           .format(axi.addrWidth:Int, size.get, log2Ceil(size.get)))
  require (bsz > 0 && bsz <= fifoDepth && bsz <= 256,
           "burst size (%d) must be 0 < bsz <= FIFO depth (%d) <= 256"
           .format(bsz, fifoDepth))

  println ("FifoAxiAdapter: fifoDepth = %d, address bits = %d, data bits = %d, id bits = %d%s%s"
           .format(fifoDepth, axi.addrWidth:Int, axi.dataWidth:Int, axi.idWidth:Int,
                   burstSize.map(", burst size = %d".format(_)).getOrElse(""),
                   size.map(", size = %d".format(_)).getOrElse("")))

  val io = IO(new FifoAxiAdapterIO(fifoDepth))

  val axi_write :: axi_wait :: Nil = Enum(2)

  val fifo                     = Module(new Queue(UInt(axi.dataWidth), fifoDepth))
  val state                    = RegInit(axi_wait)
  val len                      = Reg(UInt(log2Ceil(bsz).W))
  val maxi_wlast               = state === axi_write && len === 0.U
  val maxi_waddr               = RegInit(io.base)
  val maxi_wavalid             = !reset && fifo.io.count >= bsz.U
  val maxi_waready             = io.maxi.writeAddr.ready
  val maxi_wready              = state === axi_write && io.maxi.writeData.ready
  val maxi_wvalid              = state === axi_write && fifo.io.deq.valid

  io.enq                             <> fifo.io.enq
  io.maxi.writeData.bits.last        := maxi_wlast
  io.maxi.writeData.bits.data        := fifo.io.deq.bits
  io.maxi.writeData.valid            := maxi_wvalid
  io.maxi.writeAddr.valid            := maxi_wavalid
  fifo.io.deq.ready                  := state === axi_write && io.maxi.writeData.ready
  io.count                           := fifo.io.count

  // AXI boilerplate
  io.maxi.writeAddr.bits.addr        := maxi_waddr
  io.maxi.writeAddr.bits.burst.size  := (if (axi.dataWidth > 8) log2Ceil(axi.dataWidth / 8) else 0).U
  io.maxi.writeAddr.bits.burst.len   := (bsz - 1).U
  io.maxi.writeAddr.bits.burst.burst := Burst.Type.incr
  io.maxi.writeAddr.bits.id          := 0.U
  io.maxi.writeAddr.bits.lock.lock   := 0.U
  io.maxi.writeAddr.bits.cache.cache := Cache.Write.WRITE_THROUGH_RW_ALLOCATE
  io.maxi.writeAddr.bits.prot.prot   := 0.U
  io.maxi.writeAddr.bits.qos         := 0.U
  io.maxi.writeData.bits.strb.strb   := ("b" + ("1" * (axi.dataWidth / 8))).U
  io.maxi.writeResp.ready            := 1.U // ignore responses

  // read channel tie-offs
  io.maxi.readAddr.valid             := false.B
  io.maxi.readData.ready             := false.B

  when (reset) {
    state := axi_wait
    len   := (bsz - 1).U
  }
  .otherwise {
    when (state === axi_wait && fifo.io.count >= bsz.U) { state := axi_write }
    when (maxi_wavalid && maxi_waready) {
      val addr_off  = (bsz * (axi.dataWidth / 8)).U
      val next_addr = maxi_waddr + addr_off
      if (size.isEmpty)
        maxi_waddr := next_addr
      else
        maxi_waddr := Mux(next_addr >= io.base + size.get.U, io.base, next_addr)
    }
    when (state === axi_write) {
      when (maxi_wready && maxi_wvalid) {
        when (maxi_wlast) {
          state := Mux(fifo.io.count >= bsz.U, state, axi_wait)
          len := (bsz - 1).U
        }
        .otherwise { len := len - 1.U }
      }
    }
  }
}
