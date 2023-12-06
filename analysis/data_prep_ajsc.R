#' Adding AJSC codes
library(tidyverse)
library(hoaddata)
library(janitor)
#' HOAD journals from JCT
my_jns <- hoaddata::jct_hybrid_jns |>
  # filter(issn_l == "0002-8762") |> 
  mutate(id = issn_l) |>
  pivot_longer(cols = c(issn_l, issn)) |>
  distinct(issn_l = id, issn = value)
#' Scopus journal list from August 2023
scopus <- readxl::read_excel("~/Downloads/extlistAugust2023.xlsx", sheet = 1,
                             .name_repair = janitor::make_clean_names,
                             col_types = "text")
#' Prepare for merge
scopus_norm <- scopus |>
  select(1:4, all_science_journal_classification_codes_asjc) |>
  separate(print_issn, c("print_issn", "print_issn_extra")) |>
  gather(print_issn,
         e_issn,
         print_issn_extra,
         key = "issn_tpye",
         value = "issn") |>
  filter(!is.na(issn)) |>
  # trailing zero's missing in Excel spreadsheet
  mutate(
    issn = ifelse(nchar(issn) == 5, paste0("000", issn), issn),
    issn = ifelse(nchar(issn) == 6, paste0("00", issn), issn),
    issn = ifelse(nchar(issn) == 7, paste0("0", issn), issn)
  ) |>
  # missing hyphen
  mutate(issn = map_chr(issn, function(x)
    paste(c(
      substr(x, 1, 4), substr(x, 5, 8)
    ), collapse = "-")))
#' Match
matched_jns <- my_jns |>
  inner_join(scopus_norm, by = "issn") 
#' Add AJCS codes
ajsc_mapped <- readr::read_csv("https://raw.githubusercontent.com/njahn82/elsevier_hybrid_invoicing/master/data/asjc_mapped.csv", col_types = "ccc") 
subject_jn_df <- matched_jns |>
  distinct() |>
  mutate(ajcs = strsplit(all_science_journal_classification_codes_asjc, ";")) |>
  unnest(ajcs) |>
  mutate(top_level_code = str_extract(ajcs, "\\d{2}")) |>
  inner_join(ajsc_mapped, by = "top_level_code") |>
  rename(top_level = subject_area, subject_area = description) |> 
  select(-all_science_journal_classification_codes_asjc, ajcs, -issn, -issn_tpye) |>
  distinct() |>
  mutate(ajcs = trimws(ajcs))
write_csv(subject_jn_df, here::here("data", "jn_issnl_ajsc.csv"))
