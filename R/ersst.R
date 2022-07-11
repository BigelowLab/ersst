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