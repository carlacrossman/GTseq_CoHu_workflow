log <- file(snakemake@log[["LOG"]], open = "wt")

sink(log, type = "message")

if(require("dplyr")){
    print("dplyr is loaded correctly")
  } else {
    print("trying to install dplyr")
    install.packages("dplyr")
    if(require(dplyr)){
        print("dplyr installed and loaded")
      } else {
        stop("could not install dplyr")
        }
    }
if(require("tidyr")){
    print("tidyr is loaded correctly")
  } else {
    print("trying to install tidyr")
    install.packages("tidyr")
    if(require(tidyr)){
        print("tidyr installed and loaded")
      } else {
        stop("could not install tidyr")
        }
    }

source("scripts/mitotyping.R")

# Load_data
file <- read.table(snakemake@input[["DEPTH"]], comment.char = "", header = TRUE)

GT_long <- file %>% 
  select(POS = X.POS, REF, ALT, contains("GT")) %>%
  pivot_longer(cols = contains("GT"), names_to = "Sample", values_to = "Genotype") %>%
  separate_wider_delim(Sample, delim = ".", names = c(NA, "Sample", NA, NA, NA))

AD_long <- file %>% 
  select(POS = X.POS, REF, ALT, contains("AD")) %>%
  pivot_longer(cols = contains("AD"), names_to = "Sample", values_to = "AD") %>%
  separate_wider_delim(cols = AD, delim = ",", names = c("AD1", "AD2"), too_few = "align_start") %>%
  separate_wider_delim(Sample, delim = ".", names = c(NA, "Sample", NA, NA, NA)) %>%
  mutate(AD1 = as.numeric(AD1), AD2 = as.numeric(AD2)) %>%
  mutate(AD = ifelse(AD2 == 0 | is.na(AD2) | is.na(AD1) , NA, AD1 / AD2))

full_long <- full_join(GT_long, AD_long, by = c("POS", "REF", "ALT", "Sample"))
write.csv(full_long, snakemake@output[["DEPTH"]], row.names = FALSE, quote = FALSE)

output <- mitotyping(full_long)

write.csv(output, snakemake@output[["HAPLOTYPE"]], row.names = FALSE, quote = FALSE)
