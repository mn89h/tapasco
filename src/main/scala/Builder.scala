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

  private final val emptySlot = new ConstantRegister(Some("Empty Slot"), value = BigInt(0))

  private def makeRegister(s: Slot): Seq[(Long, ControlRegister)] = s match {
    case k: Slot.Kernel => Seq(
      256L + s.slot * 16L -> new ConstantRegister(Some(s"Slot ${s.slot} Kernel ID"), value = BigInt(k.kernel)),
      260L + s.slot * 16L -> new ConstantRegister(Some(s"Slot ${s.slot} Local Mem"), value = BigInt(0))
    )
    case m: Slot.Memory => Seq(
      256L + s.slot * 16L -> new ConstantRegister(Some(s"Slot ${s.slot} Kernel ID"), value = BigInt(0)),
      260L + s.slot * 16L -> new ConstantRegister(Some(s"Slot ${s.slot} Local Mem"), value = BigInt(m.size))
    )
    case k: Slot.Empty  => Seq(
      256L + s.slot * 16L -> emptySlot,
      260L + s.slot * 16L -> emptySlot
    )
  }

  private def fillEmptySlots(ss: Seq[Slot]): Seq[Slot] = {
    val slotIds: Set[Int] = (ss map (_.slot: Int)).toSet
    ss ++ (for (x <- 0 until NUM_SLOTS if !(slotIds.contains(x))) yield Slot.Empty(x))
  }

  def makeConfiguration(status: Status): RegisterFile.Configuration = RegisterFile.Configuration(
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
    ) ++ ((fillEmptySlots(status.config) map (makeRegister _) fold Seq()) (_ ++ _))).toMap
  )

  private def makeBuilder(base: Path, status: Status): chisel.packaging.ModuleBuilder = new chisel.packaging.ModuleBuilder {
    val configuration = makeConfiguration(status)
    val modules: Seq[ModuleDef] = Seq(
      ModuleDef(
        Some(configuration),
        () => new RegisterFile(configuration) { override def desiredName = "tapasco_status" },
        CoreDefinition.withActions(
          name = "tapasco_status",
          vendor = "esa.cs.tu-darmstadt.de",
          library = "tapasco",
          version = "1.2",
          root = makePath(base, status).toString,
          interfaces = Seq(Interface(name = "s_axi", kind = "axi4slave")),
          postBuildActions = Seq(_ match {
            case Some(cfg: RegisterFile.Configuration) => cfg.dumpAddressMap(makePath(base, status).toString)
            case _ => ()
          })
        )
      )
    )
  }

  private def makePath(base: Path, status: Status): Path = base.resolve("%08x".format(status.hashCode))

  def main(args: Array[String]) {
    require (args.length == 2, "expected exactly two arguments: the base path for IP cores and the name of the json configuration file")
    try {
      val base = Paths.get(args(0)).toAbsolutePath.normalize
      val json = Json.parse(Source.fromFile(args(1)).getLines mkString " ")
      val status: Status = Json.fromJson[Status](json).get
      val hash = "%08x".format(status.hashCode)
      val path = makePath(base, status)
      println("Read configuration:")
      println(Json.prettyPrint(json))
      println("Status:")
      println(status)
      if (path.toFile.exists) {
        println(s"IP for configuration 0x$hash already exists, no need to build")
      } else {
        makeBuilder(base, status).main(Array(base.toString, "tapasco_status"))
      }
      println(s"Finished, IP Core is located in $path")
    } catch {
      case e: Exception => println(e); throw e
    }
  }
}
