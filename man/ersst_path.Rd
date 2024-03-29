% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/path.R
\name{ersst_path}
\alias{ersst_path}
\title{Retrieve the ERSST path}
\usage{
ersst_path(..., root = "/mnt/ecocast/coredata/ersst")
}
\arguments{
\item{...}{path segments inlcuding version as 'v5' or 'v4'}

\item{root}{character, the path to the ersst directory}
}
\value{
character, see \code{file.path}
}
\description{
Retrieve the ERSST path
}
