#' Display the hexadecimal canonical view of a file part
#'
#' Display the hexadecimal canonical view of a file part. The view consists in
#' three parts. On each line, the first is the position, next the hexadecimal
#' view, finally the character/ASCII view.
#'
#' @param filename FCS file path as a string.
#' @param start  byte position; 0 means the first byte. If -1, target TEXT of
#'   FCS.
#' @param nbytes  number of bytes to display.
#' @param replaceChar  character that are not ASCII and could not be displayed
#'   are replaced by the is character.
#'
#' @return none.
#'
#' @export
#' @examples
#' library(flowCore)
#' fname <- system.file("extdata", "0877408774.B08", package = "flowCore")
#' fcs_hex_dump(fname)
#' \dontrun{
#' writeChar(fcs_hex_dump(fname, nbytes = 4800), con = "hexdump.txt")
#' }
#'
fcs_hex_dump <- function(
    filename,
    start = 0,
    nbytes = 4096,
    replaceChar = " "
) {
  # Open and read
  con <- file(filename, open="rb")
  # on.exit(close(con))
  # FCS
  if (start == -1) {
    offsets <- flowCore:::findOffsets(con)
    nbytes <- offsets["textend"]
    start <- 0
  }
  # Read bytes
  seek(con, start)
  bytes <- readBin(con, "raw", nbytes)
  close(con)
  # Dump hexadecimal
  bytesText <- bytes
  bytesText[bytesText < 32 | bytesText > 126] <- charToRaw(replaceChar)
  text <- rawToChar(bytesText)
  # text <- gsub("\\\\", "_", text)
  text = strsplit(gsub("(.{16})", "\\1\001", text),
                  "\001", fixed = TRUE)[[1]]
  res = rep(NULL, length(text))
  for (i in (1:length(text))-1) {
    res[i+1] <- sprintf("% 9d | %s | %s |", start+i*16,
                        paste(bytes[1:16+i*16], collapse = " "), text[i+1])
  }
  cat(paste0(res, "\n", collapse = ""))
}
