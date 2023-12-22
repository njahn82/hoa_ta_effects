#' Apply OECD classification
library(dplyr)
library(bigrquery)
library(tibble)
library(countrycode)
#' Prepare matching table
oecd_countries <- readr::read_csv(here::here("data", "oecd.csv")) |>
  mutate(cat = "OECD")
brics <- tibble::tribble(
  ~ country, ~ iso3,
  "Brazil", "BRA",
  "Russia", "RUS",
  "India", "IND",
  "China", "CHN",
  "South Africa", "ZAF"
) |>
  mutate(cat = "BRICS")

country_classification <- bind_rows(oecd_countries, brics) |>
  mutate(iso2 = countrycode::countrycode(iso3,
                                         origin = "iso3c",
                                         destination = "iso2c")) |>
  mutate(iso2 = ifelse(iso3 == "IRE", "IE", iso2))
#' Upload to BQ
#' 
my_bq_table <-  bq_table("hoa-article", "hoaddata_nov23", "country_classification")
if (bigrquery::bq_table_exists(my_bq_table)) {
  bigrquery::bq_table_delete(my_bq_table)
}
bigrquery::bq_table_upload(
  my_bq_table,
  country_classification
)

#' Aggregate per group
my_sql <- "WITH
  doi_raw AS (
  SELECT
    DISTINCT cc_md.doi,
    cc_md.issn_l,
    cc_md.cr_year,
    CASE
      WHEN cc IS NOT NULL THEN 1
    ELSE
    0
  END
    AS oa,
    CASE
      WHEN EXISTS ( SELECT * FROM ( SELECT doi FROM `hoa-article.hoaddata_nov23.ta_oa_inst` WHERE ta_active = TRUE AND cc IS NOT NULL ) AS t WHERE cc_md.doi = t.doi ) THEN 1
    ELSE
    0
  END
    AS ta_oa
  FROM
    `subugoe-collaborative.hoaddata.cc_md` AS cc_md),
  -- Add country info
  country_info AS (
  SELECT
    DISTINCT doi_raw.*,
    country.cat
  FROM
    doi_raw
  LEFT JOIN
    `hoa-article.hoaddata_nov23.cr_openalex_inst_full` AS alex
  ON
    doi_raw.doi = alex.doi
  LEFT JOIN
    `hoa-article.hoaddata_nov23.country_classification` AS country
  ON
    alex.country_code = country.iso2)
SELECT
  DISTINCT issn_l,
  cr_year,
  cat,
  SUM(oa) AS oa,
  SUM(ta_oa) AS ta_oa,
  COUNT(DISTINCT doi) AS articles
FROM
  country_info
GROUP BY
  issn_l,
  cr_year,
  cat"

tb <- bq_project_query("subugoe-collaborative", my_sql)
oecd_stats <- bq_table_download(tb)
# Back up
readr::write_csv(oecd_stats, here::here("data", "oecd_stats.csv"))
