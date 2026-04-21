mitotyping <- function(datafile){
  # Check headers are correct, else return error/warning message
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

  # known haplotypes as data frames
  POS <- as.integer(c(1044, 1133, 1895, 2304, 2503, 3477, 3768, 8302,  9924,  9951, 14013, 16382, 16716))
  I <- c("T/T", "T/T", "C/C", "G/G", "G/G", "A/A", "A/A", "G/G", "G/G", "A/A", "T/T", "A/A", "G/G")
  II <- c("T/T", "T/T", "C/C", "G/G", "G/G", "G/G", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "G/G")
  III <- c("T/T", "T/T", "C/C", "A/A", "G/G", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "G/G")
  IV <- c("T/T", "T/T", "C/C", "G/G", "A/A", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "G/G")
  V <- c("T/T", "T/T", "C/C", "G/G", "G/G", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "A/A")
  VI <- c("C/C", "T/T", "C/C", "G/G", "G/G", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "G/G")
  VII <- c("T/T", "C/C", "C/C", "G/G", "G/G", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "G/G")
  VIII <- c("T/T", "T/T", "C/C", "G/G", "G/G", "A/A", "G/G", "G/G", "A/A", "G/G", "C/C", "A/A", "G/G")
  IX <- c("T/T", "T/T", "C/C", "G/G", "G/G", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "G/G", "G/G")
  X <- c("T/T", "T/T", "C/C", "G/G", "G/G", "A/A", "G/G", "A/A", "G/G", "G/G", "T/T", "A/A", "G/G")
  XI <- c("T/T", "T/T", "C/C", "G/G", "G/G", "A/A", "G/G", "G/G", "A/A", "G/G", "T/T", "A/A", "G/G")
  XII <- c("T/T", "T/T", "C/C", "G/G", "G/G", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "G/G")
  XIII <- c("T/T", "T/T", "T/T", "G/G", "G/G", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "G/G")
  heteroplasmy <- c("T/T", "T/T", "C/C", "G/G", "G/A", "A/A", "G/G", "G/G", "G/G", "G/G", "T/T", "A/A", "G/G")
  haplotypes <- data.frame(POS, I, II, III, IV, V, VI, VII, VIII, IX, X, XI, XII, XIII, heteroplasmy)
  haplotypes<-haplotypes %>% filter(POS != 16716) %>% select(-V)
  outfile <- data.frame(Sample = character(), haplotype = character(), stringsAsFactors=FALSE)
  counter = 1
  for (i in unique(datafile$Sample)){
    subset_genotypes <- datafile %>% filter(Sample == i) %>% select(POS, Genotype, AD)
    if(any(subset_genotypes$Genotype %in% "./.")){
      outfile[counter,] <- c(i, "MISSING")} else 
      if (nrow(subset_genotypes %>% filter(AD > 0.1 & AD < 10)) > 0){
      outfile[counter,] <- c(i, "CHECK FOR HET")} else 
      if (identical(subset_genotypes$POS, haplotypes$POS)){
       hap <- names(haplotypes)[which(sapply(haplotypes, identical, y = subset_genotypes$Genotype))]
       if(length(hap) == 0) {outfile[counter,] <- c(i, "NO MATCH")} else {
                             outfile[counter,] <- c(i, hap)}
                             } 
        else {outfile[counter,] <- c(i, "ERROR")
              }
    counter <- counter+1
  }
return(outfile)
}
