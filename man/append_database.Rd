% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/database.R
\name{append_database}
\alias{append_database}
\title{Append one or more rows to a database.}
\usage{
append_database(db, x, rm_dups = TRUE)
}
\arguments{
\item{db}{tibble, the database to append to}

\item{x}{tibble, the new data to append.  If this has no rows then the
original database is returned}

\item{rm_dups}{logical, if TRUE remove duplicates from combined databases.
If x has no rows then this is ignored.}
}
\value{
the updated database tibble
}
\description{
The databases must have identical column classes and names.
}
