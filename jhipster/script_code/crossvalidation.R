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
# The script performs a 10-Fold crossvalidation of the algorithms LEM2, CN2, and AQ
# to induce the rules that explain the detected faults.
#
# Also, the script generates a box-plot that summarizes the results.
#############################################################################################

library(tidyverse)
library(RoughSets)

# Input CSV file 
JHIPSTER_FILE <- "../original_data/jhipster3.6.1-testresults.csv"
# Directory where crossvalidation results will be generated
STATISTICS_DIR <- "../rule_statistics/"

set.seed(123)
NFOLDS <- 10

# Import data in a data.frame
df <- read.csv(JHIPSTER_FILE, sep = "," ) %>%  
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

# Randomly shuffle the data
df<-df[sample(nrow(df)),]

# Create NFOLDS equally size folds
folds <- cut(seq(1,nrow(df)),breaks=NFOLDS,labels=FALSE)

error_rates_LEM2 <- rep(NA, NFOLDS)
error_rates_CN2 <- rep(NA, NFOLDS)
error_rates_AQ <- rep(NA, NFOLDS)

#Perform NFOLDS fold cross validation
for(i in 1:NFOLDS){
  
  writeLines(str_c("Fold ", i))
  
  #Segment data by fold using the which() function 
  test_indices <- which(folds==i,arr.ind=TRUE)
  test_df <- df[test_indices, ]
  train_df <- df[-test_indices, ]
  
  test_dt <- SF.asDecisionTable(
    test_df,
    decision.attr = ncol(df),
    indx.nominal = 1:ncol(df)
  ) 
  
  train_dt <- SF.asDecisionTable(
    train_df,
    decision.attr = ncol(df),
    indx.nominal = 1:ncol(df)
  ) 
  
  writeLines("  LEM2")
  rules <- RI.LEM2Rules.RST(train_dt)
  predicted_vals <- predict(rules, test_dt)
  error_rates_LEM2[i] <- mean(test_dt[[ncol(df)]] != predicted_vals$predictions)
  
  writeLines("  CN2")
  rules <- RI.CN2Rules.RST(train_dt, K=5)
  predicted_vals <- predict(rules, test_dt)
  error_rates_CN2[i] <- mean(test_dt[[ncol(df)]] != predicted_vals$predictions)
  
  writeLines("  AQ")
  rules <- RI.AQRules.RST(train_dt)  
  predicted_vals <- predict(rules, test_dt)
  error_rates_AQ[i] <- mean(test_dt[[ncol(df)]] != predicted_vals$predictions)
}

error_rate_LEM2 <- mean(error_rates_LEM2)
error_rate_CN2 <- mean(error_rates_CN2)
error_rate_AQ <- mean(error_rates_AQ)

error_rate_df <- tibble(
  algorithm = c("LEM2", "CN2", "AQ"),
  rate = c(error_rate_LEM2, error_rate_CN2, error_rate_AQ)
)
write.table(error_rate_df, 
            str_c(STATISTICS_DIR, "error_rate.csv"), 
            sep="; ", row.names = FALSE)

accuracy_df <- tibble(
  accuracy=c(1-error_rates_LEM2, 1-error_rates_CN2, 1-error_rates_AQ),
  algorithm=c(rep("LEM2", NFOLDS), rep("CN2", NFOLDS), rep("AQ", NFOLDS))
)
write.table(accuracy_df, 
            str_c(STATISTICS_DIR, "accuracy.csv"), 
            sep="; ", row.names = FALSE)

cairo_pdf(str_c(STATISTICS_DIR, "CrossvalidationAccuracy.pdf"), 
          width=3.5, height=2) 
ggplot(accuracy_df, 
       aes(x=reorder(algorithm, accuracy, FUN=median), 
           y=accuracy)) +
  scale_fill_manual(values=c("darkviolet", "goldenrod2", "mediumseagreen")) +
  geom_boxplot(aes(fill=algorithm), alpha=0.6) +
  scale_x_discrete("Rule induction\nalgorithm") +
  scale_y_continuous("Accuracy", seq(0.95,0.975,by=0.0025)) +
  theme(axis.text.x = element_text (angle=60, hjust=1), 
        legend.title = element_text(size=13),
        legend.text = element_text(size=12)) +
  guides(fill=FALSE) +
  coord_flip()
dev.off()  
