package chisel.axiutils
import Chisel._
import AXIDefs._

class AxiSlaveModelIO(val cfg: AxiSlaveModelConfiguration) extends Bundle {
  val saxi = new AXIMasterIF(cfg.addrWidth, cfg.dataWidth, cfg.idWidth).flip()
}

class AxiSlaveModel(val cfg: AxiSlaveModelConfiguration) extends Module {
  val aw = cfg.addrWidth
  val sz = cfg.size
  println ("AxiSlaveModel: %s".format(cfg.toString))

  val io = new AxiSlaveModelIO(cfg)
  val mem = Mem(sz, UInt(width = cfg.dataWidth))

  /** WRITE PROCESS **/
  val wa_valid = (io.saxi.writeAddr.valid)
  val wd_valid = (io.saxi.writeData.valid)
  val wr_ready = RegNext(io.saxi.writeResp.ready)
  val wa_addr  = (io.saxi.writeAddr.bits.addr)
  val wd_data  = (io.saxi.writeData.bits.data)
  val wa_len   = RegNext(io.saxi.writeAddr.bits.len)
  val wa_size  = RegNext(io.saxi.writeAddr.bits.size)
  val wa_burst = RegNext(io.saxi.writeAddr.bits.burst)

  val wa = Reg(UInt(width = aw))
  val wd = Reg(UInt(width = cfg.dataWidth))
  val wr = Reg(UInt(width = 2))
  val wl = Reg(io.saxi.writeAddr.bits.len.cloneType())

  val wa_hs = Reg(Bool()) // address handshake complete?
  val wd_hs = Reg(Bool()) // data handshake complete?
  val wr_hs = Reg(Bool()) // response handshake complete?
  val wr_valid = Reg(Bool()) // response valid
  val wr_wait = Reg(UInt(width = log2Up(cfg.writeDelay + 1)))

  /**
   * Returns data at address (dataWidth bits).
   * @param address AXI address (byte granularity).
   * @param t Tester instance.
   * @return value of internal memory (cfg.dataWidth bit wide).
   **/
  def at(address: Int)(implicit t: Tester[_]): BigInt  = {
    val idx = address / (cfg.dataWidth / 8)
    require (idx >= 0 && idx < cfg.size,
             "AxiSlaveModel: read at invalid index %d (max: %d) for address 0x%x"
             .format(idx, cfg.size - 1, address))
    t.peekAt(mem, address / (cfg.dataWidth / 8))
  }

  /**
   * Returns data at word index (dataWidth bits).
   * @param index Index into internal memory (cfg.dataWidth sized words).
   * @param t Tester instance.
   * @return value of internal memory (cfg.dataWidth bit wide)
   **/
  def apply(index: Int)(implicit t: Tester[_]): BigInt = {
    require (index >= 0 && index < cfg.size,
             "AxiSlaveModel: read at invalid index %d (max: %d)"
             .format(index, cfg.size - 1))
    t.peekAt(mem, index)
  }

  /**
   * Set data at address (dataWidth bits).
   * @param address AXI address (byte granularity, will be aligned automatically).
   * @param value Word value to set (always full word, cfg.dataWidth bits).
   * @param t Tester instance.
   **/
  def set(address: Int, value: BigInt)(implicit t: Tester[_]) =
    t.pokeAt(mem, value, address / (cfg.dataWidth / 8))

  io.saxi.writeAddr.ready     := !wa_hs
  io.saxi.writeData.ready     :=  wa_hs && !wr_valid && wr_wait === UInt(0)
  io.saxi.writeResp.bits.resp := wr
  io.saxi.writeResp.bits.id   := UInt(0)
  io.saxi.writeResp.valid     :=  wa_hs && wr_valid

  when (reset) {
    wa       := UInt(0)
    wd       := UInt(0)
    wr       := UInt(0) // OK
    wr_valid := Bool(false)
    wa_hs    := Bool(false)
    wd_hs    := Bool(false)
    wr_hs    := Bool(false)
    wr_wait  := UInt(0)
  }
  .otherwise {
    when (!wa_hs && wa_valid) {
      wa     := wa_addr
      wl     := wa_len
      wa_hs  := Bool(true)
      assert (wa_size === UInt(if (cfg.dataWidth > 8) log2Up(cfg.dataWidth / 8) else 0), "wa_size is not supported".format(wa_size))
      assert (wa_burst < UInt(2), "wa_burst type (b%s) not supported".format(wa_burst))
      if (cfg.writeDelay > 0) wr_wait := UInt(cfg.writeDelay)
    }
    when (wa_hs && wr_wait > UInt(0)) { wr_wait := wr_wait - UInt(1) }
    when (wa_hs && wr_wait === UInt(0)) {
      when (wa_hs && wd_valid && !wr_valid) {
        val shifted_addr   = if (cfg.dataWidth > 8) wa >> UInt(log2Up(cfg.dataWidth / 8)) else wa
        mem(shifted_addr) := wd_data
        printf("writing data 0x%x to address 0x%x (0x%x)\n", wd_data, wa, shifted_addr)
        when (io.saxi.writeData.bits.last || wl === UInt(0)) { wr_valid := Bool(true) }
        .otherwise {
          wl := wl - UInt(1)
          // increase address in INCR bursts
          when (wa_burst === UInt("b01")) { wa := wa + UInt(cfg.dataWidth / 8) }
        }
      }
      when (wa_hs && wr_valid && wr_ready) {
        wa_hs    := Bool(false)
        wd_hs    := Bool(false)
        wr_valid := Bool(false)
      }
    }
  }

  /** READ PROCESS **/
  val ra       = Reg(UInt(width = aw))
  val l        = Reg(UInt(width = 8))
  val ra_valid = RegNext(io.saxi.readAddr.valid)
  val ra_addr  = RegNext(io.saxi.readAddr.bits.addr)
  val ra_len   = RegNext(io.saxi.readAddr.bits.len)
  val ra_size  = RegNext(io.saxi.readAddr.bits.size)
  val ra_burst = RegNext(io.saxi.readAddr.bits.burst)

  val rr_resp  = UInt(0, width = 2) // response: OKAY

  val rr_wait  = Reg(UInt(width = log2Up(cfg.readDelay + 1)))
  val ra_hs    = Reg(Bool())
  val ra_ready = !reset && !ra_hs

  io.saxi.readAddr.ready := ra_ready

  val rd_valid = ra_hs && rr_wait === UInt(0)

  io.saxi.readData.valid := rd_valid
  io.saxi.readData.bits.data := mem(if (cfg.dataWidth > 8) ra >> UInt(log2Up(cfg.dataWidth / 8)) else ra)
  io.saxi.readData.bits.last := ra_hs && l === UInt(0)
  io.saxi.readData.bits.resp := rr_resp

  when (reset) {
    ra        := UInt(0)
    l         := UInt(1)
    ra_valid  := Bool(false)
    ra_addr   := UInt(0)
    ra_len    := UInt("hFF")
    ra_size   := UInt(0)
    ra_burst  := UInt(0)
    ra_hs     := Bool(false)
    rr_wait   := UInt(0)
  }
  .otherwise {
    when(io.saxi.readData.ready && io.saxi.readData.valid) {
      printf("reading data 0x%x from address 0x%x",
          io.saxi.readData.bits.data,
          if (cfg.dataWidth > 8) ra >> UInt(log2Up(cfg.dataWidth / 8)) else ra)
    }
    when (!ra_hs && io.saxi.readAddr.ready && io.saxi.readAddr.valid) {
      ra    := io.saxi.readAddr.bits.addr
      ra_hs := Bool(true)
      l     := io.saxi.readAddr.bits.len
      if (cfg.readDelay > 0) rr_wait := UInt(cfg.readDelay)
    }
    when (ra_hs && rr_wait > UInt(0)) { rr_wait := rr_wait - UInt(1) }
    when (rd_valid && io.saxi.readData.ready) {
      l      := l - UInt(1)
      ra     := ra + UInt(cfg.dataWidth / 8)
      when (l === UInt(0)) { ra_hs := Bool(false) }
    }
  }
}
