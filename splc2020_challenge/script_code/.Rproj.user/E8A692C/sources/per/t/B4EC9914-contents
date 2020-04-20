#############################################################################################
# In the original SPLC'2020 challenge, data is sparsed in several files stored in directories 
# "failuresFound" and "workspace_IncLing/Tools/All_valid_conf/".
# This script formats that data into .csv files, one per model.
#############################################################################################

library(tidyverse)
library(stringr)
library(testit)

# Directories where data is originally stored
FAILURES_DIR <- "../original_data/failuresFound/"
ALL_CONFS_DIR <- "../original_data/workspace_IncLing/Tools/All_valid_conf/"

# Directory that will contain the formatted data
OUTPUT_DIR <- "../formatted_data/"

model_files <- list.files(FAILURES_DIR)
for (f in model_files) {
  model <- unlist(str_split(f, ".csv"))[1]
  writeLines(str_c("* Proccessing ", model))
  
  # < Get failures > ####################################################
  
  failures <- read.csv(
    str_c(FAILURES_DIR, f),
    sep=",",
    stringsAsFactors = FALSE
  )
  if (nrow(failures) == 0) {
    writeLines(str_c("    ", model, " has no failures"))
    next()
  }
  failures <- failures$configuration
  failures <- str_replace_all(failures, "true", "TRUE")
  failures <- str_replace_all(failures, "false", "FALSE")
  failures <- str_extract_all(failures, "[A-Za-z0-9_]+:(TRUE|FALSE)")
  
  pairs <- str_split(failures[[1]], ":")
  v <- unlist(pairs)
  m <- matrix(v, nrow=length(v)/2, ncol=2, byrow=TRUE)
  m <- t(m)
  df_failures <- data.frame(m) 
  colnames(df_failures) <- unlist(df_failures[1,])
  df_failures <- df_failures[-1,]
  for (j in 2:length(failures)) {
    pairs <- str_split(failures[[j]], ":")
    v <- unlist(pairs)
    m <- matrix(v, nrow=length(v)/2, ncol=2, byrow=TRUE)
    m <- t(m)
    df_aux <- data.frame(m) 
    colnames(df_aux) <- unlist(df_aux[1,])
    df_aux <- df_aux[-1,]
    df_failures <- union(df_failures, df_aux)
  }
  for (j in 1:length(colnames(df_failures))) {
    df_failures[,j] <- as.logical(df_failures[,j])
  }
  
  # < Get all configurations > ####################################################
  
  model_confs_dir <- str_c(ALL_CONFS_DIR, model, "/products/")
  configs <- list.files(model_confs_dir, 
                        pattern = "[.]config$",
                        recursive=TRUE)
  df_configs <- df_failures[FALSE,]
  cnames <- colnames(df_configs)
  for (j in 1:length(configs)) {
    if ( !has_error(read.table(str_c(model_confs_dir, configs[j]))) ) {
      c <- read.table(str_c(model_confs_dir, configs[j])) 
      v <- cnames %in% c[,1] 
      #v[length(v)] <- "OK"
      df_configs <- rbind(df_configs, v)
      colnames(df_configs) <- cnames
    } else { # all features are unselected
      v <- rep(FALSE, length(cnames))
      #v[length(v)] <- "OK"
      df_configs <- rbind(df_configs, v)
      colnames(df_configs) <- cnames
    }
  }    
  df_configs <- anti_join(df_configs, df_failures)
  
  df_configs$test<- rep("OK", nrow(df_configs))
  df_failures$test <- rep("KO", nrow(df_failures))
  df <- union(df_configs, df_failures)

  write.table(df,
              str_c(OUTPUT_DIR, model, ".csv"),
              sep=";",
              row.names = FALSE)  
}
