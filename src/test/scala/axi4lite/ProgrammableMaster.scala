package chisel.axiutils.axi4lite
import  chisel3._
import  chisel3.util._
import  chisel.axi._

/** AXI4Lite master transaction model.
 *  @param isRead true for read transactions.
 *  @param addr address to read from.
 *  @param value write value (optional)
 **/
sealed abstract trait MasterAction {
  def isRead: Boolean
  def address: Int
  def value: Option[BigInt]
}

final case class MasterRead(address: Int) extends MasterAction {
  def isRead: Boolean = true
  def value: Option[BigInt] = None
}

final case class MasterWrite(address: Int, v: BigInt) extends MasterAction {
  def isRead: Boolean = false
  def value: Option[BigInt] = Some(v)
}

/** Axi4LiteProgrammableMaster is a testing tool to perform a sequence of master actions.
 *  It automatically performs simple AXI4Lite transactions on slave.
 *  @param action Sequence of transactions, executed sequentially without delay.
 *  @param axi implicit AXI configuration.
 **/
class ProgrammableMaster(action: Seq[MasterAction])
                        (implicit axi: Axi4Lite.Configuration) extends Module {
  val io = IO(new Bundle {
    val maxi     = Axi4Lite.Master(axi)
    val out      = Decoupled(UInt(axi.dataWidth))
    val finished = Output(Bool())
    val w_resp   = Irrevocable(new chisel.axi.Axi4Lite.WriteResponse)
  })

  val cnt = RegInit(UInt(log2Ceil(action.length + 1).W), init = 0.U) // current action; last value indicates completion
  val s_addr :: s_wtransfer :: s_rtransfer :: s_response :: s_idle :: Nil = Enum(5)
  val state = RegInit(s_addr)
  val w_data = Reg(UInt(axi.dataWidth))
  val r_data = RegNext(io.maxi.readData.bits.data)

  val q = Module(new Queue(UInt(axi.dataWidth), action.length))

  q.io.enq.valid                 := false.B
  q.io.enq.bits                  := io.maxi.readData.bits.data
  io.maxi.readData.ready         := q.io.enq.ready
  io.out <> q.io.deq

  io.maxi.writeData.bits.data    := w_data
  io.maxi.writeData.valid        := state === s_wtransfer
  io.maxi.readAddr.valid         := false.B
  io.maxi.writeAddr.valid        := false.B

  io.maxi.readAddr.bits.addr     := 0.U
  io.maxi.writeAddr.bits.addr    := 0.U

  io.w_resp <> io.maxi.writeResp
  io.maxi.writeResp.ready        := true.B

  io.finished                    := cnt === action.length.U

  // always assign address from current action
  for (i <- 0 until action.length) {
    when (i.U === cnt) {
      io.maxi.readAddr.bits.addr  := action(i).address.U
      io.maxi.writeAddr.bits.addr := action(i).address.U
    }
  }

  when (state === s_addr) {
    for (i <- 0 until action.length) {
      when (i.U === cnt) {
        io.maxi.readAddr.valid  := action(i).isRead.B
        io.maxi.writeAddr.valid := (! action(i).isRead).B
        action(i).value map { v => w_data := v.U }
      }
    }
    when (io.maxi.readAddr.ready && io.maxi.readAddr.valid)   { state := s_rtransfer }
    when (io.maxi.writeAddr.ready && io.maxi.writeAddr.valid) { state := s_wtransfer }
    when (cnt === action.length.U)                            { state := s_idle      }
  }

  when (state === s_rtransfer) {
    for (i <- 0 until action.length) {
      val readReady  = action(i).isRead.B && io.maxi.readData.ready && io.maxi.readData.valid
      when (i.U === cnt && readReady) {
        q.io.enq.valid := io.maxi.readData.bits.resp === 0.U // response OKAY
        cnt := cnt + 1.U
        state := s_addr
      }
    }
  }

  when (state === s_wtransfer) {
    for (i <- 0 until action.length) {
      val writeReady = (!action(i).isRead).B && io.maxi.writeData.ready && io.maxi.writeData.valid
      when (i.U === cnt && writeReady) {
        cnt := cnt + 1.U
        state := s_response
      }
    }
  }

  when (state === s_response && io.maxi.writeResp.valid) { state := s_addr }
}

