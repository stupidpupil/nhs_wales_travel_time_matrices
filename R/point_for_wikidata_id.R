point_for_wikidata_id <- function(wikidata_id) {

  overpass_sf <- points_from_osm_for_wikidata_id(wikidata_id)

  if(nrow(overpass_sf) > 0){

    ret <- st_geometry(overpass_sf[1, ])
    st_crs(ret) <- 'EPSG:4326'
    return(ret)
  }

  message("Falling back to Wikidata...")

  try({
    wikidata_ret <- jsonlite::read_json(paste0("https://www.wikidata.org/wiki/Special:EntityData/", wikidata_id, ".json"))

    lat <- wikidata_ret$entities[[wikidata_id]]$claims$P625[[1]]$mainsnak$datavalue$value$latitude
    lon <- wikidata_ret$entities[[wikidata_id]]$claims$P625[[1]]$mainsnak$datavalue$value$longitude

    wikidata_tibble <- tibble(latitude = lat, longitude = lon) |>
      sf::st_as_sf(crs='EPSG:4326', coords = c("longitude", "latitude"))

    return(wikidata_tibble[[1, 'geometry']])
  })


  return(NA)
}