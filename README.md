## Snakemake workflow to analysze GT-Seq panel for Atlantic Whitefish ##
*Updated April 21, 2026 by Carla Crossman*  
  
  
**Under development**
Currently optimized for 364 loci (including 350 nuclear sites and 14 mitochondrial loci). This panel is undergoing iterative improvements. As the panel changes, a few tweaks will need to be made to the input files 
  
**Background**
The GT-Seq panel was developed using SNPs identified with low coverage whole genome sequence data originally obtained to call mitotypes. These SNPs were filtered to select variable sites that would be informative for ongoing diversity monitoring. Primers were designed and optimized using Primer3 and mfeprimer. Additional primers were designed to capture the known variant sites in the mitochondrial genome. 
  
At least one mitochondrial position seems to display evidence of heteroplasmy. To properly call this heteroplasmy, we separate the genomic and mitochondrial analysis in this pipeline. The output files for the mitochondrial data are therefore haplotype calls, as well as allelic depth data for individuals at each poistion that will enable threshold calling for heteroplamic haplotypes. 
  
**Overview**
  
The snakemake workflow takes raw sequemce data and merges pair-end reads for each sample. Genotypes are called with the GTSeq pipeline (Campbell et. al 2014; scripts available at github.com/GTseq/GTseq-Pipeline). Paired reads are also mapped against the indexed reference sequence of the mitogenome. The 'genotypes' for the known variant sites in the mitogenome are called as if they are diploid and reformatted in R to identify mitotypes and provide allele depth data to support heteroplasmic calls.
  
![Fig1_workflow](https://github.com/carlacrossman/GTseq_CoHu_workflow/blob/main/GTseq_CoHu_rulegraph.png)
  
**System Requirements**
  
Snakemake is built and run in python. Remember version control of python and the associated python environments is essential. This workflow should work with different versions of python, but you will need to be consisent in the python environment you are using. Below are the system requirements needed to run the workflow on the Digital Alliance Infrastructure.  
  
- Python (I used python/3.11.5)
- snakemake (This can be installed on the alliance clusters as a python wheel with pip. This only needs to be done once.)
- Perl (I used perl/5.36.1)
- R (I used r/4.5.0)
- R libraries dplyr and tidyr
  
The following modules will be installed inside the shell as part of the pipeline:
- fastp/1.0.1 
- bwa/0.7.18 
- samtools/1.22.1 
- bcftools/1.22 
  
Notes:  
- You will need to create and activate a python environment. See https://docs.alliancecan.ca/wiki/Python for more information on python
- After loading Perl you will need the Approx module. It can be installed by typing ```cpan```, then running ```install String::Approx```(this only needs to be done once).
- The R portion of the workflow is set to install the necessarily R libraries if they are not installed. However, compute nodes (including interactive nodes) on the Digital Alliance system do not have access to the internet so they will not be able to be installed.  
  
**File System Requirements**  

The directory housing the snakemake workflow should be set up in a consistent matter and contain the files listed below:  

- GTSeq_CoHu_workflow
    - data
        - samples.txt (a list of sample names)
        - raw fastq files (renamed to: {SAMPLE}_R1.fastq.gz, {SAMPLE}_R2.fastq.gz etc.)
    - intermediate_files
    - results
    - logs
    - scripts
        - compile_haplotypes.R
        - mitotyping.R
    - dependency_files
        - 364_sites_genotyper_input.csv
        - 364_sites_Seqtest.txt
        - CoHu_mtdna_haplotype_XII.fasta
        - CoHu_mtdna_haplotype_XII.fasta.fai
        - CoHu_mtdna_haplotype_XII.fasta.pac
        - CoHu_mtdna_haplotype_XII.fasta.sa
        - CoHu_mtdna_haplotype_XII.fasta.bwt
        - CoHu_mtdna_haplotype_XII.fasta.ann
        - CoHu_mtdna_haplotype_XII.fasta.amb
        - GTseq_HashSeqs.pl
        - GTseq_SeqTest.pl
        - GTseq_Genotyper_v3.pl
        - GTseq_GenoCompile_v3.pl          
        - GTseq_ErrorReport_v3.pl            
        - site_depth 
    - GTseq_CoHu_workflow.smk
    - GTseq_CoHu_rulegraph.png
    - README.md
  
Notes:   
- If you have a negative control that will be analyzed alongside everything, it needs to be omitted from the GTSeq Compile steps. This will be done automatically if the sample name begins with "neg".  
First begin by cloning this repository and setting up the additional required directories:  
``` bash
git clone https://github.com/carlacrossman/GTseq_CoHu_workflow.git

cd GTseq_CoHu_workflow

mkdir data
mkdir intermediate_files
mkdir results
mkdir logs
```

**Running Instructions** 
  
The workflow runs very quickly on the panel (<5 mins for 12 samples). I have been running it on an interactive node with 4 threads and -mem 8000M. One command will require 4 threads (bwa). This is currently hard-coded, but could be adjusted if needed. Always remember to go through a dry run before running the pipepline. It is also a good idea to test on a couple samples first to verify each step works.  

The following are the exact steps I take to run the workflow:  
```
# Load necessary modules
module load python/3.11.5 perl/5.36.1 r/4.5.0

# Login to an interactive node
salloc --time=1:00:0 --mem-per-cpu=8000M --ntasks=4 --account={INSERT def- ACCOUNT NAME HERE}

# Activate python environment
source ~/links/scratch/ENV/bin/activate

# In the main directory run:
snakemake -s GTseq_CoHu_workflow.sh --dryrun

# If the dry run looks good, run:
snakemake -j 4 -s GTseq_CoHu_workflow.sh
```

**Output**

Four output files should be generated in the results/ directory.  

- results
    - allelic_depth_per_ind.csv
    - CoHu_gtseq_compile
    - CoHu_gtseq_compile_counts
    - haplotype_table_depth.csv
  
At present the site 16716 is omitted from the final output files as there were problems with its amplifcaiton. We will fix this moving forward.