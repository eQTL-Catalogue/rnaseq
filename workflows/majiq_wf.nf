nextflow.enable.dsl=2

// ------------------------------------------------------
// Validate input files before creating channels
// ------------------------------------------------------
if( !file(params.majiq_license_file).exists() ) {
    exit 1, "MAJIQ license file not found: ${params.majiq_license_file}"
}

if( !file(params.gff3_annotation_file).exists() ) {
    exit 1, "Annotation GFF3 file not found: ${params.gff3_annotation_file}"
}

// ------------------------------------------------------
// Create broadcast channels
// ------------------------------------------------------
majiq_license = Channel.value( file(params.majiq_license_file) )
gff3_annotation = Channel.value( file(params.gff3_annotation_file) )

include { gff2zarr; build_junctions; build_splicegraph; psi_coverage; quantifier;merge_psi;pivot_psi;coverage_for_viz;visualise;merge_modulised_events} from '../modules/majiq'

workflow {
    majiq(bam_sorted_indexed)
}
workflow majiq {
    take:
        bam_sorted_indexed
    
    main:
        if (params.has_zarr) {
            annotation = Channel.value(params.annt_file_gff_zarr)
        } else {
            gff2zarr(gff3_annotation, majiq_license)
            annotation = gff2zarr.out
        }
        build_junctions(bam_sorted_indexed, majiq_license, annotation)

        majiq_junc_grouped = build_junctions.out.majiq_junc.groupTuple()
        sample_group_majiq_juncs =  majiq_junc_grouped.map { sample_group, sample_ids, junc_files ->
         tuple(sample_group, junc_files)
        }

        sample_grouped_bams = bam_sorted_indexed.groupTuple()
        sample_group_tsv_ch = sample_grouped_bams.map { sample_group, sample_ids, bams, bam_idxs ->
                def tsv_file = file("${sample_group}.tsv")
                tsv_file.text = "group\tprefix\tsj\n" +
                    sample_ids.collect { id -> "${sample_group}\t${id}\t${id}.sj" }.join("\n")

                tuple(sample_group, tsv_file)
        }

        plicegraph_ch = sample_group_tsv_ch.join(sample_group_majiq_juncs)
        build_splicegraph(plicegraph_ch, majiq_license, annotation)

        psi_coverage_ch = majiq_junc_grouped
            .join(build_splicegraph.out.splicegraph)          // <- [group, [ids], [sj], splicegraph]
            .flatMap { group, ids, sjs, splicegraph ->
                ids.indices.collect { i ->
            [group, ids[i], sjs[i], splicegraph]
            }
        }  // -> [group, sample_id, sj, splicegraph]
        psi_coverage(psi_coverage_ch, majiq_license)
        quantifier(psi_coverage.out.psicov, majiq_license)
        sample_groups_quantifiers = quantifier.out.psi_tsv.groupTuple()
        merge_psi(sample_groups_quantifiers)
        pivot_psi(merge_psi.out.sample_group_db)
        coverage_for_viz(psi_coverage_ch, majiq_license)
        visualise_ch = coverage_for_viz.out.sgc
            .map { grp, id, graph, sgc ->
                tuple([grp, id], grp, id, graph, sgc)
            }
            .join(
                psi_coverage.out.psicov.map { grp, id, graph, psi ->
                    tuple([grp, id], grp, id, graph, psi)
                }
            )
            .map { merged ->
                def (
                    key,
                    sgc_group, sgc_id, sgc_graph, sgc_file,
                    psi_group, psi_id, psi_graph, psi_file
                ) = merged
                tuple(sgc_group, sgc_id, sgc_graph, sgc_file, psi_file)
        }
        visualise(visualise_ch, majiq_license)        
        sample_group_events = visualise.out.modulised_events
            .flatMap { sample_group, maybeFiles ->
                def files = (maybeFiles instanceof Collection) ? maybeFiles : [ maybeFiles ]
                files.collect { f ->
                    if (f.name ==~ /.*(summary|other|orphan|heatmap).*/)
                        return null
                    def event = f.name.replaceFirst(/\..*\.tsv$/, '')
                    tuple(sample_group, event, f)
                }.findAll { it != null }
            }
            .groupTuple(by: [0,1])
        merge_modulised_events(sample_group_events)
}