package de.tu_darmstadt.cs.esa.tapasco.tapasco_status
import  de.tu_darmstadt.cs.esa.tapasco.Implicits._
import  SlotConfig._
import  play.api.libs.json._
import  play.api.libs.functional.syntax._

package object json {
  implicit object SlotIdFormats extends Format[SlotId] {
    def reads(json: JsValue): JsResult[SlotId] = json match {
      case JsNumber(n) => JsSuccess(SlotId(n.toInt))
      case _           => JsError(Seq(JsPath() -> Seq(JsonValidationError("validation.error.expected.jsnumber"))))
    }
    def writes(sz: SlotId): JsValue = writes(sz.id)
  }

  implicit object KernelIdFormats extends Format[KernelId] {
    def reads(json: JsValue): JsResult[KernelId] = json match {
      case JsNumber(n) => JsSuccess(KernelId(n.toInt))
      case _           => JsError(Seq(JsPath() -> Seq(JsonValidationError("validation.error.expected.jsnumber"))))
    }
    def writes(sz: KernelId): JsValue = writes(sz.id)
  }

  implicit object SizeFormats extends Format[Size] {
    def reads(json: JsValue): JsResult[Size] = json match {
      case JsNumber(n) => JsSuccess(Size(n.toInt))
      case _           => JsError(Seq(JsPath() -> Seq(JsonValidationError("validation.error.expected.jsnumber"))))
    }
    def writes(sz: Size): JsValue = writes(sz.size)
  }

  implicit val kernelWrite: Writes[Kernel] = (
    (JsPath \ "Type").write[String] ~
    (JsPath \ "SlotId").write[SlotId] ~
    (JsPath \ "Kernel").write[KernelId]
  ) (unlift(Kernel.unapply _ andThen (_ map ("Kernel" +: _))))

  implicit val memoryWrite: Writes[Memory] = (
    (JsPath \ "Type").write[String] ~
    (JsPath \ "SlotId").write[SlotId] ~
    (JsPath \ "Memory").write[Size]
  ) (unlift(Memory.unapply _ andThen (_ map ("Memory" +: _))))
}
