nextflow.enable.dsl=2

process featureCounts {
    tag "${bam_featurecounts_sorted.baseName - '.sortedByName'}"
    publishDir "${params.outdir}/featureCounts/biotype_counts", mode: 'copy', pattern: "${sample_name}_biotype_counts*mqc.{txt,tsv}", enabled: params.saveInfoLogs
    publishDir "${params.outdir}/featureCounts/gene_count_summaries", mode: 'copy', pattern: "*_gene.featureCounts.txt.summary", enabled: params.saveInfoLogs
    publishDir "${params.outdir}/featureCounts/gene_counts", mode: 'copy', pattern: "*_gene.featureCounts.txt", enabled: params.saveIndividualQuants
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    path bam_featurecounts_sorted
    path gtf 
    path biotypes_header

    output:
    path "${sample_name}_gene.featureCounts.txt", emit: gene_feature_counts
    path "${sample_name}_gene.featureCounts.txt.summary"
    path "${sample_name}_biotype_counts*mqc.{txt,tsv}"

    script:
    def featureCounts_direction = 0
    def extraAttributes = params.fcExtraAttributes ? "--extraAttributes ${params.fcExtraAttributes}" : ''
    if (params.forward_stranded && !params.unstranded) {
        featureCounts_direction = 1
    } else if (params.reverse_stranded && !params.unstranded){
        featureCounts_direction = 2
    }
    // Try to get real sample name
    sample_name = bam_featurecounts_sorted.baseName - 'ByName'
    """
    mv $bam_featurecounts_sorted ${sample_name}.bam
    featureCounts -a $gtf -g gene_id --donotsort -o ${sample_name}_gene.featureCounts.txt $extraAttributes -p -s $featureCounts_direction ${sample_name}.bam
    featureCounts -a $gtf -g gene_type --donotsort -o ${sample_name}_biotype.featureCounts.txt -p -s $featureCounts_direction ${sample_name}.bam
    cut -f 1,7 ${sample_name}_biotype.featureCounts.txt | tail -n +3 | cat $biotypes_header - >> ${sample_name}_biotype_counts_mqc.txt
    mqc_features_stat.py ${sample_name}_biotype_counts_mqc.txt -s $sample_name -f rRNA -o ${sample_name}_biotype_counts_gs_mqc.tsv
    """
}

process merge_featureCounts {
    tag "merge ${input_files.size()} files"
    publishDir "${params.outdir}/featureCounts", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    path input_files

    output:
    path 'merged_gene_counts.tsv.gz'

    script:
    """
    paste -d"\t" $input_files > merged_raw_all.tsv
    
    csvtk cut -t -f 1 merged_raw_all.tsv | \
    csvtk rename -t -f Geneid -n phenotype_id > phenotype_ids_column.tsv

    csvtk cut -t -F -f "*.sorted.bam" merged_raw_all.tsv | sed 's/.sorted.bam//g' > merged_genes_no_phenotype_id.tsv
    paste -d"\t" phenotype_ids_column.tsv merged_genes_no_phenotype_id.tsv | gzip -c > merged_gene_counts.tsv.gz
    """
}