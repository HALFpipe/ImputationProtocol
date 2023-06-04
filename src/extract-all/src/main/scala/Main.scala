import scopt.OParser
import net.lingala.zip4j.ZipFile
import net.lingala.zip4j.progress.ProgressMonitor
import me.tongfei.progressbar.ProgressBarBuilder
import me.tongfei.progressbar.ProgressBarStyle

case class Config(
    inputFile: String = "",
    password: String = "",
    outputDirectory: String = "."
)

val parser = {
  val builder = OParser.builder[Config]
  import builder._
  OParser.sequence(
    programName("extract-all"),
    head("extract-all", "0.1"),
    opt[String]("input-file")
      .required()
      .text("the path to the zip file")
      .action((value, config) => config.copy(inputFile = value)),
    opt[String]("password")
      .required()
      .text("the password of the zip file")
      .action((value, config) => config.copy(password = value)),
    opt[String]("output-directory")
      .text("the directory to extract the zip file to")
      .action((value, config) => config.copy(outputDirectory = value)),
    help("help").text("prints this usage text")
  )
}

def main(args: Array[String]): Unit = {
  OParser.parse(parser, args, Config()) match {
    case Some(config) =>
      extract(config)
    case _ =>
      // Arguments are bad, error message was displayed
      sys.exit(1)
  }
}

def extract(config: Config): Unit = {
  println(
    s"Extracting \"${config.inputFile}\" to \"${config.outputDirectory}\""
  );

  val zipFile =
    new ZipFile(config.inputFile, config.password.toCharArray);
  zipFile.setRunInThread(true);
  zipFile.extractAll(config.outputDirectory);
  val progressMonitor = zipFile.getProgressMonitor();

  val bytesPerGigabyte = 1 << 30;
  val progressBarBuilder = new ProgressBarBuilder()
    .setStyle(ProgressBarStyle.ASCII)
    .setInitialMax(-1)
    .setUnit("GB", bytesPerGigabyte);
  val progressBar = progressBarBuilder.build();
  while (progressMonitor.getState() == ProgressMonitor.State.BUSY) {
    progressBar.stepTo(progressMonitor.getWorkCompleted());
    progressBar.maxHint(progressMonitor.getTotalWork());
    progressBar.setExtraMessage(progressMonitor.getCurrentTask().toString());
    Thread.sleep(100);
  }

  // Ensure the progress bar shows 100% when the extraction is complete
  progressBar.stepTo(progressBar.getMax());
  progressBar.refresh();

  sys.exit(0)
}
