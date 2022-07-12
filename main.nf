#!/usr/bin/env nextflow
nextflow.enable.dsl=2

def helpMessage() {
    log.info """

    Usage:

    Mandatory arguments:
      --readPathsFile               Tab-seperated file with sample names and path to the fastq files. (Used if --reads not provided.)
      -profile                      Configuration profile to use. tartu_hpc / singularity / docker / test 

    Additional quantification options:
      --run_ge_quant                Runs gene expression quantification (featureCounts) def:true
      --run_salmon                  Runs transcript usage quantification (Salmon) def:false
      --run_txrevise                Runs txrevise quantification (Salmon with custom reference transciptome) def:false
      --run_leafcutter              Runs alternative splicing quantification  (LeafCutter) def:false
      --run_exon_quant              Runs exon quantification (DEXseq) def:false

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

def run_info_message() {
  def summary = [:]
  summary['Run Name']     = workflow.runName
  summary['ReadPathsFile']        = params.readPathsFile
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
  summary['Save Reference'] = params.saveReference ? 'Yes' : 'No'
  summary['Save Trimmed']   = params.saveTrimmed ? 'Yes' : 'No'
  summary['Save Intermeds'] = params.saveAlignedIntermediates ? 'Yes' : 'No'
  summary['Save Indv Quants']  = params.saveIndividualQuants ? 'Yes' : 'No'
  summary['Max Memory']     = params.max_memory
  summary['Max CPUs']       = params.max_cpus
  summary['Max Time']       = params.max_time
  summary['Output dir']     = params.outdir
  summary['Run ge quant']   = params.run_ge_quant
  summary['Run salmon']     = params.run_salmon
  summary['Run exon quant'] = params.run_exon_quant
  summary['Run leafcutter'] = params.run_leafcutter
  summary['Run txrevise']   = params.run_txrevise
  summary['Working dir']    = workflow.workDir
  if(workflow.revision) summary['Pipeline Release'] = workflow.revision
  summary['Current home']   = "$HOME"
  summary['Current user']   = "$USER"
  summary['Current path']   = "$PWD"
  summary['Script dir']     = workflow.projectDir
  summary['Config Profile'] = workflow.profile
  log.info summary.collect { k,v -> "${k.padRight(15)}: $v" }.join("\n")
  log.info "========================================="
}

include {align_reads} from './workflows/align_wf'
include {count_features} from './workflows/featureCounts_wf'
include {quant_exons} from './workflows/exonQuant_wf'
include {quant_tx} from './workflows/txQuant_wf'
include {quant_txrev} from './workflows/txrevQuant_wf'
include {quant_leafcutter} from './workflows/leafcutter_wf'
include { createBigWig } from './modules/utils'
include { generate_mbv } from './workflows/mbv_wf'
include { sample_correlation } from './modules/utils'

workflow {
    run_info_message()
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

    if (params.run_sample_corr && params.run_ge_quant) { 
        sample_correlation(count_features.out.gene_feature_counts.collect(),
                            Channel.fromPath("$baseDir/assets/mdsplot_header.txt"),
                            Channel.fromPath("$baseDir/assets/heatmap_header.txt"))
    }
}

