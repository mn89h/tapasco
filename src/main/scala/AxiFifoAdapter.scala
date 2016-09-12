package chisel.axiutils
import Chisel._
import AXIDefs._

/**
 * Configuration parameters for AxiFifoAdapter.
 * @param axi AXI-MM interface parameters.
 * @param fifoDepth Depth of the backing FIFO (each element data width wide).
 * @param burstSize Number of beats per burst (optional).
 * @param size Address wrap-around after size elements (optional).
 **/
sealed case class AxiFifoAdapterConfiguration(
  axi: AxiConfiguration,
  fifoDepth: Int,
  burstSize: Option[Int] = None,
  size: Option[Int] = None
)

/**
 * I/O bundle for AxiFifoAdapter.
 **/
class AxiFifoAdapterIO(cfg: AxiFifoAdapterConfiguration) extends Bundle {
  val maxi = new AXIMasterIF(cfg.axi.addrWidth, cfg.axi.dataWidth, cfg.axi.idWidth)
  val deq = Decoupled(UInt(width = cfg.axi.dataWidth))
  val base = UInt(INPUT, width = cfg.axi.addrWidth)
}

/**
 * AxiFifoAdapter is simple DMA engine filling a FIFO via AXI-MM master.
 * The backing FIFO is filled continuosly with burst via the master
 * interface; the FIFO itself uses handshakes for consumption.
 * @param cfg Configuration parameters.
 **/
class AxiFifoAdapter(cfg: AxiFifoAdapterConfiguration) extends Module {
  val bsz = cfg.burstSize.getOrElse(cfg.fifoDepth)

  require (cfg.size.map(s => log2Up(s) <= cfg.axi.addrWidth).getOrElse(true),
           "addrWidth (%d) must be large enough to address all %d element, at least %d bits"
           .format(cfg.axi.addrWidth, cfg.size.get, log2Up(cfg.size.get)))
  require (cfg.size.isEmpty,
           "size parameter is not implemented")
  require (bsz > 0 && bsz <= cfg.fifoDepth && bsz <= 256,
           "burst size (%d) must be 0 < bsz <= FIFO depth (%d) <= 256"
           .format(bsz, cfg.fifoDepth))

  println ("AxiFifoAdapter: fifoDepth = %d, address bits = %d, data bits = %d, id bits = %d%s%s"
           .format(cfg.fifoDepth, cfg.axi.addrWidth, cfg.axi.dataWidth, cfg.axi.idWidth,
                   cfg.burstSize.map(", burst size = %d".format(_)).getOrElse(""),
                   cfg.size.map(", size = %d".format(_)).getOrElse("")))

  val io = new AxiFifoAdapterIO(cfg)

  val fifo = Module(new Queue(UInt(width = cfg.axi.dataWidth), cfg.fifoDepth))
  val axi_read :: axi_wait :: Nil = Enum(UInt(), 2)
  val state = Reg(init = axi_wait)
  val len = Reg(UInt(width = log2Up(bsz)))
  val ra_hs = Reg(Bool())

  val maxi_rlast = io.maxi.readData.bits.last
  val maxi_raddr = Reg(init = io.base)
  val maxi_ravalid = !reset && state === axi_read && !ra_hs
  val maxi_raready = io.maxi.readAddr.ready
  val maxi_rready = !reset && state === axi_read && fifo.io.enq.ready
  val maxi_rvalid = state === axi_read && io.maxi.readData.valid

  io.deq                       <> fifo.io.deq
  fifo.io.enq.bits             := io.maxi.readData.bits.data
  io.maxi.readData.ready       := maxi_rready
  io.maxi.readAddr.valid       := maxi_ravalid
  fifo.io.enq.valid            := io.maxi.readData.valid

  // AXI boilerplate
  io.maxi.readAddr.bits.addr   := maxi_raddr
  io.maxi.readAddr.bits.size   := UInt(if (cfg.axi.dataWidth > 8) log2Up(cfg.axi.dataWidth / 8) else 0)
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
    state       := axi_wait
    len         := UInt(bsz - 1)
    maxi_raddr  := io.base
    ra_hs       := Bool(false)
  }
  .otherwise {
    when (state === axi_wait && fifo.io.count <= UInt(cfg.fifoDepth - bsz)) { state := axi_read }
    when (state === axi_read) {
      when (maxi_ravalid && maxi_raready) {
        maxi_raddr := maxi_raddr + UInt(bsz * (cfg.axi.dataWidth / 8))
        ra_hs := Bool(true)
      }
      when (maxi_rready && maxi_rvalid) {
        when (maxi_rlast) {
          state := Mux(fifo.io.count <= UInt(cfg.fifoDepth - bsz), state, axi_wait)
          len := UInt(bsz - 1)
          ra_hs := Bool(false)
        }
        .otherwise { len := len - UInt(1) }
      }
    }
  }
}

/** AxiFifoAdapter companion object: Factory methods. **/
object AxiFifoAdapter {
  /**
   * Build an AxiFifoAdapter.
   * @param cfg Configuration.
   * @return AxiFifoAdapter instance.
   **/
  def apply(cfg: AxiFifoAdapterConfiguration): AxiFifoAdapter = new AxiFifoAdapter(cfg)

  /**
   * Build an AxiFifoAdapter.
   * @param fifoDepth Depth of the backing FIFO (each element data width wide).
   * @param addrWidth Width of AXI address line in bits.
   * @param dataWidth Width of AXI data line in bits.
   * @param idWidth Width of AXI id line in bits.
   * @param burstSize Number of beats per burst (optional).
   * @param size Address wrap-around after size elements (optional).
   * @return AxiFifoAdapter instance.
   **/
  def apply(fifoDepth: Int,
            addrWidth: Int,
            dataWidth: Int,
            idWidth: Int = 1,
            burstSize: Option[Int] = None,
            size: Option[Int] = None): AxiFifoAdapter =
    new AxiFifoAdapter(AxiFifoAdapterConfiguration(
        axi = AxiConfiguration(addrWidth, dataWidth, idWidth),
        fifoDepth = fifoDepth,
        burstSize = burstSize,
        size = size))
}
