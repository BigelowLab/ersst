# A script to compare the local repos to that online.  If any locals are missing then
# download the new stuff, add tot he datbase and save

library(logger)
library(dplyr)
library(ersst)

version <- "v5"

logger::log_formatter(logger::formatter_sprintf)
logger::log_appender(logger::appender_file(ersst::ersst_path(version, "log")))
log_info("updating version %s", version)

v5_path <- ersst::ersst_path(version)
local_db <- ersst::read_database(v5_path)

log_info("gathering online listing of available dates")
avail_db <- ersst::ncdc_list_available(version = version)

need_db <- avail_db %>%
  dplyr::filter(!(date %in% local_db$date))

if (nrow(need_db) > 0){
  log_info("need to fetch %i dates", nrow(need_db))
  new_db <- ersst::fetch_ersst(date = need_db$date,
            version = version,
            path = ersst::ersst_path(),
            avail_db = avail_db,
            overwrite = TRUE,
            verbose = FALSE)

  db <- ersst::append_database(local_db, new_db) %>%
    dplyr::arrange(date) %>%
    ersst::write_database(v5_path)
} else {
  log_info("local database up to date with online resources")
}

log_info("done")
if (!interactive()) quit(save = "no", status = 0)
