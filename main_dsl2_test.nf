#!/usr/bin/env nextflow
nextflow.enable.dsl=2

workflow {
    include {align_reads} from './workflows/align_wf'

    align_reads()
}