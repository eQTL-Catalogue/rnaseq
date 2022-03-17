process bam_to_junc {
    container = 'quay.io/eqtlcatalogue/leafcutter:v22.03.p4'
    publishDir "${params.outdir}/leafcutter/juncs", mode: 'copy', enabled: params.saveIndividualQuants

    input:
    tuple file(bam), file(bam_index)

    output:
    path "${bam.baseName}.junc", emit: junc
    
    script:
    // If confused about strands check this: https://rnabio.org/module-09-appendix/0009/12/01/StrandSettings/
    def leafcutter_strand = 0
    if (params.forward_stranded && !params.unstranded) {
        leafcutter_strand = 1
    } else if (params.reverse_stranded && !params.unstranded){
        leafcutter_strand = 2
    }
    """
    regtools junctions extract -s $leafcutter_strand -a 8 -m ${params.leafcutter_min_intron_length} -M ${params.leafcutter_max_intron_length} $bam -o ${bam.baseName}.junc
    """
}

process cluster_introns {
    container = 'quay.io/eqtlcatalogue/leafcutter:v22.03.p4'
    tag "${junc_files.baseName}"
    publishDir "${params.outdir}/leafcutter", mode: 'copy'

    input:
    path junc_files

    output:
    path "leafcutter_perind*.gz", emit: perind_counts
    path "*_refined"

    script:
    """
    leafcutter_cluster_regtools.py -j $junc_files -m ${params.leafcutter_min_split_reads} -o leafcutter -l ${params.leafcutter_max_intron_length} --checkchrom=True
    zcat leafcutter_perind_numers.counts.gz | sed '1s/^/phenotype_id /' | sed 's/.sorted//g' | sed -e 's/ /\t/g' | gzip -c > leafcutter_perind_numers.counts.formatted.gz
    """
}