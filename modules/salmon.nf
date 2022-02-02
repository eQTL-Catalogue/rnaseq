nextflow.enable.dsl=2

process makeSalmonIndex {
    tag "${fasta.baseName}"
    publishDir "${params.outdir}/Salmon/salmon_index", mode: 'copy', enabled: params.saveReference

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
    tag "$samplename - ${index.baseName}"
    publishDir "${params.outdir}/Salmon/quant/${index.baseName}/", mode: 'copy', enabled: params.saveIndividualQuants, pattern: "*.quant.sf"

    input:
    tuple val(samplename), file(reads) 
    each index 

    output:
    tuple val(index.baseName), file("${samplename}.quant.edited.sf"), emit: salmon_quantified
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
        mv quant.sf ${samplename}.quant.sf
        cat ${samplename}.quant.sf | csvtk cut -t -f "-Length,-EffectiveLength" | sed '1s/TPM/${samplename}_TPM/g' | sed '1s/NumReads/${samplename}_NumReads/g' > ${samplename}.quant.edited.sf
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
        mv quant.sf ${samplename}.quant.sf
        cat ${samplename}.quant.sf | csvtk cut -t -f "-Length,-EffectiveLength" | sed '1s/TPM/${samplename}_TPM/g' | sed '1s/NumReads/${samplename}_NumReads/g' > ${samplename}.quant.edited.sf
        """
    }
}

process salmon_merge {
    tag "merge_salmon_${index}"
    publishDir "${params.outdir}/Salmon/merged_counts/TPM", mode: 'copy', pattern: "*TPM.merged.txt"
    publishDir "${params.outdir}/Salmon/merged_counts/NumReads", mode: 'copy', pattern: "*.NumReads.merged.txt"

    input:
    tuple val(index), file(input_files) 

    output:
    path '*merged.txt'

    script:
    //if we only have 1 file, just use cat and pipe output to csvtk. Else join all files first, and then remove unwanted column names.
    def single = input_files instanceof Path ? 1 : input_files.size()
    def merge = (single == 1) ? 'cat' : 'csvtk join -t -f "Name"'
    """
    $merge $input_files | csvtk rename -t -f Name -n phenotype_id > merged_TPMS_NumReads.tsv
    csvtk cut -t -F -f -"*_NumReads" merged_TPMS_NumReads.tsv | sed 's/_TPM//g' > ${index}.TPM.merged.txt
    csvtk cut -t -F -f -"*_TPM" merged_TPMS_NumReads.tsv | sed 's/_NumReads//g' > ${index}.NumReads.merged.txt
    """
}