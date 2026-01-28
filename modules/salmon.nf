nextflow.enable.dsl=2

process makeSalmonIndex {
    tag "${fasta.baseName}"
    publishDir "${params.outdir}/Salmon/salmon_index", mode: 'copy', enabled: params.saveReference
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    path fasta 

    output:
    path "${fasta.baseName}.index"
    
    script:
    """
    salmon index -t ${fasta} -i ${fasta.baseName}.index
    """
}

process salmon_quant {
    tag "$sample_id - ${index.baseName}"
    publishDir "${params.outdir}/Salmon/quant/${index.baseName}/", mode: 'copy', enabled: params.saveIndividualQuants, pattern: "*.quant.sf"
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple val(sample_group), val(sample_id), path(reads)
    each index 

    output:
    tuple val(index.baseName), val(sample_group), val(sample_id), file("${sample_id}.quant.edited.sf"), emit: salmon_quantified
    path '*.quant.sf'
    
    script:
    def strandedness = params.unstranded ? 'U' : 'SR'
    if (params.singleEnd) {
        """
        salmon quant --seqBias --useVBOpt --gcBias \\
                        --libType $strandedness \\
                        --index ${index} \\
                        -r ${reads[0]} \\
                        -p ${task.cpus} \\
                        -o .
        mv quant.sf ${sample_id}.quant.sf
        cat ${sample_id}.quant.sf | csvtk cut -t -f "-Length,-EffectiveLength" | sed '1s/TPM/${sample_id}_TPM/g' | sed '1s/NumReads/${sample_id}_NumReads/g' > ${sample_id}.quant.edited.sf
        """
    } else {
        """
        salmon quant --seqBias --useVBOpt --gcBias \\
                        --libType I$strandedness \\
                        --index $index \\
                        -1 ${reads[0]} \\
                        -2 ${reads[1]} \\
                        -p ${task.cpus} \\
                        -o .
        mv quant.sf ${sample_id}.quant.sf
        cat ${sample_id}.quant.sf | csvtk cut -t -f "-Length,-EffectiveLength" | sed '1s/TPM/${sample_id}_TPM/g' | sed '1s/NumReads/${sample_id}_NumReads/g' > ${sample_id}.quant.edited.sf
        """
    }
}

process salmon_merge {
    tag "merge_salmon_${sample_group}_${index}"
    publishDir "${params.outdir}/${sample_group}/Salmon/merged_counts/TPM", mode: 'copy', pattern: "*.TPM.merged.tsv.gz"
    publishDir "${params.outdir}/${sample_group}/Salmon/merged_counts/NumReads", mode: 'copy', pattern: "*.NumReads.merged.tsv.gz"
    container = 'quay.io/eqtlcatalogue/rnaseq:v20.11.1'

    input:
    tuple val(index), val(sample_group), path(input_files)

    output:
    path "*merged.tsv.gz"

    script:
    """
    paste -d"\t" $input_files > merged_raw_all.tsv
    csvtk cut -t -f 1 merged_raw_all.tsv | csvtk rename -t -f Name -n phenotype_id > phenotype_ids_column.tsv
    csvtk cut -t -F -f "*_TPM" merged_raw_all.tsv | sed 's/_TPM//g' > gencode.v39.transcripts.TPM_only.merged.tsv
    csvtk cut -t -F -f "*_NumReads" merged_raw_all.tsv | sed 's/_NumReads//g' > gencode.v39.transcripts.NumReads_only.merged.tsv
    paste -d"\t" phenotype_ids_column.tsv gencode.v39.transcripts.TPM_only.merged.tsv | gzip -c > ${index}.TPM.merged.tsv.gz
    paste -d"\t" phenotype_ids_column.tsv gencode.v39.transcripts.NumReads_only.merged.tsv | gzip -c > ${index}.NumReads.merged.tsv.gz
    """
}