nhs_wales_sites_with_points <- function(){

  ret <- nhs_wales_sites_with_postcode_centroids()


  for(i in 1:nrow(ret)){
    wikidata_id <- ret[[i, 'Wikidata']]
    message(ret[[i, 'Name']])

    if(is.na(wikidata_id)){
      next
    }

  
    alt_point <- point_for_wikidata_id(wikidata_id)

    if(is.na(alt_point)){
      next
    }

    sf::st_geometry(ret[i,]) <- alt_point
  }

  return(ret)
}