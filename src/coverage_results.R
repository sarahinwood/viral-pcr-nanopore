library(data.table)
library(rtracklayer)
library(dplyr)

coverage_table <- fread("output/samtools_coverage/hyp_bro_depth.out")
prodigal_gff <- readGFF("data/Mh/gene_predictions.gff")

setorder(coverage_table, -meandepth)
coverage_table$meandepth <- format(coverage_table$meandepth)

prodigal_scaffold_list <- unique(prodigal_gff$seqid)

fil_coverage_table <- subset(coverage_table, numreads>0)
fil_coverage_table$prodigal_status <- ifelse(fil_coverage_table$`#rname` %in% prodigal_scaffold_list, "prodigal_scaffold", "NA")
setorder(fil_coverage_table, -prodigal_status, -meandepth)

fwrite(fil_coverage_table,"output/samtools_coverage/coverage_table.csv")
