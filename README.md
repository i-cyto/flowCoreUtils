# flowCoreUtils

`flowCoreUtils` provides utilities and sometimes faster replacements for the Bioconductor `flowCore` package.


### Features

-   **Automatic Overload**: Once loaded, it replaces `flowCore::read.FCS` with a faster version for large files.
-   **Smart Fallback**: Automatically reverts to the original `flowCore` logic for edge cases or specific file types.
-   **Toggleable**: Switch back to the original implementation at any time.


### Installation

``` r
# install.packages("remotes")
remotes::install_github("yourusername/flowCoreUtils")
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
