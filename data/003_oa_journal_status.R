#' Exclusion of full OA journals
library(readr)
library(here)
library(bigrquery)
#' Full OA data sources
#' 
#' - `is_doaj` DOAJ (13 December 2023)
#' - `openalex` OpenAlex (Source)
#' - `gold oa` Bielefeld Gold OA (version 5) (https://pub.uni-bielefeld.de/download/2961544/2961545/issn_gold_oa_version_5.csv)
#' 
#' Download matched journal data from Google BigQuery
oa_status_sql <- "SELECT DISTINCT
  issn_l,
  CASE
    WHEN is_oa = TRUE OR is_in_doaj = TRUE THEN TRUE
  ELSE
  FALSE
END
  AS openalex,
  is_doaj AS doaj,
  gold_oa AS bielefeld
FROM (
  SELECT
    jct.issn_l,
    is_oa,
    is_in_doaj,
    is_doaj,
    gold_oa
  FROM
    `subugoe-collaborative.openalex.sources` AS openalex
  INNER JOIN
    `hoa-article.jct.jct_hybrid_jns_new` AS jct
  ON
    openalex.issn_l = jct.issn_l )"

tb <- bq_project_query("subugoe-collaborative", oa_status_sql)
oa_journal_status <- bq_table_download(tb)
readr::write_csv(oa_journal_status, here::here("data", "oa_journal_status.csv"))
