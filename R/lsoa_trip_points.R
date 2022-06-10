lsoa_trip_points <- function() {
	lsoa_trip_point_url <- "https://raw.githubusercontent.com/stupidpupil/wales_lsoa_trip_points/points-releases/lsoa11_nearest_road_points.geojson"
	sf::read_sf(lsoa_trip_point_url)
}
