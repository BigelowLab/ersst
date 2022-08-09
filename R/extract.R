
#' extract generic
#'
#' @export
#' @param x \code{sf} object
#' @param y \code{ncdf4} object
#' @param ... Arguments passed to or from other methods
#' @return data frame of covariates (point, or raster)
extract <- function(x, ...) {
  UseMethod("extract")
}

#' @export
#' @param x \code{sf} object
#' @param y \code{ncdf4} object
#' @describeIn extract Extract data from a NCDF4 object
extract.default <- function(x, y = NULL, ...){
  stop("class not known:", paste(class(x), collapse = ", "))
}

#' @export
#' @param x \code{sf} object
#' @param y \code{ncdf4} object
#' @param varname character, one or more variable names
#' @param verbose logical, output helpful messages?
#' @describeIn extract Extract from a NCDF4 object using any sf object
extract.sf <- function(x, y = NULL, 
                       varname = ersst_vars(y),
                       verbose = FALSE, ...){
  
  typ <- xyzt::get_geometry_type(x)
  if (verbose[1]) {
    cat("extract.sf typ =", typ, "\n" )
    cat("  varname:", paste(varname, collapse = ", "), "\n")
  }
  switch(typ,
         "POINT" = {
           g <- sf::st_geometry(x)
           r <- extract(g, y = y, varname = varname, verbose = verbose, ...)
          },
         #"BBOX" = {do something ?}
         "POLYGON" = {
           g <- sf::st_geometry(x)
           ss <- lapply(varname,
                function(varnm,g = NULL, y = NULL, ...) {
                  extract(g, y = y, varname = varnm, verbose = verbose, ...)
                }, g = g, y = y, ...)
           r <- Reduce(c, ss)
          }
         )
  r
}

#' @export
#' @param x \code{sfc} object
#' @param y \code{ncdf4} object
#' @param varname character, one or more variable names
#' @param verbose logical, output helpful messages?
#' @return tibble of extracted values (one variable per covariate)
#' @describeIn extract Extract data from a NCDF4 object using sf POINT object
extract.sfc_POINT <- function(x, y = NULL, 
                              varname = ersst_vars(y),
                              verbose = FALSE, 
                              ...){
  if (verbose[1]) {
    cat("extract.sfc_POINT\n" )
    cat("  varname:", paste(varname, collapse = ", "), "\n")
  }
  
  # Extract points for a given variable
  # 
  # @param tbl table of navigation info, see \code{\link{ersst_nc_nav_point}}
  # @param key table of variable name
  # @param X \code{ncdf4} object
  # @return table of variable values
  .extract_point <- function(tbl, key, X = NULL){
    
    varname <- key$varname[1]
    x <- tbl$data[[1]]
    v <- sapply(seq_len(nrow(x)), 
                function(i){
                  ncdf4::ncvar_get(X, varid = varname,
                                   start = x$start[[i]], count = x$count[[i]])
                })
    dplyr::tibble(!!varname := v)
  }
  
  
  
  nav <- ersst_nc_nav_point(y, x, varname = varname)
  xx <- nav |>
    dplyr::nest_by(.data$varname) |>
    dplyr::group_map(.extract_point, X = y) |> 
    dplyr::bind_cols()
}







#' @export
#' @param x \code{sfc} object that defines a bounding box
#' @param y \code{ncdf4} object 
#' @param varname character one or more variable names
#' @return stars object (one variable per covariate)
#' @describeIn extract Extract data from a NCDF4 object using sf POLYGON object
extract.sfc_POLYGON <- function(x, y = NULL, varname = ersst_vars(y)[1], ...){
  
    #bb <- xyzt::as_BBOX(x)
    nav <- ersst_nc_nav_bb(y, x, varname = varname)
    m <- ncdf4::ncvar_get(y, varid = varname,
                     start = nav$start, count = nav$count)
    stars::st_as_stars(sf::st_bbox(x), 
                         nx = nav$count[1],
                         ny = nav$count[2],
                         values = m ) |>
      stars::st_flip("y") |>
      set_names(varname)
}


