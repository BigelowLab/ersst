#' Returns the URI for people to browse
#'
#' @export
#' @param version character, ala "v5"
#' @param base_uri character, the NCDC/NCEI base URI
#' @return character uri
ncdc_uri <- function(version = "v5",
                     base_uri = "https://www.ncdc.noaa.gov/data-access/marineocean-data"){

  file.path(base_uri,
    sprintf("extended-reconstructed-sea-surface-temperature-ersst-%s", version[1]))
}


#' Returns the known base URIs for file listings
#'
#' @export
#' @param version, character, ala "v5"
#' @return character uri
ncdc_list_uri <- function(version = "v5"){
  switch(version[1],
    "v4" = "https://www1.ncdc.noaa.gov/pub/data/cmb/ersst/v4/netcdf",
    "v5" =  "https://www.ncei.noaa.gov/pub/data/cmb/ersst/v5/netcdf")
}

#' Retrieve a listing of the \code{filenames} currently posted by NCDC/NCEI
#' of available ERSST.
#'
#' @export
#' @param version character, ala "v5"
#' @param simplify logical, if TRUE then make the returned tibble easier tp work with
#' @return tibble of posted files (includes columns 'Name', 'Last modified', 'Size' and 'Description') unless \code{simply = TRUE} in which case
ncdc_list_available <- function(version = "v5", simplify = TRUE){
  uri <- ncdc_list_uri(version=version)
  x <- httr::GET(uri)
  httr::stop_for_status(x, task = paste("read uri:", uri))
  r <- httr::content(x, type = "text", encoding = 'UTF-8') %>%
    xml2::read_html() %>%
    xml2::xml_child(search = "body") %>%
    xml2::xml_child(search = "table") %>%
    rvest::html_table() %>%
    dplyr::as_tibble() %>%
    dplyr::filter(grepl("ersst", .data$Name, fixed = TRUE))
  if (simplify){
    r <- r %>%
      dplyr::pull(.data$Name) %>%
      decompose_filename(ext = ".nc")
  }
  r
}


#' Build a URI for given dates and a single version.
#'
#' Note: just because you build a URI for a given month doesn't mean it
#' exists.  Be sure to compare to \code{ncdc_list_available}.
#'
#' @export
#' @param date Date or castable to Date, one or more dates. Dates preceding
#' @param version character, ala "v5"
#' 1854-01-01 are returned as NA.  Dates exceding the previous current month are
#' mapped to the most recently available month.
ncdc_build_uri <- function(date = seq(from = as.Date("1854-01-01"),
                                       to = Sys.Date(),
                                       by = "month"),
                            version = "v5"){
  # https://www.ncei.noaa.gov/pub/data/cmb/ersst/v5/netcdf/ersst.v5.185401.nc
  # https://www1.ncdc.noaa.gov/pub/data/cmb/ersst/v4/netcdf/ersst.v4.185401.nc
  if (FALSE) date <- as.Date(c("1850-03-04","1854-01-02", "1854-01-12",
                               format(Sys.Date(), "%Y-%m-%d")))
  if (!inherits(date, "Date")){
    date <- try(as.Date(date))
    if (inherits(date, "try-error")){
      print(date)
      stop("date must be castable to Date class")
    }
  }

  # here we convert each requested date to the first of the month just prior to
  # the request.  Dates the preceed the first request are returned as NA
  # while dates the exceed the last available always return the last available.
  prior_month <- 31
  # request Feb 28/29 goes back to end of Jan
  # request Jan 31 goes back to end of Dec, etc
  lut <- seq(from = as.Date("1854-01-01"),
             to = Sys.Date() - prior_month,
             by = "month")
  ix <- findInterval(date, lut)
  ix[ix < 1] <- NA
  date <- lut[ix]


  u <- ncdc_list_uri(version=version[1])

  pattern  <- paste0(sprintf("ersst.%s.", version[1]), "%s.nc")
  file.path(u, sprintf(pattern, format(date, "%Y%m")))
}


#' Download NCDC ERSST file to the specified directory.
#'
#' @export
#' @param uri character the URI of the file to downlaod with \code{download.file}
#' @param path charcater the name of the path to download to
#' @return named logical where TRUE indicates success, name is the filename
download_ersst <- function(
  uri = "https://www.ncei.noaa.gov/pub/data/cmb/ersst/v5/netcdf/ersst.v5.185401.nc",
  path = tempdir()){

  filename <- file.path(path[1], basename(uri[1]))
  ok <- utils::download.file(uri[1],
                             destfile = filename,
                             mode = "wb")
  sapply(filename, file.exists)
}


#' Fetch a NCDC ERSST file, unpack it and save to the specified path
#'
#' @export
#' @param date Date or Date-castable, one of more dates to fetch
#' @param version character, the version
#' @param path character, the output path. Version subdirectory and
#'   years subdirectories are made by default.
#' @param overwrite logical, if TRUE overwrite existing file(s)
#' @return a database tibble (date and version)
fetch_ersst <- function(date = Sys.Date(),
                        version = "v5",
                        path = "./ersst_data",
                        overwrite = TRUE){


  # generate REQUEST uris
  # list the resources available as AVAILable
  # compare REQUEST and AVAIL
  # for each REQUEST in AVAIL
  # download
  # extract with stars
  # save as tiff to version path
  request_uri <- ncdc_build_uri(date = date, version = version)
  request_db <- decompose_filename(request_uri, ext = ".nc")
  avail_db <- ncdc_list_available(version = version)

  fetch_one <- function(x, key, path = "."){
    ok <- download_ersst(x$uri)
    if (ok){
      filename <- names(ok)
      db <- decompose_filename(filename)
      dba <- db %>%
        dplyr::mutate(anomaly = TRUE)
      db <- dplyr::bind_rows(db, dba)
      s <- terra::rast(filename)
      files <- compose_filename(db, path)
      ok <- sapply(dirname(files), dir.create, recursive = TRUE, showWarnings = FALSE)
      for (i in seq_len(length(files))){
          terra::writeRaster(s[[i]], files[i], overwrite = overwrite)
      }
      ok <- unlink(filename)
    } else {
      db <- NULL
    }
    db
  }

  dplyr::semi_join(avail_db, request_db, by = "date") %>%
    dplyr::mutate(uri = ncdc_build_uri(date = .data$date, version = .data$version)) %>%
    dplyr::rowwise() %>%
    dplyr::group_map(fetch_one, .keep = TRUE, path = path) %>%
    dplyr::bind_rows()
}
