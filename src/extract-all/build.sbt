import sbtassembly.AssemblyPlugin.defaultUniversalScript

val scala3Version = "3.3.0"
lazy val root = project
  .in(file("."))
  .settings(
    name := "extract-all",
    version := "0.1.0-SNAPSHOT",
    scalaVersion := scala3Version,
    libraryDependencies ++= Seq(
      "net.lingala.zip4j" % "zip4j" % "2.11.5",
      "me.tongfei" % "progressbar" % "0.9.5",
      "com.github.scopt" %% "scopt" % "4.1.0"
    ),
    assemblyPrependShellScript := Some(
      defaultUniversalScript(
        shebang = true // We don't need windows compatibility
      )
    ),
    assembly / assemblyJarName := "extract-all.jar"
  )
