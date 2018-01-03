package de.tu_darmstadt.cs.esa.tapasco.tapasco_status
import  de.tu_darmstadt.cs.esa.tapasco.Implicits._
import  Slot._
import  play.api.libs.json._
import  play.api.libs.json.Reads._
import  play.api.libs.functional.syntax._

package object json {
  /** @{ Id formats */
  implicit object SlotIdFormats extends Format[SlotId] {
    def reads(json: JsValue): JsResult[SlotId] = json match {
      case JsNumber(n) => JsSuccess(SlotId(n.toInt))
      case _           => JsError(Seq(JsPath() -> Seq(JsonValidationError("validation.error.expected.jsnumber"))))
    }
    def writes(id: SlotId): JsValue = Json.toJson(id: Int)
  }

  implicit object KernelIdFormats extends Format[KernelId] {
    def reads(json: JsValue): JsResult[KernelId] = json match {
      case JsNumber(n) => JsSuccess(KernelId(n.toInt))
      case _           => JsError(Seq(JsPath() -> Seq(JsonValidationError("validation.error.expected.jsnumber"))))
    }
    def writes(id: KernelId): JsValue = Json.toJson(id: Int)
  }

  implicit object SizeFormats extends Format[Size] {
    def reads(json: JsValue): JsResult[Size] = json match {
      case JsNumber(n) => JsSuccess(Size(n.toInt))
      case _           => JsError(Seq(JsPath() -> Seq(JsonValidationError("validation.error.expected.jsnumber"))))
    }
    def writes(sz: Size): JsValue = Json.toJson(sz: Int)
  }
  /** Id formats @} */

  /** @{ Slot.Kernel */
  implicit val kernelWrites: Writes[Kernel] = (
    (JsPath \ "Type").write[String] ~
    (JsPath \ "SlotId").write[SlotId] ~
    (JsPath \ "Kernel").write[KernelId]
  ) (unlift(Kernel.unapply _ andThen (_ map ("Kernel" +: _))))

  val kernelReads: Reads[Slot] = (
    (JsPath \ "Type").read[String] (verifying[String](_.toLowerCase equals "kernel")) ~>
    (JsPath \ "SlotId").read[SlotId] ~
    (JsPath \ "Kernel").read[KernelId]
  ) (Kernel.apply _)
  /** Slot.Kernel @} */

  /** @{ Slot.Memory */
  implicit val memoryWrites: Writes[Memory] = (
    (JsPath \ "Type").write[String] ~
    (JsPath \ "SlotId").write[SlotId] ~
    (JsPath \ "Bytes").write[Size]
  ) (unlift(Memory.unapply _ andThen (_ map ("Memory" +: _))))

  val memoryReads: Reads[Slot] = (
    (JsPath \ "Type").read[String] (verifying[String](_.toLowerCase equals "memory")) ~>
    (JsPath \ "SlotId").read[SlotId] ~
    (JsPath \ "Bytes").read[Size]
  ) (Memory.apply _)
  /** Slot.Memory @} */

  /** @{ Slot */
  implicit val slotReads: Reads[Slot] = kernelReads | memoryReads

  implicit object SlotWrites extends Writes[Slot] {
    def writes(c: Slot): JsValue = c match {
      case k: Kernel => kernelWrites.writes(k)
      case m: Memory => memoryWrites.writes(m)
    }
  }
  /** Slot @} */

  /** @{ Versions */
  implicit val versionWrites: Writes[Versions.Version] = (
    (JsPath \ "Software").write[String] ~
    (JsPath \ "Year").write[Int] ~
    (JsPath \ "Release").write[Int]
  ) (_.unapply)

  val tapascoVersionReads: Reads[Versions.Version] = (
    (JsPath \ "Software").read[String] (verifying[String](_.toLowerCase contains "tapasco")) ~>
    (JsPath \ "Year").read[Int] ~
    (JsPath \ "Release").read[Int]
  ) (Versions.Tapasco.apply _)

  val vivadoVersionReads: Reads[Versions.Version] = (
    (JsPath \ "Software").read[String] (verifying[String](_.toLowerCase contains "vivado")) ~>
    (JsPath \ "Year").read[Int] ~
    (JsPath \ "Release").read[Int]
  ) (Versions.Vivado.apply _)

  implicit val versionReads: Reads[Versions.Version] = tapascoVersionReads | vivadoVersionReads

  implicit object VersionsFormat extends Format[Versions] {
    private def tapascoVersion(vs: Seq[Versions.Version]): Versions.Tapasco = vs match {
      case t +: tt => t match {
        case v: Versions.Tapasco => v
        case _ => tapascoVersion(tt)
      }
      case _ => throw new IllegalArgumentException("TaPaSCo version not found in JSON")
    }

    private def vivadoVersion(vs: Seq[Versions.Version]): Versions.Vivado = vs match {
      case t +: tt => t match {
        case v: Versions.Vivado => v
        case _ => vivadoVersion(tt)
      }
      case _ => throw new IllegalArgumentException("Vivado version not found in JSON")
    }

    def reads(json: JsValue): JsResult[Versions] = json match {
      case vs: JsArray => Json.fromJson[Seq[Versions.Version]](vs) map (vs => Versions(tapascoVersion(vs), vivadoVersion(vs)))
      case _           => JsError(Seq(JsPath() -> Seq(JsonValidationError("validation.error.expected.jsarray"))))
    }
    def writes(v: Versions): JsValue = Json.toJson(Seq(v.vivado, v.tapasco))
  }
  /** Versions @} */

  /** @{ Clocks */
  implicit val freqWrites: Writes[Clocks.Frequency] = (
    (JsPath \ "Domain").write[String] ~
    (JsPath \ "Frequency").write[Double]
  ) (_.unapply)

  val hostFreqReads: Reads[Clocks.Frequency] = (
    (JsPath \ "Domain").read[String] (verifying[String](_.toLowerCase equals "host")) ~>
    (JsPath \ "Frequency").read[Double]
  ) fmap (Clocks.HostFreq.apply _)

  val designFreqReads: Reads[Clocks.Frequency] = (
    (JsPath \ "Domain").read[String] (verifying[String](_.toLowerCase equals "design")) ~>
    (JsPath \ "Frequency").read[Double]
  ) fmap (Clocks.DesignFreq.apply _)

  val memFreqReads: Reads[Clocks.Frequency] = (
    (JsPath \ "Domain").read[String] (verifying[String](_.toLowerCase equals "memory")) ~>
    (JsPath \ "Frequency").read[Double]
  ) fmap (Clocks.MemFreq.apply _)

  implicit val freqReads: Reads[Clocks.Frequency] = hostFreqReads | designFreqReads | memFreqReads

  implicit object ClocksFormat extends Format[Clocks] {
    def reads(json: JsValue): JsResult[Clocks] = json match {
      case cs: JsArray => Json.fromJson[Seq[Clocks.Frequency]](cs) map ((clocks: Seq[Clocks.Frequency]) => for {
        hf <- (clocks collectFirst { case h: Clocks.HostFreq => h })
        df <- (clocks collectFirst { case d: Clocks.DesignFreq => d })
        mf <- (clocks collectFirst { case m: Clocks.MemFreq => m })
      } yield Clocks(hf, df, mf)) map (_.get)
      case _           => JsError(Seq(JsPath() -> Seq(JsonValidationError("validation.error.expected.jsarray"))))
    }
    def writes(c: Clocks): JsValue = Json.toJson(Seq(c.host, c.design, c.memory))
  }
  /** Clocks @} */

  /** @{ Status */
  implicit val statusFormat: Format[Status] = (
    (JsPath \ "Composition").format[Seq[Slot]] ~
    (JsPath \ "Timestamp").format[Int] ~
    (JsPath \ "Interrupt Controllers").format[Int] ~
    (JsPath \ "Versions").format[Versions] ~
    (JsPath \ "Clocks").format[Clocks]
  ) (Status.apply _, unlift(Status.unapply _))
  /** Status @} */
}
// vim: foldmethod=marker foldmarker=@{,@} foldlevel=0
