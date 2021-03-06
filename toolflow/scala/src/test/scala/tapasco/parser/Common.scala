//
// Copyright (C) 2017 Jens Korinth, TU Darmstadt
//
// This file is part of Tapasco (TPC).
//
// Tapasco is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Tapasco is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with Tapasco.  If not, see <http://www.gnu.org/licenses/>.
//
package tapasco.parser

import fastparse.all._

private object Common {
  private final val logger = tapasco.Logging.logger(getClass)

  def checkParsed(p: => Parsed[_]): Boolean = try {
    p match {
      case _: Parsed.Success[_] => true
      case r: Parsed.Failure =>
        logger.error("parser exception: " + CommandLineParser.ParserException(r))
        false
    }
  } catch {
    case t: Throwable =>
      logger.warn("got throwable: {} - check if this is ok", t)
      true
  }
}
