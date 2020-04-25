#############################################################################################
# This script's input is a directory containing formatted CSV files, each one describing test
# cases for a configuration model. Using the LEM2 algorithm, it induces the rules that
# explain the faults detected in the test cases.
#############################################################################################

library(tidyverse)
library(RoughSets)
library(rlang)
library(RWeka)
library(gmodels)
library(caret)
library(vcd)
library(psych)
library(rapport)

# Directory storing the CSV files
DATA_DIR <- "../formatted_data/"
# Directory where rules will be generated
RULES_DIR <- "../induced_rules/"
# Directory where the performance of induction rule algorithms is saved
STATISTICS_DIR <- "../rule_statistics/"

# If DISCARD_MODELS == TRUE, with MAX_KOS_PERCENTAGE you can set
# the maximum percentage of KOs allowed; below this percentage
# the model test cases are rejected
DISCARD_MODELS <- FALSE
MAX_KOS_PERCENTAGE <- 50

model_files <- list.files(DATA_DIR)
for (f in model_files) {
  model <- unlist(str_split(f, ".csv"))[1]
  writeLines(str_c("* Proccessing ", model))
  
  test_cases_df <- read.csv(str_c(DATA_DIR, f),
                            sep = ";",
                            stringsAsFactors = TRUE)
  
  TOTAL_CASES <- nrow(test_cases_df)
  KO_PERCENTAGE <- (sum(test_cases_df$test=="KO")/TOTAL_CASES)*100
  
  ###################################################################
  # RoughSets #######################################################
  ###################################################################
  
  test_cases_dt <- SF.asDecisionTable(
    test_cases_df,
    decision.attr = ncol(test_cases_df),
    indx.nominal = 1:ncol(test_cases_df)
  )
  
  writeLines(str_c("  Features = ", ncol(test_cases_df) - 1))
  writeLines(str_c("  Configurations = ", TOTAL_CASES))
  
  kos <- test_cases_df[, ncol(test_cases_df)] == "KO"
  kos_percentage <- sum(kos) * 100 / nrow(test_cases_df)
  writeLines(str_c("  ", round(kos_percentage, 2),  " % of all tests are KO"))
  if (kos_percentage > MAX_KOS_PERCENTAGE & DISCARD_MODELS) {
    writeLines(str_c("  No rules are generated"))
    next()
  }
  
  
  RoughSets_algorithms <- c("LEM2", "CN2", "AQ")
  
  for (a in RoughSets_algorithms) {
    writeLines(str_c("  Inducing rules with ", a))
    rules <- eval(parse_expr(str_c("RI.",a,"Rules.RST(test_cases_dt)")))
    
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
    
    ko_rules_df$support <- round(ko_rules_df$support*100/TOTAL_CASES, 2)
    ko_rules_df <- ko_rules_df %>% arrange(desc(support))
    ko_rules_df$coverage <- round(ko_rules_df$support/KO_PERCENTAGE, 4)*100
    
    write.table(
      ko_rules_df,
      str_c(RULES_DIR, a, "StdRules", model, ".csv"),
      row.names = FALSE,
      sep = "; "
    )
    
    prediction <- predict(rules, test_cases_dt)
    performance <- c("================================================",
                     str_c(" ", a, "'s performance on ", model),
                     "================================================")
    performance <- c(performance,
                     capture.output(
                       CrossTable(test_cases_df$test, prediction$predictions,
                                  prop.chisq = FALSE, prop.c = TRUE, prop.r = TRUE,
                                  dnn = c('actual', 'predicted')
                       )
                     )
    )
    performance <- c(performance,
                     capture.output(
                       confusionMatrix(test_cases_df$test, 
                                       prediction$predictions, 
                                       positive="KO")
                     )
    )  
    write(performance, 
          str_c(STATISTICS_DIR, a, "Performance", model, ".txt"))
  }
  
  ###################################################################
  # RWeka ###########################################################
  ###################################################################
  
  RWekalgorithms <- c("OneR", "JRip", "PART")
  
  for (a in RWekalgorithms) {
    writeLines(str_c("  Inducing rules with ", a))
    if (a == "JRip" & TOTAL_CASES <=2) { 
      writeLines("  JRIP requires at least 3 configurations")
      next() 
    }
    
    rules <-
      eval(parse_expr(str_c(a, "(test ~ ., data = test_cases_df)")))
    rules_as_string <- capture.output(rules)
    write(rules_as_string,
          str_c(RULES_DIR, a, "RulesOriginalOn", model, ".txt"))
    
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
        number_of_rules <-
          str_extract(rules_as_string[length(rules_as_string) - 1], "\\d+")
        str_i <- 4
        rule_i <- 1
        std_rules <- rep("", number_of_rules)
        while (str_i <= (length(rules_as_string) - 3)) {
          if (rules_as_string[str_i] == "") {
            rule_i <- rule_i + 1
          } else {
            std_rules[rule_i] <-
              str_c(std_rules[rule_i],
                    str_replace(rules_as_string[str_i], "AND", "&"),
                    " ")
          }
          str_i <- str_i + 1
        }
        std_rules <- std_rules[str_detect(std_rules, ": KO")]
      } # if (a == "PART")
      support <- round(as.numeric(str_extract(std_rules, "\\d+")) * 100 /
                         nrow(test_cases_df),
                       2)
      if (a == "JRip") {
        std_rules <- str_replace_all(std_rules, "\\s+=>.*", "")
      }
      if (a == "PART") {
        std_rules <- str_replace_all(std_rules, ":\\s+KO .*", "")
      }
      coverage <- round(support / KO_PERCENTAGE, 4) * 100
      interactions <- str_count(std_rules, "&") + 1
      std_rules_df <-
        data.frame(
          rule = std_rules,
          interactions = interactions,
          support = support,
          coverage = coverage
        )
      std_rules_df <- std_rules_df %>% arrange(desc(coverage))
      write.table(
        std_rules_df,
        str_c(RULES_DIR, a, "StdRules", model, ".csv"),
        row.names = FALSE,
        sep = "; "
      )
    } # if (a %in% c("JRip", "PART"))
    
    prediction <- predict(rules, test_cases_df)
    performance <-
      c(
        "================================================",
        str_c(" ", a, "'s performance on ", model),
        "================================================"
      )
    performance <- c(performance,
                     capture.output(
                       CrossTable(
                         test_cases_df$test,
                         prediction,
                         prop.chisq = FALSE,
                         prop.c = TRUE,
                         prop.r = TRUE,
                         dnn = c('actual', 'predicted')
                       )
                     ))
    performance <- c(performance,
                     capture.output(
                       confusionMatrix(test_cases_df$test, prediction, positive = "KO")
                     ))
    write(performance,
          str_c(STATISTICS_DIR, a, "Performance", model, ".txt"))
    
  } # for (a in RWekalgorithms)
  
  
}
