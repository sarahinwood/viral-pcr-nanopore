#!/usr/bin/env python3

import snakemake
from pathlib import Path

#############
# FUNCTIONS #
#############

## use to generate list of file paths from guppy output for next rule input
def get_sample_reads(wildcards):
    my_output = checkpoints.guppy_basecalling.get(sample=wildcards.sample, pcr=wildcards.pcr).output['basecalling_out']
    fastq_path = Path(my_output, '{read}.fastq.gz')
    ##generate list of all file paths from files that were output from checkpoint step
    my_reads = snakemake.io.glob_wildcards(fastq_path).read
    return(expand(fastq_path, read=my_reads))

###########
# GLOBALS #
###########

guppy_container = 'shub://TomHarrop/ont-containers:guppy-cpu_4.2.2'
minimap2_container = 'shub://TomHarrop/singularity-containers:minimap2_2.11r797'
samtools_container = 'shub://TomHarrop/singularity-containers:samtools_1.9'
tidyverse_container = 'shub://TomHarrop/singularity-containers:r_3.5.0'

#########
# RULES #
#########

rule target:
    input:
        expand('output/samtools_coverage/{sample}_{pcr}_depth.out', sample=['hyp'], pcr=['bro']),
        expand('output/samtools/{sample}_{pcr}_sorted.bam.bai', sample=['hyp'], pcr=['bro'])

##include -a option - to print all positions even if depth = 0
rule samtools_coverage:
    input:
        sorted_bam = 'output/samtools/{sample}_{pcr}_sorted.bam'
    output:
        depth_out = 'output/samtools_coverage/{sample}_{pcr}_depth.out'
    log:
        'output/logs/samtools_coverage/{sample}_{pcr}.log'
    threads:
        20
    singularity:
        samtools_container
    shell:
        'samtools coverage '
        '{input.sorted_bam} '
        '-o {output.depth_out} '
        '2> {log}'

rule samtools_index:
    input:
        sam = 'output/samtools/{sample}_{pcr}_sorted.bam'
    output:
        index = 'output/samtools/{sample}_{pcr}_sorted.bam.bai'
    log:
        'output/logs/samtools_index/{sample}_{pcr}.log'
    threads:
        20
    singularity:
        samtools_container
    shell:
        'samtools index '
        '{input.sam} '
        '2> {log}'

rule samtools_sort:
    input:
        sam = 'output/minimap2/{sample}_{pcr}.sam'
    output:
        sorted_bam = 'output/samtools/{sample}_{pcr}_sorted.bam'
    log:
        'output/logs/samtools_sort/{sample}_{pcr}.log'
    threads:
        20
    singularity:
        samtools_container
    shell:
        'samtools sort '
        '{input.sam} '
        '-o {output.sorted_bam} '
        '2> {log}'

##map-ont is set of defaults for nanopore sequensing
##-a outputs in sam format instead of default
##need to specify genome first, them reads to be mapped?
rule minimap2:
    input:
        fastq = 'output/joined/{sample}_{pcr}_joined.fastq.gz',
        genome = 'data/Mhyp_hic_assembly.fasta'
    output:
        sam = 'output/minimap2/{sample}_{pcr}.sam'
    threads:
        10
    singularity:
        minimap2_container
    log:
        'output/logs/minimap/{sample}_{pcr}.log'
    shell:
        'minimap2 '
        '-ax map-ont '
        '{input.genome} '
        '{input.fastq} '
        '-t {threads} '
        '> {output} '
        '2> {log}'

##uses checkpoint and function to identify all of the guppy output pass files and use as input
rule join_reads:
    input:
        get_sample_reads
    output:
        'output/joined/{sample}_{pcr}_joined.fastq.gz'
    shell:
        'cat {input} > {output} &'

##is checkpoint not rule
##output needs to be the pass folder for each sample as want to only joined files with reads that passed in next step
checkpoint guppy_basecalling:
    input:
        nanopore_raw_seq = 'data/{pcr}-pcr/{sample}'
    output:
        basecalling_out = directory('output/guppy_basecalling/{sample}_{pcr}/pass/')
    log:
        'output/logs/guppy_basecalling/{sample}_{pcr}.log'
    singularity:
        guppy_container
    shell:
        'guppy_basecaller_supervisor '
        '--port tom.staff.uod.otago.ac.nz:5555 '
        '--num_clients 5 '
        '--input_path {input.nanopore_raw_seq} '
        '--save_path {output} '
        '--flowcell "FLO-MIN106" '
        '--kit "SQK-LSK109" '
        '--recursive '
        '--trim_strategy dna '
        '--qscore_filtering '
        '--records_per_fastq 0 '
        '--compress_fastq '
        '2> {log}'