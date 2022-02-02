nextflow.enable.dsl=2


hs2_indices = Channel
        .fromPath("${params.hisat2_index}*")
        .ifEmpty { exit 1, "HISAT2 index not found: ${params.hisat2_index}" }


if(params.singleEnd){
    Channel.fromPath(params.readPathsFile)
    .ifEmpty { error "Cannot find any readPathsFile file in: ${params.readPathsFile}" }
    .splitCsv(header: false, sep: '\t', strip: true)
    .map{row -> [ row[0], [ file(row[1]) ] ]}
    .set { raw_reads_trimgalore }
} else {
    Channel.fromPath(params.readPathsFile)
    .ifEmpty { error "Cannot find any readPathsFile file in: ${params.readPathsFile}" }
    .splitCsv(header: false, sep: '\t', strip: true)
    .map{row -> [ row[0], [ file(row[1]) , file(row[2]) ] ]}
    .set { raw_reads_trimgalore }
}


Channel
    .fromPath( params.gtf )
    .ifEmpty { exit 1, "GTF annotation file not found: ${params.gtf}" }
    .set { gtf_file }

include { makeHisatSplicesites; trim_galore; hisat2Align; hisat2_sortOutput } from '../modules/align'

workflow {
    align_reads()
}

workflow align_reads {
    makeHisatSplicesites(gtf_file.collect())
    trim_galore(raw_reads_trimgalore)
    hisat2Align(trim_galore.out.trimmed_reads, hs2_indices.collect(), makeHisatSplicesites.out.collect())
    hisat2_sortOutput(hisat2Align.out.hisat2_bam_ch)
}


