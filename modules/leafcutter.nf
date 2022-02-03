process bam_to_junc {
    container = 'quay.io/karlvaba/leafcutter'
    publishDir "${params.outdir}/leafcutter/juncs", mode: 'copy'

    input:
    tuple file(bam), file(bam_index)

    output:
    path "${bam.baseName}.junc", emit: junc
    
    script:
    """
    regtools junctions extract -s 0 -a 8 -m 50 -M 500000 $bam -o ${bam.baseName}.junc
    """
}

process cluster_introns {
    container = 'quay.io/karlvaba/leafcutter'
    tag "${junc_files.baseName}"
    publishDir "${params.outdir}/leafcutter", mode: 'copy'

    input:
    path junc_files

    output:
    path "leafcutter_perind*.gz", emit: perind_counts
    path "*_refined"

    script:
    """
    leafcutter_cluster_regtools.py -j $junc_files -m 50 -o leafcutter -l 500000 --checkchrom TRUE
    zcat leafcutter_perind_numers.counts.gz | sed '1s/^/phenotype_id /' | sed 's/.sorted//g' | sed -e 's/ /\t/g' | gzip -c > leafcutter_perind_numers.counts.formatted.gz
    """
}