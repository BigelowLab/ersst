# A script to compare the local repos to that online.  If any locals are missing then
# download the new stuff, add to the database and save
suppressPackageStartupMessages({
  library(argparser)
  library(logger)
  library(dplyr)
  library(ersst)
})

Args = argparser::arg_parser("Update your local ERSST data repository",
                             name = "Rscript update_ersst.R",
                             hide.opts = TRUE) |>
  argparser::add_argument("--version", default = "v5", help = 'ERSST version ID') |>
  argparser::add_argument("--path", default = ersst::ersst_path(), help = 'path to data repos') |>
  argparser::parse_args()

v_path = file.path(Args$path, Args$version)
logger::log_formatter(logger::formatter_sprintf)
logger::log_appender(logger::appender_file(file.path(Args$path, "log")))
log_info("updating version %s", Args$version)

dbfile = file.path(v_path, "databas.csv.gz")
local_db <- if(file.exists(dbfile)){
    ersst::read_database(v_path)
  } else {
    dplyr::tibble(date = Sys.Date(), anomaly = "", version = "") |>
      dplyr::slice(0)
  }
log_info("gathering online listing of available dates")
avail_db <- ersst::ncdc_list_available(version = Args$version)

need_db <- avail_db %>%
  dplyr::filter(!(date %in% local_db$date))

if (nrow(need_db) > 0){
  log_info("need to fetch %i dates", nrow(need_db))
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
  log_info("local database up to date with online resources")
}

log_info("done")
if (!interactive()) quit(save = "no", status = 0)
