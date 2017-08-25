name := "chisel-axiutils"

organization := "esa.cs.tu-darmstadt.de"

version := "0.4-SNAPSHOT"

scalaVersion := "2.11.11"

resolvers ++= Seq(
  Resolver.sonatypeRepo("snapshots"),
  Resolver.sonatypeRepo("releases")
)

// Provide a managed dependency on X if -DXVersion="" is supplied on the command line.
val defaultVersions = Map("chisel3"          -> "3.0-SNAPSHOT",
                          "chisel-iotesters" -> "1.1-SNAPSHOT")

libraryDependencies ++= (Seq("chisel3","chisel-iotesters").map {
  dep: String => "edu.berkeley.cs" %% dep % sys.props.getOrElse(dep + "Version", defaultVersions(dep)) })

libraryDependencies ++= Seq(
  "com.novocode" % "junit-interface" % "0.11" % "test",
  "org.scalatest" %% "scalatest" % "2.2.6" % "test",
  "com.typesafe.play" %% "play-json" % "2.4.8"
)

scalacOptions ++= Seq("-language:implicitConversions", "-language:reflectiveCalls", "-deprecation", "-feature")

// project structure

lazy val packaging = project.in(file("packaging"))

lazy val miscutils = project.in(file("miscutils"))

lazy val root = (project in file(".")).dependsOn(packaging, miscutils)

