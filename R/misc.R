#' Read the South Atlantic Bight bout location data
#' 
#' @export
#' @param filename charcater the name of the file
#' @return sf POINT object
read_sab = function(filename = system.file("extdata/sab.gpkg", package = "ersst")){
  sf::read_sf(filename)
}


#' Get geometry type code
#' 
#' @export
#' @param x bbox, sf or sfc object
#' @param recursive logical, if TRUE drill down to get the type for each
#'   feature.
#' @return character vector such as "POINT" or "POLYGON"
get_geometry_type <- function(x, recursive = FALSE){
  
  if (inherits(x, "bbox")) return("bbox")
  
  if (recursive[1]){
    klass <- sapply(sf::st_geometry(x), class)
  } else {
    klass <- sf::st_geometry(x) |>
      class()
  }
  sub("sfc_", "", klass[1])
}