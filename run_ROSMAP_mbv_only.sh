nextflow run mbv_only.nf\
 -profile tartu_hpc,eqtl_catalogue\
 --mbv_vcf /gpfs/hpc/home/a72094/datasets/controlled_access/ROSMAP/genotypes/Michigan_GRCh37_Phase3_200819/merged/ROSMAP_GRCh38_filtered.vcf.gz\
 --bamsDir "/gpfs/hpc/home/a72094/datasets/processed/ROSMAP/HISAT2/aligned_sorted/*.bam"
 -executor.queueSize 80\
 --outdir './mbv_results_ROSMAP'\
 -resume

