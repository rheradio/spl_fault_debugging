#############################################################################################
# This script's input is a CSV file with the exhaustive test suite for
# the JHipster Web development stack.
#
# The test suite is reported in the paper:
#
# Axel Halin, Alexandre Nuttinck, Mathieu Acher, Xavier Devroey, Gilles Perrouin, Benoit Baudry:
# Test them all, is it worth it? Assessing configuration sampling on the JHipster Web development 
# stack. Empirical Software Engineering 24(2): 674-717 (2019).
# 
# and it is available at https://github.com/xdevroey/jhipster-dataset
#
# From this CSV, the script induces the rules that explain the detected faults using 
# three algorithms: LEM2, CN2, and AQ.
#############################################################################################

library(tidyverse)
library(RoughSets)
library(rlang)

# Input CSV file 
JHIPSTER_FILE <- "../original_data/jhipster3.6.1-testresults.csv"
# Directory where rules will be generated
RULES_DIR <- "../induced_rules/"

# Import data in a data.frame
jhipster_df <- read.csv(JHIPSTER_FILE,
                     sep = "," ) %>%  
  select(Docker,
         applicationType,
         authenticationType,
         hibernateCache,
         clusteredHttpSession,
         websocket,
         databaseType,
         devDatabaseType,
         prodDatabaseType,
         buildTool,
         searchEngine,
         enableSocialSignIn,
         useSass,
         enableTranslation,
         Build)

# Transform the data.frame into a decision table
jhipster_dt <- SF.asDecisionTable(
  jhipster_df,
  decision.attr = ncol(jhipster_df),
  indx.nominal = 1:ncol(jhipster_df)
)

algorithms <- c("LEM2", "CN2", "AQ")

for (a in algorithms) {
  writeLines(str_c("Inducing rules with ", a))
  rules <- eval(parse_expr(str_c("RI.",a,"Rules.RST(jhipster_dt)")))
  
  ko_rules_df <- tibble(
    rule = character(),
    support = numeric(),
    interactions = numeric()
  )
  
  for (i in 1:length(rules)) {
    if (rules[[i]]$consequent == "KO") {
      at <- rules[[i]]$idx
      ranking <- rank(at)
      at <- colnames(jhipster_df)[at]
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
  
  ko_rules_df$support <- round(ko_rules_df$support*100/nrow(jhipster_df), 2)
  ko_rules_df <- ko_rules_df %>% arrange(desc(support))
  ko_rules_df$coverage <- round(ko_rules_df$support/37.7, 4)*100
  
  write.table(
    ko_rules_df,
    str_c(RULES_DIR, a, "Rules.csv"),
    row.names = FALSE,
    sep = "; "
  )
  
}







