#' # OVERVIEW: Data used
#' 
#' ## Data
#' 
#' *{hoaddata} version v0.2.91* provides journal-level and article-level data used.
#' 
#' <https://github.com/subugoe/hoaddata/releases/tag/v0.2.91>
#' 
#' This R package contains: 
#' 
#' *Journal-level data*, retrieved from the cOAlition S public transformative
#' agreement data on 11 December 2023
#' 
#' <https://github.com/njahn82/jct_data/tree/a00138fa78bca769cc103caed715b2fab1375b6e/data>
#' 
#' The code repository also contains code used to obtain the data.
#' 
#' {hoaddata} also represents *article-level data* retrieved from
#' 
#'  - Crossref release 2023/11
#'  - OpenAlex release 2023-11-21
#'  
#'  as well as the code used to compile the data from SUB Göttingen Scholarly
#'  data warehouse.
#'  
#'  The main dataset, providing article-level data about publications linked to 
#'  transformative agreements and institutions, is available as {hoaddata} 
#'  release asset: 
#'  <https://github.com/subugoe/hoaddata/releases/download/v0.2.91/ta_oa_inst.csv.gz>
#'  
#'  A version is provided in `data/` folder
download.file("https://github.com/subugoe/hoaddata/releases/download/v0.2.91/ta_oa_inst.csv.gz",
              destfile = here::here("data", "ta_oa_inst.csv.gz")) 
#' *Raw data for reproducibility*: To improve reproducibility, 
#' the underlying raw data used to compile {hoaddata} 
#' version v0.2.91 is available via Google BigQuery `hoa-article.hoaddata_nov23`.
#' 
#' *Subject classification* data was obtained from Scopus on 4 Oct 2023 and is
#' stored in `data/jn_scopus_ind_subjects.csv`
#' 
#' *Country information* for institutions with transformative agreements were 
#' obtained from OpenAlex in the following
library(bigrquery)
library(tidyverse)

  my_sql <-  "SELECT
    DISTINCT main.ror_main,
    country_code
  FROM
    `hoa-article.hoaddata_nov23.ta_oa_inst` AS main
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

