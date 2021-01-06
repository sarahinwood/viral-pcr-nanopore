##see https://gist.github.com/TomHarrop/1ebb893b78390dcdbaa52393f085c6f3
##host doesn't have GPU so need a non-GPU version of container on client (biochemcompute)
###port makes it run on Tom's GPU
##inut path is where sequencing is (use rsync to download from nanopore comp. to biochemcompute)
singularity exec \
    -B /Volumes \
    ont-containers_guppy-cpu_4.2.2.sif \
    guppy_basecaller_supervisor \
    --port tom-1.staff.uod.otago.ac.nz:5555 \
    --num_clients 5 \
    --input_path /Volumes/archive/deardenlab/minion/raw/sarah/bro-pcr \
    --save_path "output/hyp_bro_$(date -I)" \
    --flowcell "FLO-MIN106" \
    --kit "SQK-LSK109" \
    --recursive \
    --trim_strategy dna \
    --qscore_filtering \
    --records_per_fastq 0 \
    --compress_fastq \