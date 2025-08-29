# A script to compare the local repos to that online.  If any locals are missing then
# download the new stuff, add to the database and save
# 
# usage: Rscript update_ersst.R [--] [--help] [--version VERSION] [--path PATH]
# 
# Update your local ERSST data repository
# 
# flags:
#   -h, --help     show this help message and exit
# 
# optional arguments:
#   -v, --version  ERSST version ID [default: v5]
#   -p, --path     path to data repos [default: /mnt/s1/projects/ecocast/coredata/ersst]


suppressPackageStartupMessages({
  library(argparser)
  library(charlier)
  library(dplyr)
  library(ersst)
})


main = function(path, ver){
  v_path = file.path(path, ver)
  dbfile = file.path(v_path, "database.csv.gz")
  local_db <- if(file.exists(dbfile)){
    ersst::read_database(v_path)
  } else {
    dplyr::tibble(date = Sys.Date(), anomaly = "", version = "") |>
      dplyr::slice(0)
  }
  charlier::info("gathering online listing of available dates")
  avail_db <- ersst::ncdc_list_available(version = Args$version) |>
    na.omit()
  
  need_db <- avail_db %>%
    dplyr::filter(!(date %in% local_db$date))
  
  if (nrow(need_db) > 0){
    charlier::info("need to fetch %i dates", nrow(need_db))
    new_db <- ersst::fetch_ersst(date = need_db$date,
                                 version = Args$version,
                                 path = Args$path,
                                 avail_db = avail_db,
                                 overwrite = TRUE,
                                 verbose = FALSE)
    
    db <- ersst::append_database(local_db, new_db) %>%
      dplyr::arrange(date) %>%
      ersst::write_database(v_path)
  } else {
    charlier::info("local database up to date with online resources")
  }
  return(0)
}


Args = argparser::arg_parser("Update your local ERSST data repository",
                             name = "Rscript update_ersst.R",
                             hide.opts = TRUE) |>
  argparser::add_argument("--version", default = "v5", help = 'ERSST version ID') |>
  argparser::add_argument("--path", default = ersst::ersst_path(), help = 'path to data repos') |>
  argparser::parse_args()

charlier::start_logger(file.path(Args$path, "log.txt"))
charlier::info("updating version %s", file.path(Args$path, Args$version))

path = Args$path
ver = Args$version

if (!interactive()){

  ok = main(path, ver)
  charlier::info("done")
  quit(save = "no", status = ok)
}

