Overview
================
2023-11-08

``` r
library(tidyverse, warn.conflicts = FALSE)
```

``` r
library(hoaddata)

ta_oa_inst <- readr::read_csv("https://github.com/subugoe/hoaddata/releases/download/v0.2.82/ta_oa_inst.csv.gz")
```

What is the number and proportion of open access articles in hybrid
journals published under a transformative agreement?

``` r
ta_oa_growth <- ta_oa_inst |>
  filter(ta_active == TRUE, !is.na(cc), issn_l != "0027-8424") |>
  group_by(cr_year) |>
  summarise(ta_oa = n_distinct(doi))
hybrid_oa_growth <- hoaddata::cc_articles |>
  filter(issn_l != "0027-8424") |>
  group_by(cr_year) |>
  summarise(oa_all = n_distinct(doi))
ta_df <- inner_join(ta_oa_growth, hybrid_oa_growth) |>
  mutate(ta_oa_prop = ta_oa / oa_all) |>
  mutate(no_ta = oa_all - ta_oa, 
         no_ta_prop = 1 - ta_oa_prop) |>
  mutate(cr_year = as.factor(cr_year))
# year all
year_all <-
  hoaddata::jn_ind |>
  filter(issn_l != "0027-8424") |>
  distinct(issn_l, cr_year, jn_all) |> 
  group_by(cr_year) |> 
  summarise(n = sum(jn_all))

oa_ta_plot <- ta_df |>
  select(cr_year, ta_oa, no_ta) |>
  pivot_longer(cols = c(ta_oa, no_ta), names_to = "type", values_to = "value") |>
  filter(cr_year != "2023") |>
  inner_join(year_all) |>
  # plot
  ggplot(aes(cr_year, value / n, fill = type, group = type)) +
  geom_area() +
  scale_fill_manual("Hybrid OA", values = c(no_ta = "#b3b3b3a0", ta_oa = "#56B4E9"), labels = c(no_ta = "Other", ta_oa = "Agreement"),  guide = guide_legend(reverse = TRUE)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), labels = scales::percent_format(), limits = c(0, .15), breaks = c(0, .05, .1, .15)) +
  theme_minimal() +
  labs(y = "Hybrid OA Uptake", x = NULL) +
  theme(legend.position="top", legend.justification = "left", axis.text.x = element_blank())
```

``` r
ta_share_plot <- ta_df |>
  select(cr_year, ta_oa_prop, no_ta_prop) |>
  pivot_longer(cols = c(ta_oa_prop, no_ta_prop), names_to = "type", values_to = "value") |>
  filter(cr_year != "2023", type == "ta_oa_prop") |>
  ggplot(aes(factor(cr_year), value, group = 1)) +
  geom_bar(stat = "identity", fill = "#56B4E9") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), breaks = c(0, 0.25, 0.5),
                     labels = scales::percent) +
  theme_minimal() +
  labs(y = "Percentage\nof Hybrid OA\nvia Agreement", x = "Publication Year")
```

``` r
jn_hybrid_oa_growth <- hoaddata::cc_articles |>
  filter(issn_l != "0027-8424") |>
  group_by(cr_year, issn_l) |>
  summarise(oa_all = n_distinct(doi)) |>
  mutate(cr_year = factor(cr_year))
# year all
jn_year_all <-
  hoaddata::jn_ind |>
  filter(issn_l != "0027-8424") |>
  distinct(issn_l, cr_year, jn_all) |> 
  group_by(cr_year, issn_l) |> 
  summarise(n = sum(jn_all))

oa_jn_box <- left_join(jn_hybrid_oa_growth, jn_year_all) |>
  mutate(prop = oa_all / n) |> 
  filter(cr_year != "2023") |>
  ggplot(aes(gsub("^20", "'", as.character(cr_year)), prop)) +
  geom_boxplot(outlier.shape = NA) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)),
                     labels = scales::percent) +
  coord_cartesian(ylim = c(0,0.7)) +
  theme_minimal() +
  labs(y = "OA Uptake\nper Hybrid Journal", x = "Publication Year")
```

``` r
ta_oa_growth <- ta_oa_inst |>
  filter(ta_active == TRUE, !is.na(cc), issn_l != "0027-8424") |>
  group_by(cr_year, issn_l) |>
  summarise(ta_oa = n_distinct(doi))
hybrid_oa_growth <- hoaddata::cc_articles |>
  filter(issn_l != "0027-8424") |>
  group_by(cr_year, issn_l) |>
  summarise(oa_all = n_distinct(doi))
ta_df <- left_join(hybrid_oa_growth, ta_oa_growth) |>
  mutate(across(everything(), .fns = ~replace_na(.,0))) |>
  mutate(no_ta = oa_all - ta_oa) |>
  mutate(cr_year = as.factor(cr_year))

summary_all <- inner_join(ta_df, jn_year_all, by = c("cr_year", "issn_l")) |>
  mutate(prop_ta_oa = ta_oa / n,
         prop_no_ta = no_ta / n) |>
  ungroup() |>
  distinct(cr_year, issn_l, prop_ta_oa, prop_no_ta) |>
  pivot_longer(cols = c(prop_ta_oa, prop_no_ta))
# plot
box_ta_prop <- summary_all |>
  filter(cr_year != "2023") |>
  # With at least one OA article
  filter(value > 0) |>
  ggplot(aes(gsub("^20", "'", as.character(cr_year)), value, fill = name)) +
  geom_boxplot(outlier.shape = NA) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)),
                     labels = scales::percent) +
  coord_cartesian(ylim = c(0,0.5)) +
  scale_fill_manual("Hybrid OA", values = c(prop_no_ta = "#b3b3b3a0", prop_ta_oa = "#56B4E9"), labels = c(no_ta = "Other", ta_oa = "Agreement")) +
  theme_minimal() +
  labs(y = "OA Uptake\nper Hybrid Journal", x = "Publication Year")
  
```

``` r
library(patchwork)
design = "AC
BD"
wrap_plots(
  A = oa_ta_plot,
  B = ta_share_plot,
  C = oa_jn_box,
  D = box_ta_prop,
  design = design,
  widths = c(2, 1),
  heights = c(2, 1),
  guides = "collect"
) &
  theme(
    legend.position = "top",
    legend.justification = "left",
    legend.direction = "horizontal",
    panel.grid.minor = element_blank(),
                panel.border = element_rect(color = "grey50", fill = NA),
    axis.title=element_text(size = 10)) &
    plot_annotation(tag_levels = 'A')
```

<img src="001_overview_files/figure-gfm/unnamed-chunk-2-1.png" width="99%" style="display: block; margin: auto;" />

by publisher

``` r
jn_ind_jct <- hoaddata::jct_hybrid_jns |>
  inner_join(hoaddata::jn_ind, by = "issn_l") |>
  filter(issn_l != "0027-8424")

ta_active <- ta_oa_inst |>
  filter(issn_l != "0027-8424") |>
  filter(ta_active == TRUE, !is.na(cc)) |>
  group_by(cr_year, issn_l, esac_publisher) |>
  summarise(ta_oa = n_distinct(doi)) |>
  mutate(cr_year = as.character(cr_year))

jn_ind_jct_oa <- jn_ind_jct |>
  filter(!is.na(cc)) |>
  distinct(cr_year, issn_l, esac_publisher, cc, cc_total, jn_all) |>
  group_by(cr_year, issn_l, esac_publisher, jn_all) |>
  summarise(oa = sum(cc_total, na.rm = TRUE))

jn_ind_jct_all <- jn_ind_jct |>
  distinct(cr_year, issn_l, esac_publisher, jn_all) 

publisher_df <- left_join(jn_ind_jct_all, jn_ind_jct_oa) |>
  mutate(cr_year = as.character(cr_year)) |>
  left_join(ta_active) |>
  mutate(across(everything(), .fns = ~replace_na(.,0))) |>
  mutate(no_ta = oa - ta_oa)


## plot
publisher_plot_df <- publisher_df |> 
  pivot_longer(cols = c(ta_oa, no_ta), names_to = "type", values_to = "value") |>
  mutate(
    publisher = case_when(
      esac_publisher == "Elsevier" ~ "Elsevier",
      esac_publisher == "Springer Nature" ~ "Springer Nature",
      esac_publisher == "Wiley" ~ "Wiley",
      is.character(esac_publisher) ~ "Other"
    )
  ) |>
  mutate(publisher =
           forcats::fct_relevel(
             publisher,
             c("Elsevier", "Springer Nature", "Wiley", "Other") 
           )) |>
  filter(cr_year != "2023", oa > 0)

#+ publisher ta shares
publisher_ta_prop <- publisher_plot_df |>
  filter(type == "ta_oa") |>
  group_by(cr_year, publisher) |>
  summarize(ta_oa = sum(value), oa = sum(oa), jn_all = sum(jn_all)) |>
  mutate(prop = ta_oa / oa) 


oa_publisher <- publisher_plot_df |>
  group_by(cr_year, publisher, type) |>
  summarise(value = sum(value))
all_publisher <- publisher_plot_df |>
  distinct(cr_year, issn_l, publisher, jn_all) |>
  group_by(cr_year, publisher) |>
  summarise(jn_all = sum(jn_all))

publisher_summary_df <- inner_join(oa_publisher, all_publisher) |>
  mutate(prop = value / jn_all)

publisher_prop <- ggplot(publisher_summary_df, aes(gsub("^20", "'", as.character(cr_year)), prop, fill = type, group = type)) +
  geom_area() +
  facet_wrap(~publisher, nrow = 1) +
  scale_fill_manual("Hybrid OA", values = c(no_ta = "#b3b3b3a0", ta_oa = "#56B4E9"), labels = c(no_ta = "Other", ta_oa = "Agreement"),  guide = guide_legend(reverse = TRUE)) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), labels = scales::percent_format()) +
  theme_minimal() +
  labs(y = "Hybrid OA Uptake", x = NULL) +
  theme(legend.position="top", legend.justification = "left", axis.text.x = element_blank())

publisher_boxplot <- publisher_plot_df |>
  filter(value > 0) |>
  ggplot(aes(gsub("^20", "'", as.character(cr_year)), value / jn_all, fill = type)) +
  geom_boxplot(outlier.shape = NA, show.legend = FALSE) +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)),
                     labels = scales::percent) +
  scale_fill_manual("Hybrid OA", values = c(no_ta = "#b3b3b3a0", ta_oa = "#56B4E9"), labels = c(no_ta = "Other", ta_oa = "Agreement")) +
  coord_cartesian(ylim = c(0,0.65)) +
  facet_wrap(~publisher, nrow = 1) +
  labs(y = "OA Uptake\nby Hybrid Journal", x = "Publication Year") +
  theme_minimal() +
    theme(strip.background = element_blank(),
    strip.text.x = element_blank()
    )

publisher_ta_prop_plot <- publisher_ta_prop |>
  ggplot(aes(gsub("^20", "'", as.character(cr_year)), prop)) +
  geom_bar(stat = "identity", fill = "#56B4E9") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.05)), breaks = c(0, 0.25,0.5,0.75), limits = c(0, .75),
                     labels = scales::percent) +
  facet_wrap(~publisher, nrow = 1) +
  theme_minimal() +
  labs(y = "Percentage\nof Hybrid OA\nvia Agreement", x = NULL) +
  theme(
    axis.text.x = element_blank(),
    strip.background = element_blank(),
    strip.text.x = element_blank())
```

``` r
library(patchwork)
design = "A
B
C"
wrap_plots(
  A = publisher_prop,
  B = publisher_ta_prop_plot,
  C = publisher_boxplot,
  design = design,
#  guides = "collect",
 # widths = c(2, 1),
  heights = c(1, 0.5, 1)
) &
  theme(
    legend.position = "top",
    legend.justification = "left",
    legend.direction = "horizontal",
    panel.grid.minor = element_blank(),
                panel.border = element_rect(color = "grey50", fill = NA),
    axis.title=element_text(size = 10)) &
    plot_annotation(tag_levels = 'A') 
```

<img src="001_overview_files/figure-gfm/unnamed-chunk-4-1.png" width="99%" style="display: block; margin: auto;" />
