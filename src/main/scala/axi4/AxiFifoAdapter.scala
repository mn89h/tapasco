package chisel.axiutils
import  chisel.axi._
import  chisel.miscutils.Logging
import  chisel3._
import  chisel3.util._

object AxiFifoAdapter {
  /** Configuration parameters for AxiFifoAdapter.
   *  @param axi AXI-MM interface parameters.
   *  @param fifoDepth Depth of the backing FIFO (each element data width wide).
   *  @param burstSize Number of beats per burst (optional).
   *  @param size Address wrap-around after size elements (optional).
   **/
  sealed case class Configuration(fifoDepth: Int,
                                  burstSize: Option[Int] = None,
                                  size: Option[Int] = None)

  /** I/O bundle for AxiFifoAdapter. */
  class IO(cfg: Configuration)(implicit axi: Axi4.Configuration) extends Bundle {
    val enable = Input(Bool())
    val maxi   = Axi4.Master(axi)
    val deq    = Decoupled(UInt(axi.dataWidth))
    val base   = Input(UInt(axi.addrWidth))
  }

  /** Build an AxiFifoAdapter.
   *  @param cfg Configuration.
   *  @return AxiFifoAdapter instance.
   **/
  def apply(cfg: Configuration)(implicit axi: Axi4.Configuration, l: Logging.Level): AxiFifoAdapter =
    new AxiFifoAdapter(cfg)

  /** Build an AxiFifoAdapter.
   *  @param fifoDepth Depth of the backing FIFO (each element data width wide).
   *  @param burstSize Number of beats per burst (optional).
   *  @param size Address wrap-around after size elements (optional).
   *  @return AxiFifoAdapter instance.
   **/
  def apply(fifoDepth: Int,
            burstSize: Option[Int] = None,
            size: Option[Int] = None)
           (implicit axi: Axi4.Configuration, l: Logging.Level): AxiFifoAdapter =
    new AxiFifoAdapter(Configuration(fifoDepth = fifoDepth, burstSize = burstSize, size = size))
}

/** AxiFifoAdapter is simple DMA engine filling a FIFO via AXI-MM master.
 *  The backing FIFO is filled continuosly with bursts via the master
 *  interface; the FIFO itself uses handshakes for consumption.
 *  @param cfg Configuration parameters.
 **/
class AxiFifoAdapter(cfg: AxiFifoAdapter.Configuration)
                    (implicit axi: Axi4.Configuration,
                     logLevel: Logging.Level) extends Module with Logging{
  val bsz = cfg.burstSize.getOrElse(cfg.fifoDepth)

  require (cfg.size.map(s => log2Ceil(s) <= axi.addrWidth).getOrElse(true),
           "addrWidth (%d) must be large enough to address all %d elements, at least %d bits"
           .format(axi.addrWidth:Int, cfg.size.get, log2Ceil(cfg.size.get)))
  require (cfg.size.isEmpty,
           "size parameter is not implemented")
  require (bsz > 0 && bsz <= cfg.fifoDepth && bsz <= 256,
           "burst size (%d) must be 0 < bsz <= FIFO depth (%d) <= 256"
           .format(bsz, cfg.fifoDepth))

  cinfo ("AxiFifoAdapter: fifoDepth = %d, address bits = %d, data bits = %d, id bits = %d%s%s"
         .format(cfg.fifoDepth, axi.addrWidth:Int, axi.dataWidth:Int, axi.idWidth:Int,
                 cfg.burstSize.map(", burst size = %d".format(_)).getOrElse(""),
                 cfg.size.map(", size = %d".format(_)).getOrElse("")))

  val io = IO(new AxiFifoAdapter.IO(cfg))
  val en = RegNext(io.enable, init = false.B)

  val axi_read :: axi_wait :: Nil = Enum(2)


  val fifo  = Module(new Queue(UInt(axi.dataWidth), cfg.fifoDepth))
  val state = RegInit(axi_wait)
  val len   = RegInit(UInt(log2Ceil(bsz).W), (bsz - 1).U)
  val ra_hs = RegInit(Bool(), init = false.B)

  val maxi_rlast   = io.maxi.readData.bits.last
  val maxi_raddr   = RegInit(io.base)
  val maxi_ravalid = state === axi_read & ~ra_hs
  val maxi_raready = io.maxi.readAddr.ready
  val maxi_rready  = state === axi_read & fifo.io.enq.ready
  val maxi_rvalid  = state === axi_read & io.maxi.readData.valid

  io.deq                            <> fifo.io.deq
  fifo.io.enq.bits                  := io.maxi.readData.bits.data
  io.maxi.readData.ready            := maxi_rready
  io.maxi.readAddr.valid            := maxi_ravalid
  fifo.io.enq.valid                 := io.maxi.readData.valid

  // AXI boilerplate
  io.maxi.readAddr.bits.addr        := maxi_raddr
  io.maxi.readAddr.bits.burst.size  := (if (axi.dataWidth > 8) log2Ceil(axi.dataWidth / 8) else 0).U
  io.maxi.readAddr.bits.burst.len   := (bsz - 1).U
  io.maxi.readAddr.bits.burst.burst := Axi4.Burst.Type.incr
  io.maxi.readAddr.bits.id          := 0.U
  io.maxi.readAddr.bits.lock.lock   := 0.U
  io.maxi.readAddr.bits.cache.cache := Axi4.Cache.Read.WRITE_BACK_RW_ALLOCATE
  io.maxi.readAddr.bits.prot.prot   := 0.U
  io.maxi.readAddr.bits.qos         := 0.U

  // write channel tie-offs
  io.maxi.writeAddr.valid           := false.B
  io.maxi.writeData.valid           := false.B
  io.maxi.writeResp.ready           := false.B

  when (en) {
    when (state === axi_wait & fifo.io.count <= (cfg.fifoDepth - bsz).U) { state := axi_read }
    when (state === axi_read) {
      when (maxi_ravalid & maxi_raready) {
        maxi_raddr := maxi_raddr + (bsz * (axi.dataWidth / 8)).U
        ra_hs := true.B
      }
      when (maxi_rready & maxi_rvalid) {
        when (maxi_rlast) {
          state := Mux(fifo.io.count <= (cfg.fifoDepth - bsz).U, state, axi_wait)
          len := (bsz - 1).U
          ra_hs := false.B
        }
        .otherwise { len := len - 1.U }
      }
    }
  }
}
