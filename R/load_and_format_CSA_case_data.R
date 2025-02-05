#' load_and_format_CSA_case_data
#'
#' @return
#' @export
#'
#' @importFrom dplyr filter mutate if_else right_join group_by arrange lag
#' @importFrom readr read_csv cols col_character
#' @importFrom stringr str_detect
#' @importFrom tidyr fill
#' @importFrom magrittr %>%  %<>%
load_and_format_CSA_case_data = function()
{
  data_path4 = 
    "https://raw.githubusercontent.com/datadesk/california-coronavirus-data/master/latimes-place-totals.csv"
  
  data4a = readr::read_csv(data_path4, col_types = readr::cols(note = readr::col_character())) %>% 
    dplyr::filter(county == "Los Angeles")
  
  # fix inconsistent naming 
  data4a %<>% dplyr::mutate(
    
    name = dplyr::if_else(
      name == "Silver Lake",
      "Silverlake",
      name
    ),
    name = dplyr::if_else(
      name == "Athens",
      "Athens-Westmont",
      name
    ),
    name = dplyr::if_else(
      stringr::str_detect(name, "Pasadena"),
      "Pasadena",
      name
    ),
    name = dplyr::if_else(
      stringr::str_detect(name, "Long Beach"),
      "Long Beach",
      name
    )
    #  x = round(x, 3),
    #  y = round(y, 3)
    
  ) 
  
  # print the data around the 4th:
  # data4a %>% filter(date %in% (ymd("2020/07/04") + c(0,1,2))) # missing July 4th and 5th dates
  
  # some CSAs have dates missing, so we fill them in:
  dates_and_places = expand.grid(
    date = seq(min(data4a$date), max(data4a$date), by = 1),
    name = unique(data4a$name))
  
  # fills in any missing date
  data4a %<>%
    dplyr::right_join(
      dates_and_places,
      by = c("date", "name")
    ) %>%
    dplyr::group_by(name) %>%
    dplyr::arrange(date) %>%
    tidyr::fill(
      .direction = "downup",
      confirmed_cases, population, county, fips) %>%
    dplyr::mutate(
      "new_cases" = 
        confirmed_cases - dplyr::lag(confirmed_cases, 1, default = NA),
      "pct_infected_cumulative" = 
        100*(confirmed_cases/population),
      "new_cases_in_last_14_days" = 
        confirmed_cases - dplyr::lag(confirmed_cases, 14),
      "pct_new_cases_in_last_14_days" = 
        new_cases_in_last_14_days/population * 100
    )
  
  return(data4a)
}