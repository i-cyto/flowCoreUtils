#' Simplify a FCS file
#'
#' The function \code{fcs_simplify} aims to keep FCS file as simple as possible.
#' The currently defined action removes flowCore_ keywords from the header of
#' the given FCS file. It works in place, i.e. writing the changed header in the
#' file on disk. Please make a copy of the original file before using.
#'
#' @name fcs_simplify
#'
#' @param filename a file name.
#' @param mode a list of actions; currently only "removeFlowCoreKeywords".
#' @param emptyValue see read.FCS documentation.
#'
#' @return None.
#'
#' @examples
#' library(flowCore)
#' fname <- system.file("extdata", "0877408774.B08", package = "flowCore")
#' fcs_simplify(fname)
#' @export
fcs_simplify <- function(
    filename,
    mode = list("removeFlowCoreKeywords"),
    emptyValue = TRUE
) {
  if (mode[[1]] == "removeFlowCoreKeywords") {
    # Open and read
    con <- file(filename, open="r+b")
    on.exit(close(con))
    # HEADER
    offsets <- flowCore:::findOffsets(con)
    begTxt <- offsets["textstart"]
    endTxt <- offsets["textend"]
    # Delimiter
    seek(con, begTxt)
    delim <- readChar(con, 1)
    # TEXT aka keywords
    txt <- flowCore:::readFCStext(con, offsets)
    kwd <- as.list(txt)
    # Remove flowCore parameters from keywords
    removed <- FALSE
    idx <- grep("transformation", names(kwd))
    if (length(idx)) {
      kwd[["transformation"]] <- NULL
      removed <- TRUE
    }
    idx <- grep("flowCore_$P\\d+Rmin", names(kwd), perl = TRUE)
    if (length(idx)) {
      kwd[[idx]] <- NULL
      removed <- TRUE
    }
    idx <- grep("flowCore_$P\\d+Rmax", names(kwd), perl = TRUE)
    if (length(idx)) {
      kwd[[idx]] <- NULL
      removed <- TRUE
    }
    # Update header, fill up and write
    if (removed) {
      ctxt <- flowCore:::collapseDesc(kwd, npar = 0, delimiter = "|")
      lenTxt <- endTxt - begTxt + 1
      padTxt <- lenTxt - nchar(ctxt, "bytes")
      if (padTxt > 0) ctxt <- paste0(ctxt, rep(" ", padTxt))
      seek(con, 0)
      offsets[1:2] <- c(begTxt, endTxt)
      flowCore:::writeFCSheader(con, offsets)
      writeChar(ctxt, con, eos=NULL)
      message("flowCore keywords removed.")
    } else {
      message("No change.")
    }
  }
}
