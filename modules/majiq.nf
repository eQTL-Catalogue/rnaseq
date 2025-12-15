nextflow.enable.dsl=2

process gff2zarr {
    publishDir "${params.outdir}", mode: 'copy'
    container = 'quay.io/eqtlcatalogue/majiq3:v25.10.1'

    input:
    path gff
    path license_file

    output:
    path("*.zarr")

    script:
    def annt_name = gff.name.replaceAll(/\.(gtf|gff3)(\.gz)?$/, '')
    """
    majiq-v3 gff3 --license ${license_file}  ${gff} "${annt_name}.zarr"
    """
}

process build_junctions {
    tag "${sample_id}"
    publishDir "${params.outdir}/majiq_juncs/${sample_group}", mode: 'copy', enabled: params.saveMajiqJuncs
    container = 'quay.io/eqtlcatalogue/majiq3:v25.10.1'

    input:
    tuple val(sample_group), val(sample_id), path(bam), path(bam_index)
    path(majiq_license)
    path(annotation)


    output:
    tuple val(sample_group), val(sample_id), path("${sample_id}.sj"), emit: majiq_junc



    script:
    """
    
    majiq-v3 sj --license ${majiq_license} -j ${task.cpus} ${bam} ${annotation} ${sample_id}.sj
    """
}

process build_splicegraph{
    tag "${sample_group}"
    label 'build_splicegraph'
    container = 'quay.io/eqtlcatalogue/majiq3:v25.10.1'

    input:
    tuple val(sample_group), path(sample_group_tsv),  path(sj_files)
    path majiq_license
    path annotation

    output:
    tuple val(sample_group), path("${sample_group}_splicegraph.zarr"), emit: splicegraph
    path("${sample_group}_builder.log")


    script:
        // calculate dynamic min experiments
        def sj_count = sj_files.size()
        def dynamic_min_exp = Math.ceil(sj_count * 0.01) as int
        // choose between default or dynamic min_exp
        def min_exp_used = params.useDefaultMajiqMinExp ?
                    params.majiqMinExp :
                    dynamic_min_exp

    """
    majiq-v3 build --license ${majiq_license} -j ${task.cpus} --min-experiments ${min_exp_used} --minreads ${params.min_reads} --minpos ${params.min_pos} ${annotation} ${sample_group}_splicegraph.zarr --groups-tsv ${sample_group_tsv} --logger ${sample_group}_builder.log
    """

}

process psi_coverage {
    tag "${sample_group}-${sample_id}"
    container = 'quay.io/eqtlcatalogue/majiq3:v25.10.1'

    input:
    tuple val(sample_group), val(sample_id),  path(sj_file), path(sample_group_splicegraph)
    path majiq_license


    output:
    tuple val(sample_group),val(sample_id), path(sample_group_splicegraph), path("${sample_id}.psicov"), emit: psicov
    path("${sample_id}_psicov.log")


    script:

    """
    majiq-v3 psi-coverage --license ${majiq_license} -j ${task.cpus}  --minreads ${params.min_reads} --minbins ${params.min_pos} ${sample_group_splicegraph} ${sample_id}.psicov ${sj_file} --logger ${sample_id}_psicov.log
    """
}

 process quantifier {
    container = 'quay.io/eqtlcatalogue/majiq3:v25.10.1'



    input:
    tuple val(sample_group),val(sample_id), path(sample_group_splicegraph), path(psicov_file)
    path majiq_license


    output:
    tuple val(sample_group),val(sample_id), path("${sample_id}.psi.tsv"), emit: psi_tsv
    path("${sample_id}_quantify.log")

    script:

    """
    majiq-v3 quantify --license ${majiq_license}  -j ${task.cpus} --splicegraph ${sample_group_splicegraph} --output-tsv ${sample_id}.psi.tsv ${psicov_file} --logger ${sample_id}_quantify.log
    """

}

process merge_psi {
    tag "${sample_group}"
    container = 'quay.io/kfkf33/duckdb_env:v24.01.1'
    input:
    tuple val(sample_group), val(sample_ids), path(psi_files)

    output:
    tuple val(sample_group), path("${sample_group}_psi.duckdb"), emit: sample_group_db

    script:
    """
    merge_psi.py \
        --sample-ids ${sample_ids.join(' ')} \
        --psi-files ${psi_files.join(' ')} \
        --db ${sample_group}_psi.duckdb
    """
}

process pivot_psi {
    tag "${sample_group}"
    publishDir "${params.outdir}/majiq_quantified_psis/${sample_group}", mode: 'copy', pattern: "*.tsv.gz"
    container = 'quay.io/kfkf33/duckdb_env:v24.01.1'

    input:
    tuple val(sample_group), path(db)

    output:
    tuple val(sample_group), path("${sample_group}_majiq_quantified_psis.tsv.gz")

    script:
    """
    pivot_psi.py \
        --duckdb ${db} \
        --output ${sample_group}_majiq_quantified_psis.tsv.gz \
        --memory_limit ${task.memory.toMega() / 1024}
    """
}

process coverage_for_viz {
    tag "${sample_id}"
    container = 'quay.io/eqtlcatalogue/majiq3:v25.10.1'

    input:
    tuple val(sample_group), val(sample_id),  path(sj_file), path(sample_group_splicegraph)
    path majiq_license



    output:
    tuple val(sample_group),val(sample_id), path(sample_group_splicegraph), path("${sample_id}.sgc"), emit: sgc


    script:

    """
    majiq-v3 sg-coverage --license ${majiq_license}  -j ${task.cpus} ${sample_group_splicegraph} ${sample_id}.sgc ${sj_file} --logger ${sample_id}_cov_for_viz.log
    """

}

process visualise {
    tag "${sample_id}"
    publishDir "${params.outdir}/majiq_moduliser/${sample_group}", mode: 'copy', enabled: params.saveMajiqModulizedEvents
    container = 'quay.io/eqtlcatalogue/majiq3:v25.10.1'

    input:
    tuple val(sample_group), val(sample_id), path(sample_group_splicegraph), path(sgc_file), path(psicov_file)
    path majiq_license

    output:
    tuple val(sample_group), path("*_${sample_id}.tsv"), emit: modulised_events

    script:
    """
    
    voila --license ${majiq_license} modulize -j ${task.cpus} --show-all  --show-per-sample-psi --changing-between-group-dpsi 0.1 --decomplexify-psi-threshold 0.05 --decomplexify-reads-threshold 1 -d . ${sample_group_splicegraph} ${psicov_file} ${sgc_file} --logger modulise_${sample_id}.log
    for f in *.tsv; do
        mv -- \$f \${f%.tsv}_${sample_id}.tsv
    done
    """
}

process merge_modulised_events {
    tag "${sample_group}-${event}"
    publishDir "${params.outdir}/majiq_merged_modulised_events/${sample_group}", mode: 'copy'
    container = "quay.io/kfkf33/polars"

    input:
    tuple val(sample_group), val(event), path(modulised_event_files)

    output:
    path "*.tsv"
    tuple val(sample_group), path("${sample_group}_${event}.tsv")

    script:
    """
    merge_moduliser_events.py \
        --files ${modulised_event_files.join(' ')} \
        --event $event \
        --output ${sample_group}_${event}.tsv
    """

}
