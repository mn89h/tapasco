package chisel.axiutils
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

  io.maxi.renameSignals()
  io.base.setName("base")

  fad.io.base := io.base
  fad.io.enq  <> datasrc.io.out
  fad.io.maxi <> io.maxi
}

object AxiModuleBuilder extends ModuleBuilder {
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
      )
    )
}
