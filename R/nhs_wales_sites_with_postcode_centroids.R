nhs_wales_sites_with_postcode_centroids <- function() {
  NHSWalesOrgsAndSites::nhs_wales_sites |> 
    filter(Code != "XXXXX") %>%
    twRch::add_fields_based_on_postcode(fields=c("Centroid")) |> 
    twRch::convert_wkt_to_geometry()
}
