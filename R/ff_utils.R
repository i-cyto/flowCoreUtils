#' Clean keywords in a flowFrame
#'
#' By default, it removes flowCore_ keywords as well as "transformation".
#'
#' @param ff a flowFrame
#' @param remove a vector of patterns to search and remove
#' @param keep unused yet
#'
#' @return the cleaned flowFrame
#' @export
#' @importFrom flowCore keyword
#'
#' @examples
#' library(flowCore)
#' fcsFile <- system.file("extdata", "0877408774.B08", package = "flowCore")
#' ## read file and linearize values
#' samp <- read.FCS(fcsFile, transformation = "linearize")
#' names(keyword(samp))
#' ## Remove flowCore keywords
#' samp <- ff_clean_keyword(samp)
#' names(keyword(samp))
ff_clean_keyword <- function(
    ff,
    remove = c("^flowCore_", "transformation", "note"),
    keep = NULL
) {
  kw <- flowCore::keyword(ff)
  kw_remove <- lapply(remove, function(patt)
    grep(patt, names(kw), value = TRUE))
  kw_remove <- Reduce(c, kw_remove)
  kw <- kw[setdiff(names(kw), kw_remove)]
  flowCore::keyword(ff) <- kw
  ff
}

