package AXIDefs
{

import Chisel._
import Literal._
import Node._

// Part I: Definitions for the actual data carried over AXI channels
// in part II we will provide definitions for the actual AXI interfaces
// by wrapping the part I types in Decoupled (ready/valid) bundles

// AXI channel data definitions

class AXIAddress(addrWidthBits: Int, idBits: Int) extends Bundle {
  // address for the transaction, should be burst aligned if bursts are used
  val addr    = UInt(width = addrWidthBits)
  // size of data beat in bytes
  // set to UInt(log2Up((dataBits/8)-1)) for full-width bursts
  val size    = UInt(width = 3) 
  // number of data beats -1 in burst: max 255 for incrementing, 15 for wrapping
  val len     = UInt(width = 8)
  // burst mode: 0 for fixed, 1 for incrementing, 2 for wrapping
  val burst   = UInt(width = 2)
  // transaction ID for multiple outstanding requests
  val id      = UInt(width = idBits)
  // set to 1 for exclusive access
  val lock    = Bool()
  // cachability, set to 0010 or 0011
  val cache   = UInt(width = 4)
  // generally ignored, set to to all zeroes
  val prot    = UInt(width = 3)
  // not implemented, set to zeroes
  val qos     = UInt(width = 4)
  override def clone = { new AXIAddress(addrWidthBits, idBits).asInstanceOf[this.type] }
}

class AXIWriteData(dataWidthBits: Int) extends Bundle {
  val data    = UInt(width = dataWidthBits)
  val strb    = UInt(width = dataWidthBits/8)
  val last    = Bool()
  override def clone = { new AXIWriteData(dataWidthBits).asInstanceOf[this.type] }
}

class AXIWriteResponse(idBits: Int) extends Bundle {
  val id      = UInt(width = idBits)
  val resp    = UInt(width = 2)
  override def clone = { new AXIWriteResponse(idBits).asInstanceOf[this.type] }
}

class AXIReadData(dataWidthBits: Int, idBits: Int) extends Bundle {
  val data    = UInt(width = dataWidthBits)
  val id      = UInt(width = idBits)
  val last    = Bool()
  val resp    = UInt(width = 2)
  override def clone = { new AXIReadData(dataWidthBits, idBits).asInstanceOf[this.type] }
}



// Part II: Definitions for the actual AXI interfaces

// TODO add full slave interface definition

class AXIMasterIF(addrWidthBits: Int, dataWidthBits: Int, idBits: Int) extends Bundle {  
  // write address channel
  val writeAddr   = Decoupled(new AXIAddress(addrWidthBits, idBits))
  // write data channel
  val writeData   = Decoupled(new AXIWriteData(dataWidthBits))
  // write response channel (for memory consistency)
  val writeResp   = Decoupled(new AXIWriteResponse(idBits)).flip
  
  // read address channel
  val readAddr    = Decoupled(new AXIAddress(addrWidthBits, idBits))
  // read data channel
  val readData    = Decoupled(new AXIReadData(dataWidthBits, idBits)).flip
  
  // rename signals to be compatible with those in the Xilinx template
  def renameSignals(prefix: Option[String], suffix: Option[String]) = {
    // write address channel
    writeAddr.bits.addr.setName("%sM_AXI_AWADDR%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.bits.prot.setName("%sM_AXI_AWPROT%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.bits.size.setName("%sM_AXI_AWSIZE%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.bits.len.setName("%sM_AXI_AWLEN%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.bits.burst.setName("%sM_AXI_AWBURST%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.bits.lock.setName("%sM_AXI_AWLOCK%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.bits.cache.setName("%sM_AXI_AWCACHE%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.bits.qos.setName("%sM_AXI_AWQOS%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.bits.id.setName("%sM_AXI_AWID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.valid.setName("%sM_AXI_AWVALID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeAddr.ready.setName("%sM_AXI_AWREADY%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    // write data channel
    writeData.bits.data.setName("%sM_AXI_WDATA%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeData.bits.strb.setName("%sM_AXI_WSTRB%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeData.bits.last.setName("%sM_AXI_WLAST%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeData.valid.setName("%sM_AXI_WVALID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeData.ready.setName("%sM_AXI_WREADY%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    // write response channel
    writeResp.bits.resp.setName("%sM_AXI_BRESP%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeResp.bits.id.setName("%sM_AXI_BID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeResp.valid.setName("%sM_AXI_BVALID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    writeResp.ready.setName("%sM_AXI_BREADY%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    // read address channel
    readAddr.bits.addr.setName("%sM_AXI_ARADDR%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.bits.prot.setName("%sM_AXI_ARPROT%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.bits.size.setName("%sM_AXI_ARSIZE%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.bits.len.setName("%sM_AXI_ARLEN%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.bits.burst.setName("%sM_AXI_ARBURST%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.bits.lock.setName("%sM_AXI_ARLOCK%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.bits.cache.setName("%sM_AXI_ARCACHE%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.bits.qos.setName("%sM_AXI_ARQOS%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.bits.id.setName("%sM_AXI_ARID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.valid.setName("%sM_AXI_ARVALID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readAddr.ready.setName("%sM_AXI_ARREADY%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    // read data channel
    readData.bits.id.setName("%sM_AXI_RID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readData.bits.data.setName("%sM_AXI_RDATA%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readData.bits.resp.setName("%sM_AXI_RRESP%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readData.bits.last.setName("%sM_AXI_RLAST%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readData.valid.setName("%sM_AXI_RVALID%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
    readData.ready.setName("%sM_AXI_RREADY%s".format(prefix.getOrElse(""), suffix.getOrElse("")))
  }
  
  override def clone = { new AXIMasterIF(addrWidthBits, dataWidthBits, idBits).asInstanceOf[this.type] }
}

}
