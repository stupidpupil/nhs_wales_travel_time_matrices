produce_driving_matrices <- function(){
  sites <- nhs_wales_sites_with_postcode_centroids() %>%
    mutate(id = Code) %>% select(id)

  trip_points <- lsoa_trip_points() %>%
    mutate(id = LSOA11CD) %>% select(id)

  loc <- sites %>% bind_rows(trip_points)

  driving_ttm <- run_osrm({osrm::osrmTable(loc)})

  driving_ttm <- driving_ttm$durations %>% as_tibble()

  colnames(driving_ttm) <- loc$id
  driving_ttm$from_id <- loc$id

  driving_ttm <- driving_ttm %>% relocate(from_id)

  saveRDS(driving_ttm, "data-raw/driving_ttm.rds")

  driving_ttm %>% write_csv("output/arrive_by_0900_driving.csv")
}
