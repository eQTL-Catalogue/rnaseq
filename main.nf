#!/usr/bin/env nextflow
nextflow.enable.dsl=2

def helpMessage() {
    log.info """

    Usage:

    Mandatory arguments:
      --readPathsFile               Tab-seperated file with sample names and path to the fastq files.
      -profile                      Configuration profile to use. tartu_hpc / test

    Additional quantification options:
      --run_ge_quant                Runs gene expression quantification (featureCounts) def:true
      --run_salmon                  Runs transcript usage quantification (Salmon) def:false
      --run_txrevise                Runs txrevise quantification (Salmon with custom reference transciptome) def:false
      --run_leafcutter              Runs alternative splicing quantification  (LeafCutter) def:false
      --run_exon_quant              Runs exon quantification (DEXseq) def:false
      --run_majiq                   Runs alternative splicing/introns quantification (MAJIQ) def:false

    Options:
      --singleEnd                   Specifies that the input is single end reads
    Strandedness:
      --forward_stranded            The library is forward stranded
      --reverse_stranded            The library is reverse stranded
      --unstranded                  The default behaviour

    References                      If not specified in the configuration file or you wish to overwrite any of the references.
      --hisat2_index                Path to HiSAT2 index
      --fasta                       Path to Fasta reference
      --tx_fasta                    Path to transcript fasta reference
      --gtf_fc                      Path to GTF file to use with feactureCounts
      --gtf_hisat2_index            Path to GTF file to build hisat index
      --txrevise_gffs               Path to GFF files for txrevise
      --saveReference               Save the generated reference files the the Results directory.
      --saveTrimmed                 Save trimmed FastQ file intermediates
      --saveAlignedIntermediates    Save the BAM files from the Aligment step  - not done by default
      --saveIndividualQuants        Save individual quantified samples (exons and salmon)

    Trimming options
      --clip_r1 [int]               Instructs Trim Galore to remove bp from the 5' end of read 1 (or single-end reads)
      --clip_r2 [int]               Instructs Trim Galore to remove bp from the 5' end of read 2 (paired-end reads only)
      --three_prime_clip_r1 [int]   Instructs Trim Galore to remove bp from the 3' end of read 1 AFTER adapter/quality trimming has been performed
      --three_prime_clip_r2 [int]   Instructs Trim Galore to re move bp from the 3' end of read 2 AFTER adapter/quality trimming has been performed

    Other options:
      --outdir                      The output directory where the results will be saved
      -w/--work-dir                 The temporary directory where intermediate data will be saved
      --clusterOptions              Extra SLURM options, used in conjunction with Uppmax.config
      -name                         Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

    Additional options:
      --run_sample_corr             Runs edgeR sample correlation analysis
      --generate_bigwig             Generated BigWig files from BAM files

    MBV options:
      --run_mbv                     Enables MBV output generation
      --mbv_vcf                     if run_mbv is set vcf file should be provided

    """.stripIndent()
}

// Show help message
if (params.help){
    helpMessage()
    exit 0
}

def build_wf_summary() {
    // Fetch the pipeline version from Git tags
    def pipelineVersion = "v0.0.0" // Default version in case git command fails

    // Try to fetch the version from Git
    try {
        pipelineVersion = "git describe --tags".execute().text.trim()
    } catch (Exception e) {
        log.info "Could not retrieve the pipeline version from Git. Using default version $pipelineVersion."
    }
    def summary = [:]
    summary['Run Name']   = workflow.runName
    summary['Session id'] = workflow.sessionId?.toString()
    summary['Pipeline Version'] = pipelineVersion
    if (params.dataset_id) summary['Dataset id'] = params.dataset_id
    summary['ReadPathsFile']     = params.readPathsFile.toString()
    //summary['ReadPathsSHA']  = readpaths_sha ToDo: add  sha?
    summary['Data Type']    = params.singleEnd ? 'Single-End' : 'Paired-End'
    summary['Strandedness'] = ( params.unstranded ? 'None' : params.forward_stranded ? 'Forward' : params.reverse_stranded ? 'Reverse' : 'None' )
    summary['Trim R1'] = params.clip_r1
    summary['Trim R2'] = params.clip_r2
    summary["Trim 3' R1"] = params.three_prime_clip_r1
    summary["Trim 3' R2"] = params.three_prime_clip_r2
    summary['Aligner'] = "HISAT2"
    if(params.hisat2_index)        summary['HISAT2 Index'] = params.hisat2_index
    if(params.gtf_hisat2_index)        summary['GTF HISAT2 Index'] = params.gtf_hisat2_index
    if(params.gtf_fc)                 summary['GTF Annotation']  = params.gtf_fc
    summary['Save Reference'] = params.saveReference
    summary['Save Trimmed']   = params.saveTrimmed
    summary['Save Intermeds'] = params.saveAlignedIntermediates
    summary['Save Indv Quants']  = params.saveIndividualQuants
    summary['Run ge quant']   = params.run_ge_quant
    summary['Run salmon']     = params.run_salmon
    summary['Run exon quant'] = params.run_exon_quant
    summary['Run leafcutter'] = params.run_leafcutter
    summary['Run txrevise']   = params.run_txrevise
    summary['Run majiq']      =  params.run_majiq
    summary['Current home']   = "$HOME"
    summary['Current user']   = "$USER"
    summary['Current path']   = "$PWD"
    summary['Output dir']     = params.outdir.toString()
    summary['Working dir']    = workflow.workDir.toString()
    summary['Script dir']     = workflow.projectDir.toString()
    summary['Pipeline script file path'] = workflow.scriptFile.toString()
    summary['Pipeline script hash ID'] = workflow.scriptId.toString()
    summary['Config Profile'] = workflow.profile
    summary['Container Engine']  = workflow.containerEngine.toString()
    summary['Nextflow_version'] = workflow.nextflow.version.toString()
    summary['Nextflow Build'] = workflow.nextflow.build.toString()
    summary['Max Memory']     = params.max_memory.toString()
    summary['Max CPUs']       = params.max_cpus.toString()
    summary['Max Time']       = params.max_time.toString()
    return summary
}

def wf_summary = build_wf_summary()
log.info wf_summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")

include {align_reads} from './workflows/align_wf'
include {count_features} from './workflows/featureCounts_wf'
include {quant_exons} from './workflows/exonQuant_wf'
include {quant_tx} from './workflows/txQuant_wf'
include {quant_txrev} from './workflows/txrevQuant_wf'
include {quant_leafcutter} from './workflows/leafcutter_wf'
include { createBigWig } from './modules/utils'
include { majiq } from './workflows/majiq_wf'
include { generate_mbv } from './workflows/mbv_wf'
include { sample_correlation } from './modules/utils'

workflow {
    align_reads()
    if (params.run_ge_quant){
        count_features(align_reads.out.bam_sorted_by_name)
    }

    if (params.run_exon_quant) {
        quant_exons(align_reads.out.bam_sorted_by_name)
    }

    if (params.run_salmon) {
        quant_tx(align_reads.out.trimmed_reads)
    }

    if (params.run_txrevise) {
        quant_txrev(align_reads.out.trimmed_reads)
    }

    if (params.run_leafcutter) {
        quant_leafcutter(align_reads.out.bam_sorted_indexed)
    }

    if (params.generate_bigwig) {
        createBigWig(align_reads.out.bam_sorted_indexed)
    }

    if (params.run_mbv){
        generate_mbv(align_reads.out.bam_sorted_indexed)
    }

    if (params.run_majiq){
        majiq(align_reads.out.bam_sorted_indexed)
    }

    if (params.run_sample_corr && params.run_ge_quant) {
        def mds_header_path = file("$baseDir/assets/mdsplot_header.txt")
        def heatmap_header_path = file("$baseDir/assets/heatmap_header.txt")

        if( !mds_header_path.exists() )
            exit 1, "Missing header file: $mds_header_path"

        if( !heatmap_header_path.exists() )
            exit 1, "Missingheatmap header file: $heatmap_header_path"

        mds_header = Channel.value( mds_header_path )
        heatmap_header = Channel.value( heatmap_header_path )

        sample_correlation(count_features.out.gene_feature_counts, mds_header, heatmap_header)

    }
}

workflow.onComplete {
    def status_str =
        workflow.success ? 'SUCCESS' :
        (workflow.errorReport ? 'FAILED' : 'CANCELLED')

    wf_summary['status'] = status_str
    wf_summary['start_time']     = workflow.start?.toString()
    wf_summary['end_time']       = new Date().toString()
    wf_summary['exit_status']    = workflow.exitStatus
    wf_summary['error_message']  = workflow.errorMessage?.toString()
    wf_summary['error_report']   = workflow.errorReport?.toString()

    def manifest_file = file("${params.outdir}/pipeline_info/run_summary.json")
    manifest_file.text = groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(wf_summary))

    // save main config
    def src = file("${workflow.projectDir}/nextflow.config")
    if (src.exists()) {
        file("${params.outdir}/pipeline_info/nextflow.config").text = src.text
    }

    // save used profiles configs
    def profiles = workflow.profile?.toString()?.split(',') ?: []
    profiles.collect { it.trim() }
        .findAll { it }
        .each { prof ->
            def prof_cfg = file("${workflow.projectDir}/conf/${prof}.config")
            if (prof_cfg.exists()) {
                file("${params.outdir}/pipeline_info/${prof}.config").text = prof_cfg.text
            }
        }
}

