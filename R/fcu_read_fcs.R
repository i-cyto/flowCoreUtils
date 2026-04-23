#' fcu_read_fcs
#'
#' This function speeds up the reading of the DATA segment of an FCS file when
#' the DATA are float. Otherwise, it reverts to flowCore read.FCS(). No
#' operation is applied after the data were read: no transform, no truncate,
#' etc.
#'
#' @param filename file path to the FCS file
#' @param which.lines see flowCore::read.FCS
#' @param transformation see flowCore::read.FCS
#' @param truncate_max_range see flowCore::read.FCS
#' @param method one of "default", "readBin", "RCpp"
#' @param ... arguments passed to flowCore
#'
#' @importClassesFrom flowCore flowFrame
#' @importMethodsFrom flowCore exprs exprs<-
#' @import methods
#'
#' @returns a flowFrame
#' @export
#'
fcu_read_fcs <- function(
    filename,
    which.lines = NULL,
    transformation = FALSE,
    truncate_max_range = FALSE,
    method = c("Rcpp", "default", "readBin"),
    ...
) {
  # get method: argument > option > hardcoded
  if (missing(method))
    method <- getOption("fcu_read_fcs.method", default = "Rcpp")
  method <- match.arg(method)
  # flowCore default method
  if (method == "default") {
    return(
      flowCoreUtils:::fc_read.FCS(
        filename = filename, which.lines = which.lines,
        transformation = FALSE, truncate_max_range = FALSE, ...)
    )
  }
  # Alternatives
  ff <- tryCatch({
    # ALTERNATIVES
    ff <- flowCoreUtils:::fc_read.FCS(
      filename = filename, which.lines = 1:9,
      transformation = FALSE, truncate_max_range = FALSE, ...)
    keywords <- keyword(ff)
    # Determine the DataType
    data.type <- keywords[["$DATATYPE"]]
    if (is.null(data.type))
      stop("$DATATYPE is required but not found in keywords.")
    if (data.type == "F") {
      data.size <- 4
    } else {
      stop("$DATATYPE '", data.type, "'is not implemented.")
    }
    # Determine Endianness
    byte.ord <- keywords[["$BYTEORD"]]
    if (is.null(byte.ord))
      stop("$BYTEORD is required but not found in keywords.")
    endian <- if (byte.ord == "1,2,3,4") "little" else "big"
    # Data offset & length
    data.start <- as.numeric(keywords[["$BEGINDATA"]])
    total.events <- as.numeric(keywords[["$TOT"]])
    n.par <- as.numeric(keywords[["$PAR"]])
    # Read Matrix
    if (method == "readBin") {
      con <- file(filename, open = "rb")
      seek(con, data.start)
      data.mat <- matrix(
        readBin(
          con, "numeric", n = total.events * n.par,
          size = 4, endian = endian),
        ncol = n.par, byrow = TRUE
      )
      close(con)
    } else {
      data.mat <- fcs_rcpp_read_data(
        file_path = filename, byte_offset = data.start,
        n_row = total.events, n_par = n.par,
        swap = endian != .Platform$endian)
    }
    # Column naming
    col.names <- unname(sapply(1:n.par, function(i) {
      val <- keywords[[paste0("$P", i, "N")]]
      if (is.null(val)) paste0("Channel_", i) else val
    }))
    colnames(data.mat) <- col.names
    exprs(ff) <- data.mat
    ff

  }, error = function(err) {
    # FALLBACK
    message("fcu_read_fcs error: ", err$message)
    flowCoreUtils:::fc_read.FCS(
      filename = filename, which.lines = which.lines,
      transformation = FALSE, truncate_max_range = FALSE, ...)

  # }, warning = function(w) {
  #   # Optional: Handle warnings specifically
  #   return(NULL)
  })
  return( ff )
}
