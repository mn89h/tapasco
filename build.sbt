name := "chisel-axiutils"

organization := "esa.cs.tu-darmstadt.de"

version := "0.3-SNAPSHOT"

crossScalaVersions := Seq("2.10.3", "2.10.4", "2.11.0")

scalaVersion := "2.11.7"

libraryDependencies ++= Seq(
  "edu.berkeley.cs" %% "chisel" % "latest.release",
  "com.novocode" % "junit-interface" % "0.11" % "test",
  "org.scalatest" %% "scalatest" % "2.2.6" %"test",
   "com.typesafe.play" %% "play-json" % "2.4.8"
)


// no parallel testing

parallelExecution in Test := false

testForkedParallel in Test := false


// project structure

lazy val packaging = project.in(file("packaging"))

lazy val miscutils = project.in(file("miscutils"))

lazy val root = (project in file(".")).dependsOn(packaging, miscutils)

