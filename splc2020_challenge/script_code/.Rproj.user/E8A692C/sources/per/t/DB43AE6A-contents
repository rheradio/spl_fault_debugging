#############################################################################################
# This script's input is a directory containing formatted CSV files, each one describing test 
# cases for a configuration model. Using the LEM2 algorithm, it induces the rules that 
# explain the faults detected in the test cases.
#############################################################################################

library(tidyverse)
library(RoughSets)
library(psych)

# Directory storing the CSV files 
DATA_DIR <- "../formatted_data/"
# Directory where rules will be generated
RULES_DIR <- "../induced_rules/"

# If DISCARD_MODELS == TRUE, with MAX_KOS_PERCENTAGE you can set
# the maximum percentage of KOs allowed; below this percentage
# the model test cases are rejected
DISCARD_MODELS <- FALSE
MAX_KOS_PERCENTAGE <- 50

model_files <- list.files(DATA_DIR)
for (f in model_files) {
  model <- unlist(str_split(f, ".csv"))[1]
  writeLines(str_c("* Proccessing ", model))

  # < Get failures > ####################################################
  
  test_cases_df <- read.csv(
    str_c(DATA_DIR, f),
    sep=";",
    stringsAsFactors = FALSE
  )
  
  test_cases_dt <- SF.asDecisionTable(
    test_cases_df,
    decision.attr = ncol(test_cases_df),
    indx.nominal = 1:ncol(test_cases_df)
  )
  
  writeLines(str_c("  Features = ", ncol(test_cases_df)-1))
  writeLines(str_c("  Configurations = ", nrow(test_cases_df)))
  
  kos <- test_cases_df[,ncol(test_cases_df)] == "KO"
  kos_percentage <- sum(kos)*100/nrow(test_cases_df)
  writeLines(str_c("  ",round(kos_percentage, 2),  " % of all tests are KO"))
  if (kos_percentage>MAX_KOS_PERCENTAGE & DISCARD_MODELS) {
    writeLines(str_c("  No rules are generated"))
    next()
  }
    
  rules <- RI.LEM2Rules.RST(test_cases_dt)
  
  ko_rules_df <- tibble(
    rule = character(),
    support = numeric(),
    interactions = numeric()
  )
  
  for (i in 1:length(rules)) {
    if (rules[[i]]$consequent == "KO") {
      at <- rules[[i]]$idx
      ranking <- rank(at)
      at <- colnames(test_cases_df)[at]
      values <- rules[[i]]$values
      formated_rule <- rep(NA, length(at))
      for (j in 1:length(ranking)) {
        formated_rule[ranking[j]] <- str_c(at[j], "=", values[j])
      }
      ko_rules_df <- add_row(
        ko_rules_df,
        rule = str_c(formated_rule, collapse = " & "),
        interactions = length(at),
        support = length(rules[[i]]$support))
    }  
  }
  
  ko_rules_df$percentage <- round(ko_rules_df$support*100/nrow(test_cases_df), 2)
  
  ko_rules_df <- ko_rules_df %>% arrange(desc(percentage))  
  
  print(describe(ko_rules_df$interactions))
  
  write.table(
    ko_rules_df,
    str_c(RULES_DIR, model, "_rules.csv"),
    row.names = FALSE,
    sep = "; "
  )  
  
}
