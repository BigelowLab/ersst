# 2025-08-29
#
# I slipped up when migrating to v5 by missing a corrected path
# in the automated download process.  This silly script fixes that
# once complete I moved all of the errant files (which were fine but badly)
# organized into 'vold' whihc may get deleted.  Then I fixed downlaod
# code to use 'v5', and updated the local database


if (Sys.Date() > as.Date("2025-08-24")){
  stop("this is a run once script - do not run")
}

suppressPackageStartupMessages({
  library(dplyr)
  library(ersst)
})


path = ersst::ersst_path()
v5path = ersst::ersst_path("v5")

years = 1854:2025
mashupdirs = file.path(path, years)
mashupfiles = list.files(mashupdirs,
                         recursive = TRUE,
                         pattern = glob2rx("*.tif"),
                         full.names = TRUE)
mashup = tibble(
  year = basename(dirname(mashupfiles)),
  name = basename(mashupfiles),
  file = mashupfiles) 

#ff = lapply(mashupdirs, list.files, pattern = glob2rx("*.tif")) |>
#  setNames(years)


v5files = list.files(v5path,
                     recursive = TRUE,
                     pattern = glob2rx("*.tif"),
                     full.names = TRUE)
v5 = tibble(
  year = basename(dirname(v5files)),
  name = basename(v5files),
  file = v5files)


ix = !(mashup$name %in% v5$name)
copyme = mashup |>
  filter(ix) |>
  rowwise() |>
  group_map(
    function(row, key){
      opath = file.path(v5path, row$year)
      ok = dir.create(opath, showWarnings=FALSE, recursive = TRUE)
      ofile = file.path(opath, row$name)
      file.copy(row$file, ofile, overwrite = TRUE)
    }
  ) |>
  unlist()
