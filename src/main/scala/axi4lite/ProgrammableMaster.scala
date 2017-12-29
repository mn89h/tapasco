package chisel.axi.axi4lite
import  chisel3._
import  chisel3.util._
import  chisel.axi._
import  chisel.miscutils.Logging

/** AXI4Lite master transaction model. */
sealed abstract trait MasterAction {
  def isRead: Boolean
  def address: Long
  def value: Option[BigInt]
}

final case class MasterRead(address: Long) extends MasterAction {
  def isRead: Boolean = true
  def value: Option[BigInt] = None
}

final case class MasterWrite(address: Long, v: BigInt) extends MasterAction {
  def isRead: Boolean = false
  def value: Option[BigInt] = Some(v)
}

/** Axi4LiteProgrammableMaster is a testing tool to perform a sequence of master actions.
 *  It automatically performs simple AXI4Lite transactions on slave.
 *  @param action Sequence of transactions, executed sequentially without delay.
 *  @param axi implicit AXI configuration.
 **/
 class ProgrammableMaster(action: Seq[MasterAction], startable: Boolean = false)
                         (implicit axi: Axi4Lite.Configuration, logLevel: Logging.Level) extends Module with Logging {
  cinfo(s"AXI configuration = $axi")
  val io = IO(new Bundle {
    val maxi     = Axi4Lite.Master(axi)
    val out      = Decoupled(UInt(axi.dataWidth))
    val w_resp   = Decoupled(new chisel.axi.Axi4Lite.WriteResponse)
    val finished = Output(Bool())
    val start    = Input(UInt(if (startable) 1.W else 0.W))
    val restart  = Input(Bool())
  })

  val cnt = RegInit(UInt(log2Ceil(action.length + 1).W), init = 0.U)
  io.finished := RegNext(cnt === action.length.U)

  val ra_valid = RegInit(false.B)
  val rd_ready = RegInit(false.B)
  val wa_valid = RegInit(false.B)
  val wd_valid = RegInit(false.B)
  val wr_ready = RegInit(false.B)
  val signals  = Vec(ra_valid, rd_ready, wa_valid, wd_valid, wr_ready)

  val ra = RegInit(io.maxi.readAddr.bits.addr.cloneType, init = 0.U)
  val wa = RegInit(io.maxi.writeAddr.bits.addr.cloneType, init = 0.U)
  val wd = RegInit(io.maxi.writeData.bits.data.cloneType, init = 0.U)

  io.maxi.readAddr.bits.defaults
  io.maxi.writeAddr.bits.defaults
  io.maxi.writeData.bits.defaults

  io.out.valid := io.maxi.readData.valid
  io.out.bits  := io.maxi.readData.bits.data

  io.w_resp.valid := io.maxi.writeResp.valid
  io.w_resp.bits  <> io.maxi.writeResp.bits

  io.maxi.readAddr.valid  := ra_valid
  io.maxi.writeAddr.valid := wa_valid
  io.maxi.writeData.valid := wd_valid
  io.maxi.readData.ready  := rd_ready
  io.maxi.writeResp.ready := wr_ready

  io.maxi.readAddr.bits.addr  := ra
  io.maxi.writeAddr.bits.addr := wa
  io.maxi.writeData.bits.data := wd

  when (io.maxi.readAddr.fire)  { ra_valid := false.B }
  when (io.maxi.readData.fire)  { rd_ready := false.B }
  when (io.maxi.writeAddr.fire) { wa_valid := false.B }
  when (io.maxi.writeData.fire) { wd_valid := false.B }
  when (io.maxi.writeResp.fire) { wr_ready := false.B }

  when (RegNext(io.restart)) {
    info("restarting action sequence ...")
    cnt := 0.U
  }
  .otherwise {
    when ((if (startable) RegNext(io.start(0), init = false.B) else true.B)) {
      when (!signals.reduce(_ || _)) {
        for (i <- 0 until action.length) {
          when (i.U === cnt) {
            //info(s"Starting action #$i: ${action(i)}")
            ra := action(i).address.U
            wa := action(i).address.U
            wd := action(i).value.getOrElse(BigInt(0)).U
            ra_valid := action(i).isRead.B
            rd_ready := action(i).isRead.B
            wa_valid := (!action(i).isRead).B
            wd_valid := (!action(i).isRead).B
            wr_ready := (!action(i).isRead).B
            cnt := cnt + 1.U
          }
        }
      }
    }
  }
}
