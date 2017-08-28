package chisel.axiutils
import  chisel.axiutils.axi4lite._
import  chisel.packaging._, chisel.packaging.CoreDefinition.root
import  chisel.miscutils.DecoupledDataSource, chisel.miscutils.Logging
import  scala.sys.process._
import  java.nio.file.Paths
import  chisel3._
import  chisel.axi._

class FifoAxiAdapterTest1(dataWidth: Int, size: Int) extends Module {
  val addrWidth = 32
  implicit val logLevel = Logging.Level.Info
  implicit val axi = Axi4.Configuration(AddrWidth(addrWidth),
                                        DataWidth(dataWidth),
                                        IdWidth(1))
  val io = IO(new Bundle {
    val maxi = Axi4.Master(axi)
    val base = Input(UInt(AddrWidth(addrWidth)))
  })

  val datasrc = Module(new DecoupledDataSource(dataWidth.U, size = 256, n => n.U, false))
  val fad = Module(new FifoAxiAdapter(fifoDepth = size,
                                      burstSize = Some(16)))

  //io.maxi.renameSignals(None, None)
  io.base.suggestName("base")

  fad.io.base := io.base
  fad.io.enq  <> datasrc.io.out
  fad.io.maxi <> io.maxi
}

object AxiModuleBuilder extends ModuleBuilder {
  implicit val logLevel = Logging.Level.Info
  implicit val axi = Axi4.Configuration(AddrWidth(32),
                                        DataWidth(64),
                                        IdWidth(1))
  implicit val axilite = Axi4Lite.Configuration(AddrWidth(32),
                                                Axi4Lite.Width32)
  val exampleRegisterFile = new axi4lite.RegisterFile.Configuration(addrGranularity = 8, regs = Map(
    0  -> new ConstantRegister(value = BigInt("10101010", 16)),
    4  -> new ConstantRegister(value = BigInt("20202020", 16)),
    8  -> new ConstantRegister(value = BigInt("30303030", 16)),
    16 -> new ConstantRegister(value = BigInt("40404040", 16), bitfield = Map(
      "Byte #3" -> BitRange(31, 24),
      "Byte #2" -> BitRange(23, 16),
      "Byte #1" -> BitRange(15, 8),
      "Byte #0" -> BitRange(7, 0)
    ))
  ))(Axi4Lite.Configuration(AddrWidth(32), Axi4Lite.Width32))

  val modules: Seq[ModuleDef] = Seq(
      ModuleDef( // test module with fixed data
        None,
        () => new FifoAxiAdapterTest1(dataWidth = 32, 256),
        CoreDefinition(
          name = "FifoAxiAdapterTest1",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = Paths.get(".").toAbsolutePath.resolve("ip").resolve("FifoAxiAdapterTest1").toString
        )
      ),
      ModuleDef( // generic adapter module FIFO -> AXI
        None,
        () => new FifoAxiAdapter(fifoDepth = 8),
        CoreDefinition(
          name = "FifoAxiAdapter",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = Paths.get(".").toAbsolutePath.resolve("ip").resolve("FifoAxiAdapter").toString
        )
      ),
      ModuleDef( // generic adapter module AXI -> FIFO
        None,
        () => AxiFifoAdapter(fifoDepth = 4)
                            (Axi4.Configuration(addrWidth = AddrWidth(32),
                                                dataWidth = DataWidth(32),
                                                idWidth   = IdWidth(1))),
        CoreDefinition(
          name = "AxiFifoAdapter",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = Paths.get(".").toAbsolutePath.resolve("ip").resolve("AxiFifoAdapter").toString
        )
      ),
      ModuleDef( // AXI-based sliding window
        None,
        () => {
          implicit val axi = Axi4.Configuration(AddrWidth(32), DataWidth(64), IdWidth(1))
          new SlidingWindow(SlidingWindow.Configuration(
            gen = UInt(8.W),
            width = 8,
            depth = 3,
            afa = AxiFifoAdapterConfiguration(fifoDepth = 32, burstSize = Some(16))
          ))
        },
        CoreDefinition(
          name = "AxiSlidingWindow3x8",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = root("AxiSlidingWindow")
        )
      ),
      ModuleDef( // AXI Crossbar
        None,
        () => new AxiMux(8),
        CoreDefinition(
          name = "AxiMux",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = root("AxiMux")
        )
      ),
      ModuleDef( // AXI Register File
        Some(exampleRegisterFile),
        () => new RegisterFile(exampleRegisterFile),
        CoreDefinition.withActions(
          name = "RegisterFile",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "chisel",
          version = "0.1",
          root = root("RegisterFile"),
          postBuildActions = Seq(_ match {
            case Some(cfg: RegisterFile.Configuration) => cfg.dumpAddressMap(root("RegisterFile"))
            case _ => ()
          })
        )
      )
    )
}
