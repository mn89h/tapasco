package chisel.axiutils
import Chisel._

/**
 * AXI4Lite master transaction model.
 * @param isRead true for read transactions.
 * @param addr address to read from.
 * @param value write value (optional)
 **/
case class MasterAction(isRead: Boolean = true, addr: Int, value: Option[BigInt])

/**
 * Axi4LiteProgrammableMaster is a testing tool to perform a sequence of master actions.
 * It automatically performs simple AXI4Lite transactions on slave.
 * @param action Sequence of transactions, executed sequentially without delay.
 * @param axi implicit AXI configuration.
 **/
class Axi4LiteProgrammableMaster(action: Seq[MasterAction])(implicit axi: AxiConfiguration) extends Module {
  import AXILiteDefs._
  val io = new Bundle {
    val maxi = new AXILiteMasterIF(axi.addrWidth, axi.dataWidth)
    val out  = Decoupled(UInt(width = axi.dataWidth))
    val finished = Bool(OUTPUT)
    val w_resp = Decoupled(UInt(width = 2))
  }

  val cnt = Reg(UInt(width = log2Up(action.length + 1))) // current action; last value indicates completion
  val s_addr :: s_wtransfer :: s_rtransfer :: s_response :: s_idle :: Nil = Enum(UInt(), 5)
  val state = Reg(init = s_addr)
  val w_data = Reg(UInt(width = axi.dataWidth))
  val r_data = RegNext(io.maxi.readData.bits.data)

  val q = Module(new Queue(UInt(width = axi.dataWidth), action.length))

  q.io.enq.valid                 := Bool(false)
  q.io.enq.bits                  := io.maxi.readData.bits.data
  io.maxi.readData.ready         := q.io.enq.ready
  io.out <> q.io.deq

  io.maxi.writeData.bits.data    := w_data
  io.maxi.writeData.valid        := state === s_wtransfer
  io.maxi.readAddr.valid         := Bool(false)
  io.maxi.writeAddr.valid        := Bool(false)

  io.maxi.readAddr.bits.addr     := UInt(0)
  io.maxi.writeAddr.bits.addr    := UInt(0)

  io.w_resp <> io.maxi.writeResp
  io.maxi.writeResp.ready        := Bool(true)

  io.finished                    := cnt === UInt(action.length)

  when (reset) {
    cnt := UInt(0)
  }
  .otherwise {
    // always assign address from current action
    for (i <- 0 until action.length) {
      when (UInt(i) === cnt) {
        io.maxi.readAddr.bits.addr  := UInt(action(i).addr)
        io.maxi.writeAddr.bits.addr := UInt(action(i).addr)
      }
    }

    when (state === s_addr) {
      for (i <- 0 until action.length) {
        when (UInt(i) === cnt) {
          io.maxi.readAddr.valid  := Bool(action(i).isRead)
          io.maxi.writeAddr.valid := Bool(! action(i).isRead)
          action(i).value map { v => w_data := UInt(v) }
        }
      }
      when (io.maxi.readAddr.ready && io.maxi.readAddr.valid)   { state := s_rtransfer }
      when (io.maxi.writeAddr.ready && io.maxi.writeAddr.valid) { state := s_wtransfer }
      when (cnt === UInt(action.length))                        { state := s_idle      }
    }

    when (state === s_rtransfer) {
      for (i <- 0 until action.length) {
        val readReady  = Bool(action(i).isRead) && io.maxi.readData.ready && io.maxi.readData.valid
        when (UInt(i) === cnt && readReady) {
          q.io.enq.valid := io.maxi.readData.bits.resp === UInt(0) // response OKAY
          cnt := cnt + UInt(1)
          state := s_addr
        }
      }
    }

    when (state === s_wtransfer) {
      for (i <- 0 until action.length) {
        val writeReady = Bool(!action(i).isRead) && io.maxi.writeData.ready && io.maxi.writeData.valid
        when (UInt(i) === cnt && writeReady) {
          cnt := cnt + UInt(1)
          state := s_response
        }
      }
    }

    when (state === s_response && io.maxi.writeResp.valid) { state := s_addr }
  }
}

