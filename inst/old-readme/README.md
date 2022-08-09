
```
### Old README (may be resurrected later)

### List available file online

It is easy to generate a listing of data files, organized by month, that are [available online](https://www.ncei.noaa.gov/pub/data/cmb/ersst/v5/netcdf/).

```{r list, message = FALSE}
library(dplyr)
library(ersst)

online_db <- ncdc_list_available(version = "v5", verbose = TRUE)
online_db
```

The anomaly column indicates if the file is for `sst` or `sst anomaly` - a bit of a red herring in this case.  It will become important later, but in the meantime know that each online file contains 2 layers: `sst` or `sst anomaly (ssta)`.  The anomaly computation is [discussed here](https://www.ncdc.noaa.gov/data-access/marineocean-data/extended-reconstructed-sea-surface-temperature-ersst-v5).


### Download online data

For a URL by date and version, then download.

```{r download_one}
uri <- ncdc_build_uri(as.Date("1995-12-18"), version = "v5")
# [1] "https://www.ncei.noaa.gov/pub/data/cmb/ersst/v5/netcdf/ersst.v5.20199512.nc"
ok <- download_ersst(uri, path = ".", verbose = TRUE)
ok
```

Each file contains 2 layers: `sst` and `ssta`

```{r read_and_show}
library(stars)
s <- read_stars(names(ok))
s
```

### Download a series, unpack and save

If you are developing a local repository of the data, you can use built-in capabilities of `fetch_ersst()`. Each layer is saved separately as either `ersst.vv.YYYYmm.tif` or `erssta.vv.YYYYmm.tif`.  Returned is a database of the fetched-and-stored contents. Note that you can pass in the available online database listing; this just saves the time needed to repeat the query.

```{r download_suite}
root_path <- "~/ersst_data"
dates <- seq(from = as.Date("2020-11-15"), by = "month", length = 4)
db <- fetch_ersst(dates, version = 'v5', path = root_path, verbose = TRUE, avail_db = online_db)
db
```

You will likely want to save this database. Note that it is best to save it with the version.  Who knows when the next version will be released, but best practice is to be ready for it. If you have an existing database, you can append the new database to it before saving (see `append_database`).

```{r save_database}
v5_path <- ersst_path("v5", root = root_path)
db <- write_database(db, v5_path)
```

### Using the local database

If you have kept a database file (and if you mess your up, see `build_database()`) then you can use it to easily find the files you want without having to search the directories.

```{r filter_database}
library(stars)
sub_db <- read_database(v5_path) %>%
  filter(anomaly == TRUE, 
         between(date, as.Date("2020-11-01"), as.Date("2021-02-01")))
sub_filenames <- compose_filename(sub_db, root_path)
ss <- read_stars(sub_filenames, along = "band")
breaks <- 11
plot(ss, 
     main = format(sub_db$date, "anomaly %Y-%b"),
     col = heat.colors(breaks))
```
