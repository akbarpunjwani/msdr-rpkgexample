globalVariables(c("STATE", "MONTH", "year", "n"))

#' @title
#' Makes the year based filename
#'
#' @description
#' The FARS accidents data is available as year based CSV file. The function
#' takes the year and assumes the filename convention for FARS data and
#' returns the filename for the given year.
#'
#' @param year The year for which the filename is required. It could be any
#'   value that could coerced into integer, else it will prompt for error.
#'
#' @return This function returns the string filename which if exists contain
#'   the data for the accidents during that year
#'
#' examples
#' fars::make_filename(2021)
#'
#' No export
make_filename <- function(year) {
  year <- as.integer(year)
  #print(getwd())
  #sprintf("fars/data-raw/accident_%d.csv.bz2", year)
  system.file("extdata", sprintf("accident_%d.csv.bz2", year), package = "fars")
}


#' @title
#' Reads the CSV data from FARS accidents file
#'
#' @description
#' The function is generic which can read data from any CSV file located
#' at the given path and returns the data as tibble to the caller.
#'
#' @param filename The string filename located at current working directory
#'   or the path along with filename. In case an incorrect filename or path
#'   is provided, it will prompt an error file does not exist.
#'   It may also prompt for error when file exists but data is non-csv.#'
#'
#' @return This function returns the data with value type as tibble in case
#'   the file exists or prompts an error that the file does not exists
#'
#' examples
#' fars::fars_read(make_filename(2013))
#'
#' @importFrom readr read_csv
#' @importFrom dplyr tbl_df
#'
#' No export
fars_read <- function(filename) {
  if(!file.exists(filename))
    stop("file '", filename, "' does not exist")
  data <- suppressMessages({
    readr::read_csv(filename, progress = FALSE)
  })
  dplyr::tbl_df(data)
}


#' @title
#' Reads FARS CSV data for one or more years
#'
#' @description
#' FARS data is available in multiple CSV files, one for each year. This
#' function takes vector of integers representing years and reads each of
#' the respective files. It adds year variable for each obs and returns a
#' list having tibble of months and year for obs found.
#'
#' @param years Integer Vector representing one or more years. In case of
#'   non-integer value, it will prompt for coercion error. In case of any
#'   year, whose data could not be found, error will prompt as invalid year
#'
#' @return List of tibbles for each year, having variable for month & year.
#'   In case of error, it would return NULL
#'
#' examples
#' fars::fars_read_years(c(2013,2015))
#' fars::fars_read_years(2013:2015)
#'
#' @importFrom dplyr mutate
#' @importFrom dplyr select
#' @importFrom magrittr %>%
#'
#' No export
fars_read_years <- function(years) {
  lapply(years, function(year) {
    file <- make_filename(year)
    tryCatch({
      dat <- fars_read(file)
      dplyr::mutate(dat, year = year) %>%
        dplyr::select(MONTH, year)
    }, error = function(e) {
      warning("invalid year: ", year)
      return(NULL)
    })
  })
}


#' @title
#' Summarizes the observations found in FARS data
#'
#' @description
#' Reads the data from CSV files for each of the given years and then
#' summarizes the observations as counts for each month and years. The
#' output shows month(rows) & year(cols) wise counts
#'
#' @param  years Integer Vector representing one or more years. Incorrect
#'   values for years may result in coercion error whereas for years for
#'   which data was not found will show error for invalid year
#'
#' @return This function returns a data.frame having observations for each
#'   months spreaded over the years given. In case year is not found then
#'   the caller is been intimidated
#'
#' @examples
#' fars::fars_summarize_years(2013)
#' fars::fars_summarize_years(c(2013,2015))
#' fars::fars_summarize_years(2013:2015)
#'
#' @importFrom dplyr bind_rows
#' @importFrom dplyr group_by
#' @importFrom dplyr summarize
#' @importFrom dplyr n
#' @importFrom tidyr spread
#' @importFrom magrittr %>%
#'
#' @export
fars_summarize_years <- function(years) {
  dat_list <- fars_read_years(years)
  dplyr::bind_rows(dat_list) %>%
    dplyr::group_by(year, MONTH) %>%
    dplyr::summarize(n = n()) %>%
    tidyr::spread(year, n)
}



#' @title
#' Maps the FARS observations for specified state & years
#'
#' @description
#' Reads the CSV data for the specified year and then filters the data
#' for the specified state num. The filtered data is then mapped on the
#' plot using the Latitude and Longitude value of each observation.
#'
#' @param state.num Integer value representing the state number
#' @param year The year for which the observations are required
#'
#' @return Map plot showing the observations as found for the given
#'   state.num and year
#'
#' @examples
#' fars::fars_map_state(1,2013)
#' fars::fars_map_state(1,2014)
#' fars::fars_map_state(1,2015)
#'
#' @importFrom magrittr %in%
#' @importFrom dplyr filter
#' @importFrom maps map
#' @importFrom graphics points
#'
#' @export
fars_map_state <- function(state.num, year) {
  filename <- make_filename(year)
  data <- fars_read(filename)
  state.num <- as.integer(state.num)

  if(!(state.num %in% unique(data$STATE)))
    stop("invalid STATE number: ", state.num)
  data.sub <- dplyr::filter(data, STATE == state.num)
  if(nrow(data.sub) == 0L) {
    message("no accidents to plot")
    return(invisible(NULL))
  }
  is.na(data.sub$LONGITUD) <- data.sub$LONGITUD > 900
  is.na(data.sub$LATITUDE) <- data.sub$LATITUDE > 90
  with(data.sub, {
    maps::map("state", ylim = range(LATITUDE, na.rm = TRUE),
              xlim = range(LONGITUD, na.rm = TRUE))
    graphics::points(LONGITUD, LATITUDE, pch = 46)
  })
}

########
#' Short Title for the function
#'
#' Second Block with Longer Description of the function
#' could be of multiple lines as required
#'
#' @param Define each element of the function
#'   In case of multiple lines indent is required
#' @param Could have as many input parameters as required by function
#'
#' @return Fourth block should be of return value
#'
#' @examples
#' This block follows from next line with few valid examples
########
#Use below statement to oxygenize roxygen2 docs
#roxygen2::roxygenize('.', roclets=c('rd', 'collate', 'namespace'))
########
