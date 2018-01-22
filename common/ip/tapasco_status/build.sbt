name := "tapasco-status"

organization := "esa.cs.tu-darmstadt.de"

version := "1.0"

scalaVersion := "2.11.12"

resolvers ++= Seq(
  Resolver.sonatypeRepo("snapshots"),
  Resolver.sonatypeRepo("releases")
)

// Provide a managed dependency on X if -DXVersion="" is supplied on the command line.
val defaultVersions = Map("chisel3"          -> "3.1-SNAPSHOT",
                          "chisel-iotesters" -> "1.2-SNAPSHOT")

libraryDependencies ++= (Seq("chisel3","chisel-iotesters").map {
  dep: String => "edu.berkeley.cs" %% dep % sys.props.getOrElse(dep + "Version", defaultVersions(dep)) })

libraryDependencies ++= Seq(
  "org.scalatest" %% "scalatest" % "3.0.4" % "test",
  "org.scalacheck" %% "scalacheck" % "1.13.5" % "test",
  "com.typesafe.play" %% "play-json" % "2.6.8",
  "org.scalactic" %% "scalactic" % "3.0.4"
)

lazy val axiutils = project.in(file("axi"))

lazy val packaging = project.in(file("packaging"))

lazy val tapascostatus = (project in file(".")).dependsOn(packaging, axiutils, axiutils % "test->test").aggregate(packaging)

cleanFiles ++= Seq((baseDirectory.value / "test"), (baseDirectory.value / "ip"), (baseDirectory.value / "chisel3"))

aggregate in test := false

assemblyJarName in assembly := s"tapasco-status-${version.value}.jar"

test in assembly := false
