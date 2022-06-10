next_tuesday <- function(time_as_string, tz="Europe/London"){
  nt <- lubridate::today() %>% (function(x){x + lubridate::days(9 - lubridate::wday(x, week_start = 1))})

  lubridate::parse_date_time(
    paste0(nt %>% lubridate::format_ISO8601(), "T", time_as_string), 
    c('ymd HM', 'ymd HMS'), tz=tz)
}
