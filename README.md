# flowCoreUtils

`flowCoreUtils` provides utilities and sometimes faster replacements for the Bioconductor `flowCore` package.


### Features

-   **Automatic Overload**: Once loaded, it replaces `flowCore::read.FCS` with a faster version for large files.
-   **Smart Fallback**: Automatically reverts to the original `flowCore` logic for edge cases or specific file types.
-   **Toggleable**: Switch back to the original implementation at any time.


### Installation


#### Binary installation for Windows

Find the release to install at https://github.com/i-cyto/flowCoreUtils/releases. Windows release have an extension ".zip". The example below uses the URL of the first release.

``` r
binary_url <- "https://github.com/i-cyto/flowCoreUtils/releases/download/v0.0.0.9000/flowCoreUtils_0.0.0.9000.zip"
install.packages(binary_url, repos = NULL, type = "win.binary")
```

#### Source installation with compilation (Rtools needed for Windows)

``` r
remotes::install_github("i-cyto/flowCoreUtils")
```


### Usage

Simply loading the library activates the optimization:

``` r
library(flowCore)
library(flowCoreUtils)

# Check overload
environment(flowCore::read.FCS)  # should point to flowCoreUtils

# This now uses the optimized version if the "specific case" is met
data <- read.FCS("large_sample.fcs")

# Revert to standard flowCore behavior manually:
restore_original_read.FCS()
environment(flowCore::read.FCS)  # should point to flowCore

# Turn it back on:
enable_fast_read()
```


### ⚠️Warning on Namespace Injection

This package uses assignInNamespace to ensure that even internal calls from other packages benefit from the speed increase. This affects the global R session.
Use at your own risks!
