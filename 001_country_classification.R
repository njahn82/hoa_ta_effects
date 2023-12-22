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
bigrquery::bq_table_upload(
  bq_table("hoa-article", "hoaddata_nov23", "country_classification"),
  country_classification
)
#' Aggregate per group
my_sql <- "WITH
  all_articles AS (
  SELECT
    issn_l,
    cr_year,
    cat,
    COUNT(DISTINCT doi) AS articles,
  FROM
    `hoa-article.hoaddata_nov23.cr_openalex_inst_full` AS alex
  LEFT JOIN
    `hoa-article.hoaddata_nov23.country_classification` AS country
  ON
    alex.country_code = country.iso2
  GROUP BY
    issn_l,
    cr_year,
    cat ),
  cc_articles AS (
  SELECT
    issn_l,
    cr_year,
    cat,
    COUNT(DISTINCT doi) AS cc_articles,
  FROM
    `hoa-article.hoaddata_nov23.cc_openalex_inst` AS alex
  LEFT JOIN
    `hoa-article.hoaddata_nov23.country_classification` AS country
  ON
    alex.country_code = country.iso2
  GROUP BY
    issn_l,
    cr_year,
    cat ),
  global AS (
  SELECT
    all_articles.*,
    cc_articles.cc_articles
  FROM
    all_articles
  LEFT JOIN
    cc_articles
  ON
    all_articles.issn_l = cc_articles.issn_l
    AND all_articles.cr_year = cc_articles.cr_year
    AND all_articles.cat = cc_articles.cat ),
  -- TA calculation
  ta_raw AS (
  SELECT
    doi,
    cr_year,
    issn_l,
    ta_active,
    cc,
    cat,
    country_code
  FROM
    `hoa-article.hoaddata_nov23.country_classification` AS country
  LEFT JOIN (
    SELECT
      DISTINCT ror.doi,
      cr_year,
      issn_l,
      ta_active,
      cc,
      country_code
    FROM
      `hoa-article.hoaddata_nov23.ta_oa_inst` AS ta
    LEFT JOIN (
      SELECT
        country_code,
        doi
      FROM
        `hoa-article.hoaddata_nov23.ta_oa_inst` AS main
      INNER JOIN
        `subugoe-collaborative.openalex.institutions` AS oalex
      ON
        ror_main = oalex.ror ) AS ror
    ON
      ror.doi = ta.doi )
  ON
    country_code = country.iso2
  WHERE
    doi IS NOT NULL),
  ta_ind AS (
  SELECT
    issn_l,
    cr_year,
    cat,
    COUNT(DISTINCT doi) AS ta_articles_all,
    COUNT(DISTINCT
    IF
      (ta_active = TRUE, doi, NULL)) AS ta_articles_active,
    COUNT(DISTINCT
    IF
      (ta_active = TRUE
        AND cc IS NOT NULL, doi, NULL)) AS ta_oa_active,
  FROM
    ta_raw
  GROUP BY
    issn_l,
    cr_year,
    cat )
  -- Bringing it all together
SELECT
  DISTINCT global.*,
  ta_articles_all,
  ta_articles_active,
  ta_oa_active
FROM
  global
LEFT JOIN
  ta_ind
ON
  global.issn_l = ta_ind.issn_l
  AND global.cr_year = ta_ind.cr_year
  AND global.cat = ta_ind.cat"

tb <- bq_project_query("subugoe-collaborative", my_sql)
oecd_stats <- bq_table_download(tb)
# Back up
readr::write_csv(oecd_stats, here::here("data", "oecd_stats.csv"))
