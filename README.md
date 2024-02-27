# Source code supplement -- How open are hybrid journals included in transformative agreements?

## Overview

This repository provides data and code used for the preprint

Najko Jahn, 2024. **How open are hybrid journals included in transformative agreements?**

This repository is organized as a [research compendium](https://doi.org/10.7287/peerj.preprints.3192v2). A research compendium contains data, code, and text associated with it. 

## Analysis files

### Main analysis

The [`analysis/`](analysis/) directory contains the manuscript written in R Markdown:

[`analysis/manuscript.Rmd`](analysis/manuscript.Rmd)

The R Markdown is rendered to a Latex document. See the rendered pdf [here](analysis/manuscript.pdf): 

[{renv}](https://rstudio.github.io/renv/articles/renv.html) is used to create an reproducible environment for all the R packages used in the analysis.

### Data

Data is openly available through an R data package, [{hoaddata}]({https://github.com/subugoe/hoaddata/releases/tag/v0.2.91}). 
{hoaddata} contains not only the datasets used in the data analysis. 
It also includes code used to compile the data by connecting it to [a cloud-based Google Big Query data warehouse](https://subugoe.github.io/scholcomm_analytics/data.html), where scholarly big data from Crossref, OpenAlex and Unpaywall were imported.
To increase computational reproducibility, data aggregation through hoaddata was automatically carried out using GitHub Actions.

### Contact

Najko Jahn, Data Analyst, SUB Göttingen. najko.jahn@sub.uni-goettingen.de

