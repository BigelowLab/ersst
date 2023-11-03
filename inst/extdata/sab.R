x = readr::read_csv("inst/extdata/sab.csv") |>
  dplyr::mutate(lon = lon %% 360) |>
  sf::st_as_sf(coords = c("lon", "lat"), crs = "OGC:CRS84") |>
  sf::write_sf("inst/extdata/sab.gpkg")
