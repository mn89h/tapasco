package chisel.axiutils
import chisel.axiutils.registers._
import chisel.packaging.{CoreDefinition, ModuleBuilder}
import chisel.packaging.CoreDefinition.root
import chisel.miscutils.DecoupledDataSource
import scala.sys.process._
import java.nio.file.Paths
import Chisel._
import AXIDefs._

class FifoAxiAdapterTest1(dataWidth : Int, size: Int) extends Module {
  val addrWidth = 32
  val io = new Bundle {
    val maxi = new AXIMasterIF(addrWidth, dataWidth, 1)
    val base = UInt(INPUT, width = addrWidth)
  }

  val datasrc = Module (new DecoupledDataSource(UInt(width = dataWidth),
      size = 256, n => UInt(n), false))
  val fad = Module (new FifoAxiAdapter(fifoDepth = size,
                                       addrWidth = addrWidth,
                                       dataWidth = dataWidth,
                                       burstSize = Some(16)))

  io.maxi.renameSignals(None, None)
  io.base.setName("base")

  fad.io.base := io.base
  fad.io.enq  <> datasrc.io.out
  fad.io.maxi <> io.maxi
}

object AxiModuleBuilder extends ModuleBuilder {
  implicit val axi = AxiConfiguration(addrWidth = 32, dataWidth = 64, idWidth = 1)

  val modules: List[(() => Module, CoreDefinition)] = List(
      ( // test module with fixed data
        () => Module(new FifoAxiAdapterTest1(dataWidth = 32, 256)),
        CoreDefinition(
          name = "FifoAxiAdapterTest1",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = Paths.get(".").toAbsolutePath.resolve("ip").resolve("FifoAxiAdapterTest1").toString
        )
      ),
      ( // generic adapter module FIFO -> AXI
        () => Module(new FifoAxiAdapter(fifoDepth = 8,
                                        addrWidth = 32,
                                        dataWidth = 64)),
        CoreDefinition(
          name = "FifoAxiAdapter",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = Paths.get(".").toAbsolutePath.resolve("ip").resolve("FifoAxiAdapter").toString
        )
      ),
      ( // generic adapter module AXI -> FIFO
        () => Module(AxiFifoAdapter(fifoDepth = 4,
                                    addrWidth = 32,
                                    dataWidth = 32)),
        CoreDefinition(
          name = "AxiFifoAdapter",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = Paths.get(".").toAbsolutePath.resolve("ip").resolve("AxiFifoAdapter").toString
        )
      ),
      ( // AXI-based sliding window
        () => Module(new AxiSlidingWindow(AxiSlidingWindowConfiguration(
            gen = UInt(width = 8),
            width = 8,
            depth = 3,
            afa = AxiFifoAdapterConfiguration(
                axi = AxiConfiguration(addrWidth = 32, dataWidth = 64, idWidth = 1),
                fifoDepth = 32,
                burstSize = Some(16)
              )
          ))),
        CoreDefinition(
          name = "AxiSlidingWindow3x8",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = root("AxiSlidingWindow")
        )
      ),
      ( // AXI Crossbar
        () => Module(new AxiMux(8)),
        CoreDefinition(
          name = "AxiMux",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = root("AxiMux")
        )
      ),
      ( // AXI Register File
        () => Module(
          new Axi4LiteRegisterFile(new Axi4LiteRegisterFileConfiguration(
            width = 32,
            regs = Map(0  -> new ConstantRegister(value = BigInt("10101010", 16)),
                       4  -> new ConstantRegister(value = BigInt("20202020", 16)),
                       8  -> new ConstantRegister(value = BigInt("30303030", 16)),
                       16 -> new ConstantRegister(value = BigInt("40404040", 16), bitfield = Map(
                         "Byte #3" -> BitRange(31, 24),
                         "Byte #2" -> BitRange(23, 16),
                         "Byte #1" -> BitRange(15, 8),
                         "Byte #0" -> BitRange(7, 0)
                       )))
          ))
        ),
        CoreDefinition.withActions(
          name = "Axi4LiteRegisterFile",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = root("Axi4LiteRegisterFile"),
          postBuildActions = Seq(_ match {
            case m: Axi4LiteRegisterFile => m.dumpAddressMap(root("Axi4LiteRegisterFile"))
          })
        )
      )
    )
}
