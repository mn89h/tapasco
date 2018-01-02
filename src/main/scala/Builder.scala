package de.tu_darmstadt.cs.esa.tapasco.tapasco_status
import  chisel.packaging.ModuleDef
import  json._
import  scala.io._
import  play.api.libs.json._
import  chisel.axi._, chisel.axi.axi4lite._
import  chisel.miscutils.Logging._
import  chisel.packaging._, chisel.packaging.CoreDefinition.root
import  chisel3._
import  java.nio.file.{Path, Paths}

object Builder {
  implicit val logLevel: Level = Level.Info
  implicit val axi: Axi4Lite.Configuration = Axi4Lite.Configuration(dataWidth = Axi4Lite.Width32,
                                                                    addrWidth = AddrWidth(12))

  private def makeRegister(s: Slot): Seq[(Long, ControlRegister)] = s match {
    case k: Slot.Kernel => Seq(
      256L + s.slot * 16L -> new ConstantRegister(Some("Slot ${s.slot} Kernel ID"), value = BigInt(k.kernel)),
      260L + s.slot * 16L -> new ConstantRegister(Some("Slot ${s.slot} Local Mem"), value = BigInt(0))
    )
    case m: Slot.Memory => Seq(
      256L + s.slot * 16L -> new ConstantRegister(Some("Slot ${s.slot} Kernel ID"), value = BigInt(0)),
      260L + s.slot * 16L -> new ConstantRegister(Some("Slot ${s.slot} Local Mem"), value = BigInt(m.size))
    )
  }

  private def makeConfiguration(status: Status): RegisterFile.Configuration = RegisterFile.Configuration(
    regs = (Seq[(Long, ControlRegister)](
      0x00L -> new ConstantRegister(Some("Magic ID"), value = BigInt("E5AE1337", 16)),
      0x04L -> new ConstantRegister(Some("Int Count"), value = BigInt(status.interruptControllers)),
      0x08L -> new ConstantRegister(Some("Capabilities_0"), value = BigInt(0)), // FIXME CAPABILITIES_0
      0x10L -> new ConstantRegister(Some("Vivado Version"), value = BigInt(status.versions.vivado.toHex, 16)),
      0x14L -> new ConstantRegister(Some("Vivado Version"), value = BigInt(status.versions.tapasco.toHex, 16)),
      0x18L -> new ConstantRegister(Some("Bitstream Timestamp"), value = BigInt(status.timestamp)),
      0x1CL -> new ConstantRegister(Some("Host Clock (Hz)"), value = BigInt(status.clocks.host.frequency.toLong)),
      0x20L -> new ConstantRegister(Some("Design Clock (Hz)"), value = BigInt(status.clocks.design.frequency.toLong)),
      0x24L -> new ConstantRegister(Some("Memory Clock (Hz)"), value = BigInt(status.clocks.memory.frequency.toLong))
    ) ++ ((status.config map (makeRegister _) fold Seq()) (_ ++ _))).toMap
  )

  private def makeBuilder(status: Status): chisel.packaging.ModuleBuilder = new chisel.packaging.ModuleBuilder {
    val configuration = makeConfiguration(status)
    val modules: Seq[ModuleDef] = Seq(
      ModuleDef(
        None,
        () => new RegisterFile(configuration),
        CoreDefinition(
          name = "tapasco_status",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "tapasco",
          version = "1.2",
          root = makePath(status).toString,
          interfaces = Seq(Interface(name = "saxi", kind = "axi4slave"))
        )
      )
    )
  }

  private def makePath(status: Status): Path =
    Paths.get(".").toAbsolutePath.resolve("ip").resolve("%08x".format(status.hashCode)).normalize

  def main(args: Array[String]) {
    require (args.length == 1, "expected exactly one argument: the name of the json configuration file")
    try {
      val json = Json.parse(Source.fromFile(args(0)).getLines mkString " ")
      val status: Status = Json.fromJson[Status](json).get
      val hash = "%08x".format(status.hashCode)
      val path = makePath(status)
      println("Read configuration:")
      println(Json.prettyPrint(json))
      println("Status:")
      println(status)
      if (makePath(status).toFile.exists) {
        println(s"IP for configuration 0x$hash already exists, no need to build")
      } else {
        makeBuilder(status).main(Array("tapasco_status"))
      }
      println(s"Finished, IP Core is located in $path")
    } catch {
      case e: Exception => println(e); throw e
    }
  }
}
