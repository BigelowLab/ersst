# And yes, one big csv. Lat, Lon, Year, Month, Fractional year (just in case), SST.
# Given begin/end dates, create a massive CSV of the above

library(dplyr)
library(tidyr)
library(readr)
library(terra)
library(ersst)



dates <- as.Date(c("2011-03-01", "2021-03-01"))
PATH <- ersst::ersst_path()

extract_it <- function(db, key, path = PATH){
  what <- ifelse(db$anomaly[1], "ssta", "sst")
  name <- basename(compose_filename(db, path, ext = ""))
  compose_filename(db, path) %>%
   terra::rast() %>%
    terra::as.data.frame(xy = TRUE, na.rm = FALSE) %>%
    setNames(c("lon", "lat", name)) %>%
    dplyr::as_tibble() %>%
    tidyr::pivot_longer(dplyr::starts_with(paste0("er",what)),
                 values_to = what) %>%
    tidyr::separate(name,
                    into = c(NA, NA, "date")) %>%
    dplyr::mutate(date = as.Date(paste0(date, "01"), format = "%Y%m%d"))
}

xx <- read_database(ersst::ersst_path('v5')) %>%
  filter(dplyr::between(date, dates[1], dates[2])) %>%
  group_by(anomaly) %>%
  group_map(extract_it, .keep = TRUE)

r <- dplyr::left_join(xx[[1]], xx[[2]], by = c("lon", "lat", "date")) %>%
  dplyr::mutate(year = format(date, "%Y"),
                month = format(date, "%m")) %>%
  dplyr::mutate(year_fraction = as.numeric(year) + (as.numeric(month)- 0.5)/12) %>%
  dplyr::select(date, year, month, year_fraction, lon, lat, sst, ssta) %>%
  write_csv(ersst_path("ersst-export.csv.gz"))
