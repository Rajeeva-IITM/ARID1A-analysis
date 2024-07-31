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
  # annotation <- pluck(annot_df, filename(file)) # %>% gsub('_rep.*', '', .)
  annotation <- filename(file)   # use this for models built on averaged data
  dfs[[i]] <- read_parquet(file) %>% 
    mutate(experiment = annotation) 
  i=i+1
}

common_cols <- dfs %>% 
  map(colnames) %>% 
  reduce(intersect)

df <- dfs %>% bind_rows()

schema_list = map(rep(1, length(colnames(df))), \(x) float32()) %>%  
  as.list()  
names(schema_list)  <-  colnames(df)
schema_list$experiment <- string()

schema_final <- schema(schema_list)


rm(dfs)

common_df <- df %>% 
  select(where(~ !any(is.na(.))))


common_df_schema <- schema_list %>% 
  names() %>% 
  keep(\(x) x %in% common_cols) %>% 
  schema_list[.] %>% 
  schema()

df %>% 
  arrow_table(schema = schema_final) %>% 
  write_parquet(., "../outputs/sampling/localgini_sprintcore/final/full.parquet")

common_df %>% 
  arrow_table(schema = common_df_schema) %>% 
  write_parquet(., "../outputs/sampling/localgini_sprintcore/final/common.parquet")
