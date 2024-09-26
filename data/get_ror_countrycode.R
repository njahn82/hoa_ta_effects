# Get Country Codes
library(bigrquery)
library(tidyverse)

my_sql <-  "SELECT
  DISTINCT main.ror_main,
  country_code
FROM
  `subugoe-collaborative.hoaddata.ta_oa_inst` AS main
INNER JOIN
  `subugoe-collaborative.openalex.institutions` AS oalex
ON
  ror_main = oalex.ror"

tb <- bq_project_query("subugoe-collaborative", my_sql)
ror_country_codes_raw <- bq_table_download(tb)

ror_country_codes <- ror_country_codes_raw |>
  # Fix missing country codes
  mutate(country_code = case_when(
    ror_main == "https://ror.org/016xje988" ~ "NA",
    ror_main == "https://ror.org/03nnxqz81" ~ "SE",
    ror_main == "https://ror.org/05v0p1f11" ~ "TR",
    .default = as.character(country_code)
  )) |>
  distinct()

readr::write_csv(ror_country_codes, here::here("data/ror_country_codes.csv"))
