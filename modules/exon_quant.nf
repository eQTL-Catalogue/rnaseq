nextflow.enable.dsl=2

process makeDexSeqExonGFF {
    tag "${gtf.baseName}"
    publishDir "${params.outdir}/dexseq_exon_counts", mode: 'copy', enabled: params.saveReference
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'
    
    input:
    path gtf 

    output:
    path "${gtf.baseName}.patched_contigs.DEXSeq.gff"
    
    script:
    """
    cat $gtf | sed 's/chrM/chrMT/;s/chr//' > ${gtf.baseName}.patched_contigs.gtf
    $baseDir/bin/dexseq/dexseq_prepare_annotation.py ${gtf.baseName}.patched_contigs.gtf ${gtf.baseName}.patched_contigs_tx.DEXSeq.gff
    cat ${gtf.baseName}.patched_contigs_tx.DEXSeq.gff | cut -f1 -d";" > ${gtf.baseName}.patched_contigs.DEXSeq.gff
    """
}

process count_exons {
    tag "${sample_id}"
    publishDir "${params.outdir}/dexseq_exon_counts/quant_files", mode: 'copy', enabled: params.saveIndividualQuants
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple val(sample_group), val(sample_id), path(bam)
    path gff 

    output:
    tuple val(sample_group), val(sample_id), path("${sample_id}.exoncount.txt"), emit: exon_counts

    script:
    def featureCounts_direction = 0
    if (params.forward_stranded && !params.unstranded) {
        featureCounts_direction = 1
    } else if (params.reverse_stranded && !params.unstranded){
        featureCounts_direction = 2
    }
    """
    featureCounts -p -t exonic_part -s $featureCounts_direction -f -O -a $gff -o ${sample_id}.exoncount.txt $bam
    """
}

process exon_count_merge {
    tag "merge ${sample_group} ${input_files.size()} files"
    publishDir "${params.outdir}/dexseq_exon_counts/${sample_group}", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple val(sample_group), path(input_files)

    output:
    path "${sample_group}_merged_exon_counts.tsv.gz"

    script:
    """
    paste -d"\t" $input_files > ${sample_group}_merged_raw_all.tsv
    
    csvtk cut -t -f 1-4 ${sample_group}_merged_raw_all.tsv | \
    awk '\$1=\$1"_"\$2"_"\$3"_"\$4' OFS='\t' | \
    csvtk rename -t -f Geneid_Chr_Start_End -n phenotype_id | \
    csvtk cut -t -f phenotype_id > ${sample_group}_phenotype_ids_column.tsv

    csvtk cut -t -F -f "*.sortedByName.bam" ${sample_group}_merged_raw_all.tsv | sed 's/.sortedByName.bam//g' > ${sample_group}_merged_exon_no_phenotype_id.tsv
    paste -d"\t" ${sample_group}_phenotype_ids_column.tsv ${sample_group}_merged_exon_no_phenotype_id.tsv | gzip -c > ${sample_group}_merged_exon_counts.tsv.gz
    """
}