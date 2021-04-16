#' Retrieve the ERSST path
#'
#' @export
#' @param ... path segments inlcuding version as 'v5' or 'v4'
#' @param root character, the path to the ersst directory
#' @return character, see \code{file.path}
ersst_path <- function(...,
                       root = "/mnt/ecocast/coredata/ersst"){
  file.path(root, ...)
}

