
# Methodology
These travel time matrices show travel times between [LSOA11 Trip-points](https://github.com/stupidpupil/wales_lsoa_trip_points) in Wales and the borders and [some hospital sites relevant to NHS Wales](https://github.com/stupidpupil/r_nhs_wales_orgs_and_sites/blob/main/data-raw/nhs_wales_sites.csv).

## Hospital site locations

Postcode centroids have been used as hospital site locations. (A different approach, looking for site entrances on OpenStreetMap, might be developed in the future.)

## Public transport

These times are generated using [street map and public transport timetable data for Wales and bordering regions](https://stupidpupil.github.io/wales_ish_otp_graph/)
and the [*r5r* library](https://ipeagit.github.io/r5r/), which is built on top of the 
[Rapid Realistic Routing on Real-world and Reimagined networks (R5) routing engine](https://github.com/conveyal/r5).

They are regenerated weekly.

### Constraints

The maximum walking distance is 1 kilometre. Walking speed is 3.6 km/h. This is likely a little faster than many people with impaired mobility.

The maximum trip duration is 3 hours. 

Transfer "slack" time - the minimum time between alighting from one vehicle and boarding another - is believed to be 120 seconds. This is likely too short, particularly given [issues with punctuality and reliability](https://gov.wales/sites/default/files/consultations/2020-11/supporting-information-transport-data-and-trends.pdf#page=23) that are otherwise not accounted for. (Unfortunately, it is difficult to change this parameter in *r5r*/R5 at this time.)

### Siteward- and homeward-bound, time-of-day, percentiles
Travel times are calculated seperately for travelling _from_ LSOAs to hospital sites ("siteward-bound" trips) and _to_ LSOAs back from hospital sites ("homeward-bound" trips.)

Travel times are currently calculated over the departure window from 08:00 to 16:00 for siteward-bound trips, for the window from noon until 20:00 for homeward-bound trips, and the median travel time for someone starting their journey at some time in those windows is taken. (A different approach, better reflecting travel-plus-waiting times for appointments, might be developed in the future for siteward-bound trips.)

Where the median travel time is under the maximum trip duration for both the siteward- and homeward-bound trips, then the two travel times are averaged together as the `travel_time_minutes` field. If the median travel time for either leg is too high (or travel is not possible at all given other constraints) then the combination of LSOA and hospital site are excluded entirely.

In general, we suggest using the `travel_time_minutes` field for most purposes.

## Driving

These times are generated using [OpenStreetMap (OSM) road network data](https://www.openstreetmap.org/) and the [Open Source Routing Machine (OSRM)](https://github.com/Project-OSRM/osrm-backend).

### Loading into R

```R
library(tidyverse)
travel_time_matrix <- read_csv("https://raw.githubusercontent.com/stupidpupil/nhs_wales_travel_time_matrices/matrix-releases/arrive_by_0900_driving.csv", comment="#")
travel_time_lookup <- travel_time_matrix %>% pivot_longer(-from_id, names_to='to_id', values_to='travel_time_minutes')
```

### Car Speeds
Car speeds are taken from the Department for Transport's 
[Journey Time Statistics: Notes Definitions](https://assets.publishing.service.gov.uk/government/uploads/system/uploads/attachment_data/file/853603/notes-and-definitions.pdf#page=6)
and reflect average traffic speeds on different types of roads in the "morning peak" between 7 and 10am in 2017.

The table below shows the speeds and how they're mapped on to [OpenStreetMap's `highway` tags](https://wiki.openstreetmap.org/wiki/Roads_in_the_United_Kingdom) in OSRM.

| DfT Type of Road                    | OSM `highway` Tags        | km/h | mph  |
|-------------------------------------|---------------------------|------|------|
| Motorway                            | motorway                  | 77.6 | 48.1 |
| A road                              | trunk, primary            | 43.2 | 26.8 |
| B road                              | secondary                 | 41.9 | 26.0 |
| Minor road                          | tertiary                  | 36.3 | 22.6 |
| Local street                        | unclassified, residential | 18.3 | 11.4 |
| Private road -<br>restricted access | service                   | 15.3 | 9.5  |

### Parking etc.
The travel times do _not_ include any estimates for finding somewhere to park or the process of parking.

# Licence

The public transport travel time matrices produced by this repo are made available under the [ODbL v1.0](https://opendatacommons.org/licenses/odbl/1-0/) by Adam Watkins.

They are derived from other data, including:
- street map information obtained from [OpenStreetMap contributors](https://www.openstreetmap.org/copyright), via [Geofabrik.de](https://download.geofabrik.de/europe/great-britain.html), under the [ODbL v1.0](https://opendatacommons.org/licenses/odbl/1-0/),
- heavy rail timetable information obtained from [RSP Limited (Rail Delivery Group)](http://data.atoc.org/) under the [CC-BY v2.0](https://creativecommons.org/licenses/by/2.0/uk/legalcode), and
- bus and other public transport services timetable information obtained from [Traveline](https://www.travelinedata.org.uk/traveline-open-data/traveline-national-dataset/) and the [UK Department for Transport](https://data.bus-data.dft.gov.uk/) under the [OGL v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
- [LSOA11 Population-Weighted Centroids](https://geoportal.statistics.gov.uk/datasets/ons::lower-layer-super-output-areas-december-2011-population-weighted-centroids/about) and [LSOA11 Boundaries](https://geoportal.statistics.gov.uk/datasets/ons::lower-layer-super-output-areas-december-2011-boundaries-super-generalised-clipped-bsc-ew-v3/about) obtained from the [ONS Open Geography Portal](https://geoportal.statistics.gov.uk/), under the [OGL v3.0](https://www.ons.gov.uk/methodology/geography/licences) and containing OS data (Crown copyright and database right 2021).
