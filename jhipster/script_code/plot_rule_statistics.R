#############################################################################################
# This script's input are the rules induced with the induce_rules.r script.
# For each rules' file, the script generates the following plots:
#
# * A histogram and a box-plot analyzing feature interactions.
# * A cumulative plot relating the rules's coverage achieved with the interactions factor.
# * A histogram showing rules' coverage .
#############################################################################################

library(tidyverse)
library(Cairo)
library(gridExtra)
library(scales)

# Directory where rules were generated
RULES_DIR <- "../induced_rules/"
# Directory where plots will be generated
STATISTICS_DIR <- "../rule_statistics/"

algorithms <- c("LEM2", "CN2", "AQ", "JRip", "PART")

for (a in algorithms) {
  data <- read.csv(str_c(RULES_DIR, a, "StdRulesJHipster.csv"), sep=";") 

  #############################################################################################
  # Analyzing feature interactions
  #############################################################################################
  
  histogram_plot <- ggplot(data, aes(x=interactions)) +
    geom_histogram(col="seagreen", fill="mediumseagreen", 
                   alpha=0.4, bins=12, size=0.08,
                   aes(y = stat(width*density)*100)) +
    theme(axis.text.x = element_text (angle=60, hjust=1), 
          legend.title = element_text(size=13),
          legend.text = element_text(size=12)) + 
    scale_x_continuous("#Feature interactions (t)") +
    scale_y_continuous("%Rules") 
  
  boxplot <- ggplot(data, aes(x=interactions, y=coverage, group=interactions) ) +
    geom_boxplot(fill="mediumseagreen", col="seagreen", 
                 size=0.08,
                 alpha=0.4) +
    theme(axis.text.x = element_text (angle=60, hjust=1), 
          legend.title = element_text(size=13),
          legend.text = element_text(size=12)) + 
    scale_x_continuous("#Feature interactions (t)") +
    scale_y_continuous("%Coverage") 
    
  cairo_pdf(str_c(STATISTICS_DIR, "FeatureInteractions", a, ".pdf"),
                  width=3.5, height=3)
  grid.arrange(histogram_plot, boxplot,
               nrow=2)
  dev.off()
  #Sys.sleep(2)

  #############################################################################################
  # Analyzing the coverage achieved according to the interactions factor
  #############################################################################################  
  
  cumulative <- data  %>%
    group_by(interactions) %>%
    summarize(perc = sum(coverage))
  cumulative$acc_perc <- cumsum(cumulative$perc)
  cumulative_plot <- ggplot(cumulative, aes(x=interactions, y=acc_perc)) +
    geom_point(col="mediumseagreen", size=2) +
    geom_area(fill="mediumseagreen", col="mediumseagreen", alpha=0.4) +
    theme(axis.text.x = element_text (angle=60, hjust=1), 
          legend.title = element_text(size=13),
          legend.text = element_text(size=12)) + 
    scale_x_continuous("#Feature interactions (t)") +
    scale_y_continuous("Cumulative %coverage\n(some rules overlap)") 
  ggsave(str_c(STATISTICS_DIR, "CumulativeCoverage", a, ".pdf"),
         cumulative_plot,
         device="pdf",
         width=3.5, height=2)

  #############################################################################################
  # Analyzing the rules' coverage 
  ############################################################################################# 
  
  rules_coverage_plot <- ggplot(data, aes(x=coverage)) +
    geom_histogram(col="seagreen", fill="mediumseagreen",
                   alpha=0.4, bins = 23, size=0.07,
                   aes(y = stat(width*density)*100)) +
    theme(axis.text.x = element_text (angle=60, hjust=1), 
          legend.title = element_text(size=13),
          legend.text = element_text(size=12)) + 
    scale_x_continuous("%Coverage") +
    scale_y_continuous("%Rules") 
  ggsave(str_c(STATISTICS_DIR, "RulesCoverage", a, ".pdf"),
         rules_coverage_plot,
         device="pdf",
         width=3.5, height=1.5)
  
} #for (a in algorithms)





