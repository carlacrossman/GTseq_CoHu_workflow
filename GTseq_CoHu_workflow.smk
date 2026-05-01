SAMPLE = []
with open("data/samples.txt", "r") as f:
	SAMPLE = [line.strip() for line in f.readlines()]

rule all:
	input:
		A="results/CoHu_gtseq_compile",
		B="results/CoHu_gtseq_compile_counts",
		C="results/haplotype_table_depth.csv",
		D="results/allelic_depth_per_ind.csv"

rule merge_reads:
	input:
		R1="data/{SAMPLE}_R1.fastq.gz",
		R2="data/{SAMPLE}_R2.fastq.gz"
	output: 
		MERGED="intermediate_files/{SAMPLE}-merge.fq",
		UNMERGEDR1="intermediate_files/{SAMPLE}-unmergedR1.fq",
		UNMERGEDR2="intermediate_files/{SAMPLE}-unmergedR2.fq",
		HTML="intermediate_files/{SAMPLE}.html"
	log: "logs/fastp_{SAMPLE}_log.txt"
	shell:
		"""
		module load fastp/1.0.1

		fastp --detect_adapter_for_pe --merge --merged_out {output.MERGED} --out1 {output.UNMERGEDR1} --out2 {output.UNMERGEDR2} --correction --dont_eval_duplication --average_qual 30 --trim_poly_g --trim_poly_x --html {output.HTML} -l 80 --in1 {input.R1} --in2 {input.R2} 2> {log}
		"""

rule GTSEQ_individuals: 
	input: "intermediate_files/{SAMPLE}-merge.fq"
	output: 
		GENOS="{SAMPLE}.genos",
		SEQTEST="intermediate_files/{SAMPLE}.seqtest.csv",
		HASH="intermediate_files/{SAMPLE}.hash"
	shell:
		"""
		perl dependency_files/GTseq_HashSeqs.pl {input} > {output.HASH}
		perl dependency_files/GTseq_SeqTest.pl dependency_files/364_sites_Seqtest.txt {output.HASH} > {output.SEQTEST}
		perl dependency_files/GTseq_Genotyper_v3.pl dependency_files/364_sites_genotyper_input.csv {input} > {output.GENOS}
		"""

rule GTSEQ_compile:
	input:
		expand("{sample}.genos", sample = SAMPLE)
	output: 
		GT="results/CoHu_gtseq_compile",
		COUNTS="results/CoHu_gtseq_compile_counts",
		LOG="logs/ErrorReport_CoHu_gtseq"
	shell:
		"""
		mv neg*.genos intermediate_files/ || true
		perl dependency_files/GTseq_GenoCompile_v3.pl S > {output.GT}
		perl dependency_files/GTseq_GenoCompile_v3.pl C > {output.COUNTS}
		perl dependency_files/GTseq_ErrorReport_v3.pl dependency_files/364_sites_genotyper_input.csv > {output.LOG}
		mv *.genos intermediate_files/
		"""

rule mapping_mtdna:
    input:
        REFERENCE="dependency_files/CoHu_mtdna_haplotype_XII.fasta",
        MERGED="intermediate_files/{SAMPLE}-merge.fq"
    output: 
        BAM="intermediate_files/{SAMPLE}-mtdna.bam"
    log:
        "logs/mapping_mtdna-{SAMPLE}-log.txt"
    shell:
        """
	module load bwa/0.7.18 samtools/1.22.1

	bwa mem -M -t 4 \
	    {input.REFERENCE} \
	    {input.MERGED} | samtools view -h -F 4 | samtools sort -o {output.BAM} 2> {log}
	
	samtools index {output.BAM}
        """

rule haplotype_calling:
    input:
        REFERENCE="dependency_files/CoHu_mtdna_haplotype_XII.fasta",
	BAM=expand("intermediate_files/{sample}-mtdna.bam", sample = SAMPLE)

    output: 
        DEPTH="intermediate_files/mitotyping_allele_depth"
    log:
        "logs/haplotype_calling_mtdna_log.txt"
    shell:
        """
	module load bcftools/1.22

	ls intermediate_files/*mtdna.bam > dependency_files/mtdna_bam_files

	bcftools mpileup -f {input.REFERENCE} -b dependency_files/mtdna_bam_files -R dependency_files/site_depth -d 100000 | bcftools call -m | bcftools query -H -f '%POS\t%REF\t%ALT[\t%TGT\t%AD]\n' > {output.DEPTH} 2> {log}

	sed -i '1s,\[[0-9]\+\],,g' {output.DEPTH}
	"""

rule mtdna_haplotype_outputs:
    input:
        DEPTH="intermediate_files/mitotyping_allele_depth"
    output: 
        HAPLOTYPE="results/haplotype_table_depth.csv",
        DEPTH="results/allelic_depth_per_ind.csv"
    log:
        LOG="logs/mtdna_R_haplotype_log.txt"
    script:
        "scripts/compile_haplotypes.R"
