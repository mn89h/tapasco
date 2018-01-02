package de.tu_darmstadt.cs.esa.tapasco.tapasco_status
import  org.scalatest._, org.scalatest.prop.Checkers
import  org.scalacheck._
import  org.scalacheck.Prop._
import  scala.util.Try
import  play.api.libs.json._
import  json._
import  generators._

class JsonSpec extends FlatSpec with Checkers {
  "Versions" should "remain identical when converted from data to JSON and back" in
    check(forAll(genVersions) { versions: Versions =>
      Try(Json.fromJson[Versions](Json.toJson(versions)).get) map (_ equals versions) getOrElse false
    }, minSuccessful(10000))

  "Clocks" should "remain identical when converted from data to JSON and back" in
    check(forAll(genClocks) { clocks: Clocks =>
      Try(Json.fromJson[Clocks](Json.toJson(clocks)).get) map (_ equals clocks) getOrElse false
    }, minSuccessful(10000))

  "Configurations" should "remain identical when converted from data to JSON and back" in
    check(forAll(genConfig) { config: Seq[Slot] =>
      Try(Json.fromJson[Seq[Slot]](Json.toJson(config)).get) map (_ equals config) getOrElse false
    }, minSuccessful(1000))

  "Status" should "remain identical when converted from data to JSON and back" in
    check(forAllNoShrink(genStatus) { status: Status =>
      Try(Json.fromJson[Status](Json.toJson(status)).get) map (_ equals status) getOrElse false
    }, minSuccessful(1000))
}
