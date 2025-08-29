#' Craft a ERSST URL for a given date
#' 
#' @export
#' @param date character, POSIXt or Date the date to retrieve
#' @param root character, the root URL
#' @param version character the version to fetch
#' @return one or more URLs
ersst_url <- function(date = Sys.Date() - 2,
                      version = "v5",
                      root = file.path("https://www.ncei.noaa.gov/pub/data/cmb/ersst")){

      #"https://www.ncei.noaa.gov/pub/data/cmb/ersst/v5/netcdf/ersst.v5.185401.nc" 
  if (inherits(date, "character")) date <- as.Date(date)                    
  name <- sprintf("ersst.%s.%s.nc",
                  version,
                  format(date, "%Y%m"))
  file.path(root, version[1], "netcdf", name)                     
}


#' Read one or more local ERSST files
#' 
#' @export
#' @param db tabular database
#' @param path chr, the data path
#' @return stars object, with two attributes (variables) if both anomalies and raw values 
#'    are requested.  To read multiple attributes, the same number of dates
#'    must be available for each attribute otherwise an error is encountered.
read_ersst = function(db, path){
  xx = db |>
    dplyr::group_by(anomaly) |>
    dplyr::group_map(
      function(grp, key){
        grp = grp |>
          dplyr::arrange(date)
        files = ersst::compose_filename(grp, path)
        x = stars::read_stars(files, 
                          along = list(time = grp$date)) |>
          rlang::set_names(if(grp$anomaly[1]) "sst.anom" else "sst")
      }, .keep = TRUE)
  do.call(c, append(xx, list(along = NA_integer_)))
}