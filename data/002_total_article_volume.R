#' Proportion of total articles in Crossref by journal business model
#' 
library(bigrquery)
library(tidyverse)
#' 
my_sql <- "WITH
  hoad AS (
  SELECT
    doi,
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
  cr_year BETWEEN 2018
  AND 2022
GROUP BY
  cr_year,
  src,
  open_access.oa_status
ORDER BY
  n_articles DESC"

tb <- bq_project_query("subugoe-collaborative", my_sql)
cr_stats <- bq_table_download(tb)

my_df <- cr_stats |>
  mutate(cat = case_when(
    is.na(src) & oa_status == "gold" ~ "gold",
    src == "hoad" ~ "hoad",
    .default = "other"
  )) |> 
  group_by(cr_year, cat) |>
  summarise(n = sum(n_articles)) |>
  mutate(cat = factor(cat, levels = c("hoad", "other", "gold"))) |>
  mutate(prop = n / sum(n) )

ggplot(my_df, aes(cr_year, n, fill = cat)) +
  geom_bar(position = position_stack(reverse = TRUE), color = "black", stat = "identity") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), labels =  scales::number_format(big.mark = ",")) +
  scale_fill_manual("Journal type", values = c("hoad" = "#5789B6", "other" = "#D8D4C9", "gold" = "#DA6524"),
                    labels = c("hoad" = "Hybrid in TA", "other" = "Other", "gold" = "Full OA")) +
  theme_minimal() +
  labs(x = "Publication year", y = "Total articles") +
  guides(fill = guide_legend(reverse = TRUE)) +
  theme(
    panel.grid.minor = element_blank(),
    panel.border = element_rect(color = "grey50", fill = NA),
    axis.title=element_text(size = 10),
    legend.position = "top", 
    legend.justification = "right") 

  