fetch_osrm_graph <- function() {
	old_opts <- options(timeout=max(options()$timeout,600))
  	on.exit(options(old_opts))
	download.file("https://github.com/stupidpupil/wales_ish_otp_graph/releases/download/2022-06-11T12-37-05/osrm_driving.zip", destfile="data-raw/osrm_driving.zip")
	unzip("data-raw/osrm_driving.zip", exdir="data-raw")
}