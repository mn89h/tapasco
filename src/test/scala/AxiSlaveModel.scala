package chisel.axiutils
import Chisel._
import AXIDefs._

class AxiSlaveModelIO(addrWidth: Int, dataWidth: Int, idWidth: Int) extends Bundle {
  val saxi = new AXIMasterIF(addrWidth, dataWidth, idWidth).flip()
}

class AxiSlaveModel(val addrWidth: Option[Int],
                    val dataWidth: Int,
                    val idWidth: Int = 1,
                    val size: Option[Int] = None) extends Module {
  require (idWidth == 1, "only idWidth = 1 supported at the moment")
  require (!size.isEmpty || !addrWidth.isEmpty, "specify size or addrWidth, or both")

  val aw = addrWidth.getOrElse(scala.math.pow(2, size.get * (dataWidth / 8)).toInt)
  val sz = size.getOrElse(scala.math.pow(2, addrWidth.get).toInt)
  println ("AxiSlaveModel: address bits = %d, size = %d".format(aw, sz))

  val io = new AxiSlaveModelIO(addrWidth = aw, dataWidth = dataWidth, idWidth = idWidth)
  val mem = Mem(sz, UInt(width = dataWidth))

  /** WRITE PROCESS **/
  val wa_valid = RegNext(io.saxi.writeAddr.valid)
  val wd_valid = (io.saxi.writeData.valid)
  val wr_ready = RegNext(io.saxi.writeResp.ready)
  val wa_addr  = RegNext(io.saxi.writeAddr.bits.addr)
  val wd_data  = (io.saxi.writeData.bits.data)
  val wa_len   = RegNext(io.saxi.writeAddr.bits.len)
  val wa_size  = RegNext(io.saxi.writeAddr.bits.size)
  val wa_burst = RegNext(io.saxi.writeAddr.bits.burst)

  val wa = Reg(UInt(width = aw))
  val wd = Reg(UInt(width = dataWidth))
  val wr = Reg(UInt(width = 2))
  val wl = Reg(io.saxi.writeAddr.bits.len.cloneType())

  val wa_hs = Reg(Bool()) // address handshake complete?
  val wd_hs = Reg(Bool()) // data handshake complete?
  val wr_hs = Reg(Bool()) // response handshake complete?
  val wr_valid = Reg(Bool()) // response valid

  io.saxi.writeAddr.ready     := !wa_hs
  io.saxi.writeData.ready     :=  wa_hs && !wr_valid
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
  }
  .otherwise {
    when (!wa_hs && wa_valid) {
      wa     := wa_addr
      wl     := wa_len
      wa_hs  := Bool(true)
      assert (wa_size === UInt(if (dataWidth > 8) log2Up(dataWidth / 8) else 0), "wa_size is not supported".format(wa_size))
      assert (wa_burst < UInt(2), "wa_burst type (b%s) not supported".format(wa_burst))
    }
    when (wa_hs && wd_valid && !wr_valid) {
      mem(if (dataWidth > 8) wa >> UInt(log2Up(dataWidth / 8)) else wa) := wd_data
      printf("writing data 0x%x to address 0x%x\n", wd_data, wa)
      when (io.saxi.writeData.bits.last || wl === UInt(0)) { wr_valid := Bool(true) }
      .otherwise {
        wl := wl - UInt(1)
        // increase address in INCR bursts
        when (wa_burst === UInt("b01")) { wa := wa + UInt(dataWidth / 8) }
      }
    }
    when (wa_hs && wr_valid && wr_ready) {
      wa_hs    := Bool(false)
      wd_hs    := Bool(false)
      wr_valid := Bool(false)
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

  val ra_hs    = Reg(Bool())
  val ra_ready = !reset && !ra_hs


  io.saxi.readAddr.ready := ra_ready

  io.saxi.readData.valid := ra_hs
  io.saxi.readData.bits.data := mem(if (dataWidth > 8) ra >> UInt(log2Up(dataWidth / 8)) else ra)
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
  }
  .otherwise {
    when (!ra_hs && io.saxi.readAddr.ready && io.saxi.readAddr.valid) {
      ra    := io.saxi.readAddr.bits.addr
      ra_hs := Bool(true)
      l     := io.saxi.readAddr.bits.len
    }
    when (ra_hs && io.saxi.readData.ready) {
      l      := l - UInt(1)
      ra     := ra + UInt(dataWidth / 8)
      when (l === UInt(0)) { ra_hs := Bool(false) }
    }
  }
}
