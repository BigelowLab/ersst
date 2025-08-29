#' Set the ersst data path
#'
#' @export
#' @param path the path that defines the location of ersst data
#' @param filename the name the file to store the path as a single line of text
#' @return NULL invisibly
set_root_path <- function(path = "/mnt/s1/projects/ecocast/coredata/ersst",
                          filename = "~/.ersstdata"){
  cat(path, sep = "\n", file = filename)
  invisible(NULL)
}

#' Get the ersst data path from a user specified file
#'
#' @export
#' @param filename the name the file to store the path as a single line of text
#' @return character data path
root_path <- function(filename = "~/.ersstdata"){
  readLines(filename)
}



#' Retrieve the ERSST path
#'
#' @export
#' @param ... path segments including version as 'v5' or 'v4'
#' @param root character, the path to the ersst directory
#' @return character, see \code{file.path}
ersst_path <- function(...,
                       root = root_path()){
  file.path(root, ...)
}

