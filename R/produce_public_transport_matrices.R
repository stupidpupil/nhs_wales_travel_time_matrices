produce_public_transport_matrices <- function(){
  r5r_core <- r5r::setup_r5("data-raw/r5r_network_dat")

  max_walk_dist <- 1500

  sites <- nhs_wales_sites_with_points()

  unlink("output/sites.geojson")
  sites |> sf::st_write("output/sites.geojson")

  sites <- sites %>%
    mutate(id = Code)

  trip_points <- lsoa_trip_points() %>%
    mutate(id = LSOA11CD)

  siteward_bound <- r5r::travel_time_matrix(r5r_core = r5r_core,
    origins = trip_points,
    destinations = sites,
    mode = c('WALK', 'TRANSIT'),
    departure_datetime = next_tuesday("08:00"),
    max_walk_time = max_walk_dist/60,
    max_trip_duration = (3*60),
    time_window = 8*60,
    verbose = FALSE
    ) %>% rename(home_id = from_id, site_id = to_id, siteward_bound_travel_time_minutes = travel_time_p50)

  saveRDS(siteward_bound, "data-raw/siteward_bound.rds")

  homeward_bound <- r5r::travel_time_matrix(r5r_core = r5r_core,
    origins = sites,
    destinations = trip_points,
    mode = c('WALK', 'TRANSIT'),
    departure_datetime = next_tuesday("12:00"),
    max_walk_time = max_walk_dist/60,
    max_trip_duration = (3*60),
    time_window = 8*60,
    verbose = FALSE
    ) %>% rename(home_id = to_id, site_id = from_id, homeward_bound_travel_time_minutes = travel_time_p50)

  saveRDS(homeward_bound, "data-raw/homeward_bound.rds")

  final_ttm <- siteward_bound %>% 
    left_join(homeward_bound) %>% tibble() %>% 
    filter(
      !is.na(siteward_bound_travel_time_minutes), 
      !is.na(homeward_bound_travel_time_minutes)) %>% 
    mutate(travel_time_minutes = 
      ((siteward_bound_travel_time_minutes+homeward_bound_travel_time_minutes)/2L) %>% ceiling() %>% as.integer()
    )

  final_ttm %>% arrange(home_id, site_id) %>% write_csv("output/Tue0800_Tue1200_public_p50.csv")
}
