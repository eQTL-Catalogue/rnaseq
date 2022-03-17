nextflow.enable.dsl=2

process featureCounts {
    tag "${bam_featurecounts_sorted.baseName - '.sortedByName'}"
    publishDir "${params.outdir}/featureCounts/biotype_counts", mode: 'copy', pattern: "${sample_name}_biotype_counts*mqc.{txt,tsv}", enabled: params.saveInfoLogs
    publishDir "${params.outdir}/featureCounts/gene_count_summaries", mode: 'copy', pattern: "*_gene.featureCounts.txt.summary", enabled: params.saveInfoLogs
    publishDir "${params.outdir}/featureCounts/gene_counts", mode: 'copy', pattern: "*_gene.featureCounts.txt", enabled: params.saveIndividualQuants

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

    input:
    path input_files

    output:
    path 'merged_gene_counts.txt'

    script:
    //if we only have 1 file, just use cat and pipe output to csvtk. Else join all files first, and then remove unwanted column names.
    def single = input_files instanceof Path ? 1 : input_files.size()
    def merge = (single == 1) ? 'cat' : 'csvtk join -t -f "Geneid,Start,Length,End,Chr,Strand,gene_name"'
    """
    $merge $input_files | csvtk cut -t -f "-Start,-Chr,-End,-Length,-Strand" | sed 's/Aligned.sortedByCoord.out.markDups.bam//g' | sed 's/.sorted.bam//g' | csvtk rename -t -f Geneid -n phenotype_id | csvtk cut -t -f "-gene_name" > merged_gene_counts.txt
    """
}