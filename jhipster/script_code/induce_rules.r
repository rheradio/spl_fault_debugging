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
library(RWeka)
library(gmodels)
library(caret)

# Input CSV file 
JHIPSTER_FILE <- "../original_data/jhipster3.6.1-testresults.csv"
# Directory where rules will be generated
RULES_DIR <- "../induced_rules/"
# Directory where the performance of induction rule algorithms is saved
STATISTICS_DIR <- "../rule_statistics/"

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

TOTAL_CASES <- nrow(jhipster_df)
KO_PERCENTAGE <- (sum(jhipster_df$Build=="KO")/TOTAL_CASES)*100

###################################################################
# RoughSets #######################################################
###################################################################
# Transform the data.frame into a decision table
jhipster_dt <- SF.asDecisionTable(
  jhipster_df,
  decision.attr = ncol(jhipster_df),
  indx.nominal = 1:ncol(jhipster_df)
)

RoughSets_algorithms <- c("LEM2", "CN2", "AQ")

for (a in RoughSets_algorithms) {
  writeLines(str_c("Inducing rules with ", a))
  rules <- eval(parse_expr(str_c("RI.",a,"Rules.RST(jhipster_dt)")))
  
  rules_as_string <- capture.output(rules)

  ko_rules_df <- tibble(
    rule = character(),
    interactions = numeric(),
    support = numeric()
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
  ko_rules_df$coverage <- round(ko_rules_df$support/KO_PERCENTAGE, 4)*100
  
  write.table(
    ko_rules_df,
    str_c(RULES_DIR, a, "StdRulesJHipster.csv"),
    row.names = FALSE,
    sep = "; "
  )
  
  prediction <- predict(rules, jhipster_dt)
  performance <- c("================================================",
                   str_c(" ", a, "'s performance on JHipster"),
                   "================================================")
  performance <- c(performance,
                   capture.output(
                     CrossTable(jhipster_df$Build, prediction$predictions,
                                prop.chisq = FALSE, prop.c = TRUE, prop.r = TRUE,
                                dnn = c('actual', 'predicted')
                     )
                   )
  )
  performance <- c(performance,
                   capture.output(
                     confusionMatrix(jhipster_df$Build, 
                                     prediction$predictions, 
                                     positive="KO")
                   )
  )  
  write(performance, 
        str_c(STATISTICS_DIR, a, "PerformanceJHipster.txt"))
}

###################################################################
# RWeka ###########################################################
###################################################################

RWekalgorithms <- c("OneR", "JRip", "PART")

for (a in RWekalgorithms) {
  
  rules <- eval(parse_expr(str_c(a, "(Build ~ ., data = jhipster_df)")))
  rules_as_string <- capture.output(rules)
  write(rules_as_string, 
        str_c(RULES_DIR, a, "RulesOriginalJHipster.txt"))

  if (a %in% c("JRip", "PART")) {
    
    if (a == "JRip") {
      number_of_rules <- as.numeric(str_extract(rules_as_string[length(rules_as_string) -
                                                                  1], "\\d+"))
      i <- 1
      std_rules <- rep("", number_of_rules)
      while (i <= number_of_rules) {
        std_rules[i] <- str_replace(rules_as_string[i+3], "and", "&")
        i <- i + 1
      }
      std_rules <- std_rules[str_detect(std_rules, "=KO")]
    } # if (a == "JRip")
  
   if (a == "PART") {
      number_of_rules <- str_extract(rules_as_string[length(rules_as_string)-1], "\\d+")
      str_i <- 4
      rule_i <- 1
      std_rules <- rep("", number_of_rules)
      while (str_i <= (length(rules_as_string)-3)) {
        if (rules_as_string[str_i] == "") {
          rule_i <- rule_i + 1  
        } else {
          std_rules[rule_i] <- 
            str_c(std_rules[rule_i], 
                  str_replace(rules_as_string[str_i], "AND", "&"), 
                  " ") 
        }
        str_i <- str_i+1
      }
      std_rules <- std_rules[str_detect(std_rules, ": KO")]
    } # if (a == "PART")
    support <- round(
      as.numeric(str_extract(std_rules, "\\d+"))*100/nrow(jhipster_df),
      2
    )
    if (a == "JRip") {
       std_rules <- str_replace_all(std_rules, "\\s+=>.*", "")
    }
    if (a == "PART") {
      std_rules <- str_replace_all(std_rules, ":\\s+KO .*", "")
    }
    coverage <- round(support/KO_PERCENTAGE, 4)*100
    interactions <- str_count(std_rules, "&") + 1
    std_rules_df <- data.frame(rule = std_rules, interactions = interactions, support = support, coverage = coverage)
    std_rules_df <- std_rules_df %>% arrange(desc(coverage))
    write.table(
      std_rules_df,
      str_c(RULES_DIR, a, "StdRulesJHipster.csv"),
      row.names = FALSE,
      sep = "; "
    )
  } # if (a %in% c("JRip", "PART"))

  prediction <- predict(rules, jhipster_df)
  performance <- c("================================================",
                   str_c(" ", a, "'s performance on JHipster"),
                   "================================================")
  performance <- c(performance,
                   capture.output(
                     CrossTable(jhipster_df$Build, prediction,
                                prop.chisq = FALSE, prop.c = TRUE, prop.r = TRUE,
                                dnn = c('actual', 'predicted')
                     )
                   )
  )
  performance <- c(performance,
                   capture.output(
                     confusionMatrix(jhipster_df$Build, prediction, positive="KO")
                   )
  )
  write(performance, 
        str_c(STATISTICS_DIR, a, "PerformanceJHipster.txt"))

} # for (a in RWekalgorithms)


