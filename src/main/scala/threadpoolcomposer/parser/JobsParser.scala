package de.tu_darmstadt.cs.esa.threadpoolcomposer.parser
import  de.tu_darmstadt.cs.esa.threadpoolcomposer.jobs._

private object JobsParser {
  import CommandLineParser._

  /** Returns a parser for a sequence of Job. */
  def apply(): Parser[Seq[Job]] = rep(job)

  private def job: Parser[Job] =
    HighLevelSynthesisJobParser()      |
    ImportJobParser()                  |
    BulkImportJobParser()              |
    CoreStatisticsJobParser()          |
    ComposeJobParser()                 |
    DesignSpaceExplorationJobParser()
}
