nextflow.enable.dsl=2

process makeDexSeqExonGFF {
    tag "${gtf.baseName}"
    publishDir "${params.outdir}/dexseq_exon_counts", mode: 'copy', enabled: params.saveReference
    
    input:
    path gtf 

    output:
    path "${gtf.baseName}.patched_contigs.DEXSeq.gff"
    
    script:
    """
    cat $gtf | sed 's/chrM/chrMT/;s/chr//' > ${gtf.baseName}.patched_contigs.gtf
    $baseDir/bin/dexseq/dexseq_prepare_annotation.py ${gtf.baseName}.patched_contigs.gtf ${gtf.baseName}.patched_contigs.DEXSeq.gff
    """
}

process count_exons {
    tag "${bam.simpleName}"
    publishDir "${params.outdir}/dexseq_exon_counts/quant_files", mode: 'copy', enabled: params.saveIndividualQuants

    input:
    path bam 
    path gff 

    output:
    path "${bam.simpleName}.exoncount.txt" 

    script:
    def featureCounts_direction = 0
    if (params.forward_stranded && !params.unstranded) {
        featureCounts_direction = 1
    } else if (params.reverse_stranded && !params.unstranded){
        featureCounts_direction = 2
    }
    """
    featureCounts -p -t exonic_part -s $featureCounts_direction -f -O -a $gff -o ${bam.simpleName}.exoncount.txt $bam
    """
}

process exon_count_merge {
    tag "merge exon ${input_files.size()} files"
    publishDir "${params.outdir}/dexseq_exon_counts", mode: 'copy'

    input:
    path input_files

    output:
    path 'merged_exon_counts.tsv'

    script:
    //if we only have 1 file, just use cat and pipe output to csvtk. Else join all files first, and then remove unwanted column names.
    def single = input_files instanceof Path ? 1 : input_files.size()
    def merge = (single == 1) ? 'cat' : 'csvtk join -t -f "Geneid,Start,Length,End,Chr,Strand"'
    """
    $merge $input_files | sed 's/.sortedByName.bam//g' | awk '\$1=\$1"_"\$2"_"\$3"_"\$4' OFS='\t' | csvtk rename -t -f Geneid_Chr_Start_End -n phenotype_id | csvtk cut -t -f "-Chr,-Start,-End,-Strand,-Length" > merged_exon_counts.tsv
    """
}