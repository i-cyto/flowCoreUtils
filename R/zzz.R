# Internal variable to hold the original function
fc_read.FCS <- NULL

#' Enable the optimized flowCore overload
#' @param quiet Logical. If TRUE, suppresses the startup message.
#' @export
enable_fast_read.FCS <- function(quiet = FALSE) {
  # 0. flowCore should be already loaded
  if (!"flowCore" %in% loadedNamespaces())
    return(invisible(NULL))
    # stop("flowCore must be loaded to enable overload.")
  # Check if already overloaded to prevent repeats
  ns_f <- environment(utils::getFromNamespace("read.FCS", "flowCore"))
  if (identical(ns_f, asNamespace("flowCoreUtils"))) {
    return(invisible(NULL))
  }

  # 1. Capture original (only once per session)
  if (is.null(fc_read.FCS)) {
    # Direct access to the base namespace version
    fc_read.FCS <<- utils::getFromNamespace("read.FCS", "flowCore")
  }

  # 2. Deep Overload
  ns <- asNamespace("flowCore")
  base::unlockBinding("read.FCS", ns)
  utils::assignInNamespace("read.FCS", fcu_read_fcs, ns = "flowCore")
  base::lockBinding("read.FCS", ns)

  # 3. Surface Overload
  if ("package:flowCore" %in% search()) {
    env <- as.environment("package:flowCore")
    base::unlockBinding("read.FCS", env)
    assign("read.FCS", fcu_read_fcs, envir = env)
    base::lockBinding("read.FCS", env)
  }

  # Add this if the above still isn't enough
  # methods::setGeneric("read.FCS", fcu_read_fcs, where = ns)

  if (!quiet)
    packageStartupMessage(
      "flowCoreUtils: flowCore::read.FCS has been overloaded.")
}

#' Disable the optimized flowCore overload
#' @param quiet Logical. If TRUE, suppresses the message.
#' @export
restore_original_read.FCS <- function(quiet = FALSE) {
  if (is.null(fc_read.FCS)) {
    message("Nothing to restore; original version not captured.")
    return(invisible(NULL))
  }

  # 1. Restore Deep Namespace
  ns <- asNamespace("flowCore")
  base::unlockBinding("read.FCS", ns)
  utils::assignInNamespace("read.FCS", fc_read.FCS, ns = "flowCore")
  base::lockBinding("read.FCS", ns)

  # 2. Restore Surface Search Path
  if ("package:flowCore" %in% search()) {
    env <- as.environment("package:flowCore")
    base::unlockBinding("read.FCS", env)
    assign("read.FCS", fc_read.FCS, envir = env)
    base::lockBinding("read.FCS", env)
  }

  if (!quiet)
    message(
      "flowCoreUtils: Original flowCore::read.FCS restored.")
}

.onLoad <- function(libname, pkgname) {
  # Set the hook for future loading
  setHook(packageEvent("flowCore", "attach"), function(...) {
    # If the user hasn't manually disabled it, auto-inject on attach
    flowCoreUtils::enable_fast_read.FCS()
  })

  # If already loaded, inject immediately
  if ("flowCore" %in% loadedNamespaces()) {
    enable_fast_read.FCS()
  }
}

.onUnload <- function(libpath) {
  # Clean up: Restore flowCore to its original state when package is detached
  restore_original_read.FCS()
}
