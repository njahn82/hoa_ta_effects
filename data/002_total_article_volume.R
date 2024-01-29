#' Proportion of total articles in Crossref by journal business model
#' 
library(bigrquery)
library(tidyverse)
#' 
my_sql <- "WITH
  hoad AS (
  SELECT
    doi,
    issn_l,
    'hoad' AS src
  FROM
    `hoa-article.hoaddata_nov23.cc_md` AS hoad ),
  crossref AS (
  SELECT
    cr.doi,
    EXTRACT ( YEAR
    FROM
      issued ) AS cr_year,
    publisher,
    src
  FROM
    `subugoe-collaborative.cr_instant.snapshot` AS cr
  LEFT JOIN
    hoad
  ON
    cr.doi = hoad.doi
  WHERE
    type = 'journal-article'
    AND NOT REGEXP_CONTAINS( title, '^Author Index$|^Back Cover|^Contents$|^Contents:|^Corrigendum|^Cover Image|^Cover Picture|^Editorial Board|^Front Cover|^Frontispiece|^Inside Back Cover|^Inside Cover|^Inside Front Cover|^Issue Information|^List of contents|^Masthead|^Title page|^Correction$|^Corrections to|^Corrections$|^Withdrawn|^Frontmatter' )
    AND ( NOT REGEXP_CONTAINS(page, '^S')
      OR page IS NULL ) -- include online only articles, lacking page or issue
    AND ( NOT REGEXP_CONTAINS(issue, '^S')
      OR issue IS NULL ) )
SELECT
  COUNT(DISTINCT crossref.doi) AS n_articles,
  cr_year,
  src,
  open_access.oa_status 
FROM
  crossref
LEFT JOIN
  `subugoe-collaborative.openalex.works` AS openalex
ON
  crossref.doi = openalex.doi
WHERE
  (cr_year BETWEEN 2018
  AND 2022) AND NOT primary_location.source.issn_l = '0027-8424'
GROUP BY
  cr_year,
  src,
  open_access.oa_status
ORDER BY
  n_articles DESC"

tb <- bq_project_query("subugoe-collaborative", my_sql)
cr_stats <- bq_table_download(tb)
# backup
write_csv(cr_stats, here::here("data", "cr_stats.csv"))
