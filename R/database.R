#' Compose a filename from a database
#'
#' @export
#' @param x database (tibble) with date, anomaly, version
#' @param path character, the root path for the filename
#' @param ext character, the filename extension to apply (with dot)
#' @return character vector of filenames in form \code{<path>/ersst.vv.YYYYmm.ext}
compose_filename <- function(x, path = ".", ext = ".tif"){
  name <- ifelse(x$anomaly, "erssta", "ersst")
  file.path(path,
            x$version,
            format(x$date, "%Y"),
            sprintf("%s.%s.%s%s", name, x$version, format(x$date, "%Y%m"), ext[1]))
}

#' Decompose a filename into a database
#'
#' @export
#' @param x character, vector of one or more filenames
#' @param ext character, the extension to remove (including dot)
#' @return table (tibble) database of date, var, and version
decompose_filename <- function(x = c("ersst.v5.185401.tif","erssta.v5.185401.tif"),
                               ext = ".tif"){

  # a tidy version of gsub
  global_sub <- function(x, pattern, replacement = ".tif", fixed = TRUE, ...){
    gsub(pattern, replacement, x, fixed = fixed, ...)
  }
  x <- basename(x) %>%
    global_sub(pattern = ext, replacement = "") %>%
    strsplit(split = ".", fixed = TRUE)
  # <path>/ersst.v5.185401.tif
  dplyr::tibble(
    date = as.Date(paste0(sapply(x, '[[', 3), "01"), format = "%Y%m%d"),
    anomaly = grepl("erssta", x, fixed = TRUE),
    version = sapply(x, '[[', 2))
}

#' Construct a database tibble give a data path
#'
#' @export
#' @param path character the directory to catalog
#' @param pattern character, the filename pattern (as glob) to search for
#' @param ... other arguments for \code{\link{decompose_filename}}
#' @return tibble database
build_database <- function(path, pattern = "*.tif", ...){
  if (missing(path)) stop("path is required")
  list.files(path[1], pattern = utils::glob2rx(pattern),
             recursive = TRUE, full.names = TRUE) %>%
    decompose_filename(...)
}


#' Read a file-list database
#'
#' @export
#' @param path character the directory with the database
#' @param filename character, optional filename
#' @return a tibble
read_database <- function(path,
                          filename = "database.csv.gz"){
  if (missing(path)) stop("path is required")
  filepath <- file.path(path[1], filename[1])
  stopifnot(file.exists(filepath))
  # date var depth
  suppressMessages(readr::read_csv(filepath, col_types = 'Dlc'))
}

#' Write the file-list database
#'
#' We save only date (YYYY-mm-dd), anomaly and version. If you
#' have added other variables to the database they will be dropped in the saved
#' file.
#'
#' @export
#' @param x the tibble or data.frame database
#' @param path character the directory to where the database should reside
#' @param filename character, optional filename
#' @return the input tibble (even if saved version has columns dropped)
write_database <- function(x, path,
                           filename = "database.csv.gz"){
  if (missing(path)) stop("path is required")
  filepath <- file.path(path[1], filename[1])
  # date version
  dummy <- x %>%
    dplyr::select(.data$date, .data$anomaly, .data$version) %>%
    readr::write_csv(filepath)
  invisible(x)
}

#' Append one or more rows to a database.
#'
#' The databases must have identical column classes and names.
#'
#' @export
#' @param db tibble, the database to append to
#' @param x tibble, the new data to append.  If this has no rows then the
#'  original database is returned
#' @param rm_dups logical, if TRUE remove duplicates from combined databases.
#'  If x has no rows then this is ignored.
#' @return the updated database tibble
append_database <- function(db, x, rm_dups = TRUE){

  if (!identical(colnames(db), colnames(x)))
    stop("x column names must be identical to db column names\n")

  if (!identical(sapply(db, class), sapply(x, class)))
    stop("x column classes must be identical to db column classes\n")

  if (nrow(x) > 0){
    db <- dplyr::bind_rows(db, x)
    if (rm_dups) db <- dplyr::distinct(db)
  }

  db
}
