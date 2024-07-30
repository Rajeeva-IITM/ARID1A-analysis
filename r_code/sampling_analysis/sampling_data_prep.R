# Read the sampling data and convert into single file for further use

library(dplyr)
library(arrow)
library(purrr)
library(ggplot2)
# library(stringr)

filename <- function(x){ # Get filename from path
  strsplit(x, '/', fixed=T) %>%  # Split the path
    unlist() %>%                  # Convert from list to vector
    tail(n=1) %>%                  # Last element
    strsplit(".", fixed=T) %>%     # Split based on dot
    unlist() %>%                   
    pluck(1) %>% 
    return
}

annot_df <- read_tsv_arrow("../data/samplenames.tsv", ) %>% as.list()
files <- list.files("../outputs/sampling/localgini_sprintcore/",
                    pattern = ".*parquet$", full.names = T)

dfs <- list()

i=1
for(file in files){
  annotation <- pluck(annot_df, filename(file)) # %>% gsub('_rep.*', '', .)
  dfs[[i]] <- read_parquet(file) %>% 
    mutate(experiment = annotation) 
  i=i+1
}

common_cols <- dfs %>% 
  map(colnames) %>% 
  reduce(intersect)

df <- dfs %>% bind_rows()
rm(dfs)

common_df <- df %>% 
  select(where(~ !any(is.na(.))))

write_parquet(df, "../outputs/sampling/localgini_sprintcore/final/full.parquet")
write_parquet(common_df, "../outputs/sampling/localgini_sprintcore/final/common.parquet")
