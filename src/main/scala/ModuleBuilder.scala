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
  val fad = Module (new FifoAxiAdapter(addrWidth = addrWidth,
      dataWidth = dataWidth, idWidth = 1, size = size))

  io.maxi.renameSignals()
  io.base.setName("base")

  fad.io.base := io.base
  fad.io.inq  <> datasrc.io.out
  fad.io.maxi <> io.maxi
}

object ModuleBuilder {
  val chiselArgs = Array("--backend", "v", "--compile")
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
        () => Module(new FifoAxiAdapter(addrWidth = 32,
                                        dataWidth = 64,
                                        idWidth = 1,
                                        size = scala.math.pow(2, 24).toInt)),
        CoreDefinition(
          name = "FifoAxiAdapter",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = Paths.get(".").toAbsolutePath.resolve("ip").resolve("FifoAxiAdapter").toString
        )
      ),
      ( // generic adapter module AXI -> FIFO
        () => Module(new AxiFifoAdapter(fifoDepth = 4,
                                        addrWidth = 32,
                                        dataWidth = 32,
                                        idWidth = 1)),
        CoreDefinition(
          name = "AxiFifoAdapter",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = Paths.get(".").toAbsolutePath.resolve("ip").resolve("AxiFifoAdapter").toString
        )
      )
    )

  def main(args: Array[String]) {
    modules foreach { m =>
      chiselMain(chiselArgs ++ Array("--targetDir", m._2.root), m._1)
      val json = "%s/%s.json".format(m._2.root, m._2.name)
      m._2.write(json)
      "packaging/package.py %s".format(json) !
    }
  }
}
