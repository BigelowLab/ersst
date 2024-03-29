% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ncdc.R
\name{ncdc_build_uri}
\alias{ncdc_build_uri}
\title{Build a URI for given dates and a single version.}
\usage{
ncdc_build_uri(
  date = seq(from = as.Date("1854-01-01"), to = Sys.Date(), by = "month"),
  version = "v5"
)
}
\arguments{
\item{date}{Date or castable to Date, one or more dates. Dates preceding}

\item{version}{character, ala "v5"
1854-01-01 are returned as NA.  Dates exceding the previous current month are
mapped to the most recently available month.}
}
\description{
Note: just because you build a URI for a given month doesn't mean it
exists.  Be sure to compare to \code{ncdc_list_available}.
}
