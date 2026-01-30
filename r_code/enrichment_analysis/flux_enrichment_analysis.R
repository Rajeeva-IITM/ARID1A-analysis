# Code for performing flux enrichment analysis in R
# The MATLAB code is wrong

library(dplyr)
library(readr)
library(purrr)

FEA <- function(given_reactions, total_reactions, groups) {
  unique_groups <- unique(groups)
  total_group_size <- length(groups)
  total_group_counts <- table(groups) %>%
    as.list() %>%
    unlist() # This is the group sizes for the total reactions

  # print(total_group_counts)

  # Get group counts for given set
  # Get which groups are present in the given set
  given_groups_predicate <- map_lgl(total_reactions, \(x) {
    x %in% given_reactions
  })
  given_groups <- groups[given_groups_predicate]
  given_group_names <- names(given_groups)

  given_group_counts <- table(given_groups) %>%
    as.list() %>%
    unlist

  #subset the total to have only the relevant groups

  total_group_counts <- total_group_counts[names(given_group_counts)]
  # print(total_reactions)
  # print(total_group_counts)
  # print(given_group_counts)

  # Putting it all together:
  # dhyper function requires 4 variables:
  # - x: Number of desirable group drawn from the entirety, this we get from given groups
  # - m: Number of desirable group in the population, this we get from total group size
  # - n: Number of undesirable groups in the population, Total size - m
  # - k: Total number of groups drawn, this is the length of given reactions

  pvals <- dhyper(
    x = given_group_counts,
    m = total_group_counts,
    n = total_group_size - total_group_counts,
    k = length(given_reactions)
  )

  fold_change = (given_group_counts / length(given_reactions)) /
    (total_group_counts / total_group_size)

  tibble(
    pval = pvals,
    Adj_pval = p.adjust(pvals, method = 'fdr'),
    Group = names(given_group_counts),
    Enriched_set_size = given_group_counts,
    Total_set_size = total_group_counts,
    Fold_change = fold_change
  ) %>%
    return()
}

# Generic plotting function for FEA result
plot_FEA <- function(fea_result, n = 10, p.cutoff = 0.05) {
  fea_result %>%
    filter(Adj_pval < p.cutoff) %>%
    arrange(-Fold_change) %>%
    slice_head(n = n) %>%
    ggplot(aes(
      y = reorder(Group, -Fold_change),
      x = Fold_change,
      fill = -log10(Adj_pval)
    )) +
    geom_bar(stat = 'identity') +
    labs(x = "Fold Change", y = "Reaction system", fill = "Adj. log p-value") +
    scale_fill_continuous(type = 'viridis') %>%
      return
}

# an example of the total reactions and groups can be found in data/recon_reaction_names.csv
