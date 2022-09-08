points_from_osm_for_wikidata_id <- function(wikidata_id, retries=3L, backoff_secs = 30L) {

    overpass_query <- paste0('
[timeout:300];
nwr[wikidata=', wikidata_id, '](50.993464,-5.608538,53.462316,-1.378801) ->.main;
wr.main;
map_to_area;
nwr(area)->.all;
(
  nwr.main;
  node.all[entrance=main];
  node.all[entrance=yes];
  node.all[access=yes];
  node.all[wheelchair=yes];
  node.all[emergency=yes];
  node.all[emergency=emergency_ward_entrance];
  node.all[highway=bus_stop];
  nwr.all[name~"Entrance"];
  nwr.all[building=hospital];
  nwr.all[building];
  nwr.all[healthcare];
  nwr.all[amenity=cafe];
);
out center;')

  tryCatch({
    overpass_url <- paste0("https://overpass-api.de/api/interpreter?data=", utils::URLencode(overpass_query, reserved=TRUE))

    overpass_xml <- readr::read_file(overpass_url)

    # HACK: Rewrite all ways and relations as pretend nodes (using their centers)
    overpass_xml <- overpass_xml |>
      stringr::str_replace_all('<(way|relation) (id=".+?")>\\s+<center (.+?)/>', "<node \\2 \\3>") |>
      stringr::str_replace_all('</(way|relation)>', '</node>') |>
      stringr::str_replace_all('<nd .+/>', '') |>
      stringr::str_replace_all('<member .+/>', '')

    overpass_xml_path <- tempfile(fileext=".xml")
    on.exit({unlink(overpass_xml_path)}, add=TRUE)

    overpass_xml |> write(overpass_xml_path)

    overpass_sf <- sf::st_read(overpass_xml_path, layer="points", quiet=TRUE, options=c("USE_CUSTOM_INDEXING=NO", "CONFIG_FILE=data-raw/osmconf.ini"))

    if(nrow(overpass_sf) == 0){
      return(tibble())
    }

    overpass_sf$score <- 0

    overpass_sf <- overpass_sf |> mutate(
      name_comb = paste0(name, " ", name_cy) |> stringr::str_to_lower() |> stringr::str_squish(),
      score = score + 
        case_when(
          highway == 'bus_stop' ~ 5,
          entrance == "main" ~ 12,
          entrance == "yes" ~ 7,
          entrance == "service" ~ -5,
          amenity == 'hospital' ~ 4,
          amenity == "clinic" ~ 2,
          amenity == "cafe" ~ 1,
          amenity == "place_of_worship" ~ -10,
          TRUE ~ 0
          ) + 
        case_when(
          access == 'yes' ~ 5,
          access == 'private' ~ -10,
          access == 'no' ~ -10,
          TRUE ~ 0
          ) + 
        case_when(
          wheelchair == 'yes' ~ 3,
          wheelchair == 'limited' ~ 1,
          wheelchair == 'no' ~ -10,
          TRUE ~ 0
          ) + 
        case_when(
          emergency == 'yes' ~ 3,
          emergency == "emergency_ward_entrance" ~ 7,
          TRUE ~ 0
          ) + 
        case_when(
          name_comb |> stringr::str_detect("\\b(main|prif|brif)\\b") ~ 5,
          name |> stringr::str_detect("\\b(emergency|ed|a\\s?&\\s?e)\\b") ~ 3,
          TRUE ~ 0
        ) +
        case_when(
          name_comb |> stringr::str_detect("\\b(hospital|ysbyty|infirmary|clafdy)\\b") ~ 5,
          TRUE ~ 0
        ) +
        case_when(
          name_comb |> stringr::str_detect("\\b(offices?)\\b") ~ -5,
          TRUE ~ 0
        ) +
        case_when(
          name_comb |> stringr::str_detect("\\b(entrance|fynedfa|mynedfa)\\b") ~ 6,
          TRUE ~ 0
        ) +
        case_when(
          name_comb |> stringr::str_detect("\\b(reception|derbynfa)\\b") ~ 6,
          TRUE ~ 0
        ) +
        case_when(
          building == "hospital" ~ 3,
          building == "office" ~ -3,
          building == "chapel" ~ -5,
          building == "church" ~ -5,
          building == "industrial" ~ -10,
          building == "warehouse" ~ -10,
          TRUE ~ 0
        ) +
        case_when(
          !is.na(disused_building) ~ -5,
          !is.na(demolished_building) ~ -15,
          TRUE ~ 0
        )
      )


    overpass_sf <- overpass_sf |> sf::st_transform(crs="EPSG:27700")

    centre_ish <- overpass_sf |> filter(score >= 0) |> st_geometry() |> st_union() |> st_centroid()

    overpass_sf <- overpass_sf |>
      mutate(score = score - (as.integer(st_distance(centre_ish, geometry))/60))

    overpass_sf <- overpass_sf |>
      sf::st_transform(crs="EPSG:4326") |>
      arrange(-score)

    return(overpass_sf)
  },
  error=function(err){
    if(retries < 1L){
      stop(err)
    }
    message(err, "\n")
    message("Retrying for ", wikidata_id, " after ", backoff_secs, "s...\n")
    Sys.sleep(backoff_secs)
    return(points_from_osm_for_wikidata_id(wikidata_id, retries-1L, backoff_secs+30L))
  }
  )
}