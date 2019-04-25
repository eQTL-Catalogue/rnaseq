# ![nfcore/rnaseq](docs/images/nfcore-rnaseq_logo.png)

[![Build Status](https://travis-ci.org/nf-core/rnaseq.svg?branch=master)](https://travis-ci.org/nf-core/rnaseq)
[![Nextflow](https://img.shields.io/badge/nextflow-%E2%89%A50.32.0-brightgreen.svg)](https://www.nextflow.io/)
[![DOI](https://zenodo.org/badge/127293091.svg)](https://zenodo.org/badge/latestdoi/127293091)
[![Gitter](https://img.shields.io/badge/gitter-%20join%20chat%20%E2%86%92-4fb99a.svg)](https://gitter.im/nf-core/Lobby)

[![install with bioconda](https://img.shields.io/badge/install%20with-bioconda-brightgreen.svg)](http://bioconda.github.io/)
[![Docker Container available](https://img.shields.io/docker/automated/nfcore/rnaseq.svg)](https://hub.docker.com/r/nfcore/rnaseq/)
![Singularity Container available](
https://img.shields.io/badge/singularity-available-7E4C74.svg)


### Introduction

**nfcore/rnaseq** is a bioinformatics analysis pipeline used for RNA sequencing data.

The workflow processes raw data from FastQ inputs ([FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/), [Trim Galore!](https://www.bioinformatics.babraham.ac.uk/projects/trim_galore/)), aligns the reads ([STAR](https://github.com/alexdobin/STAR) or [HiSAT2](https://ccb.jhu.edu/software/hisat2/index.shtml)), generates gene counts ([featureCounts](http://bioinf.wehi.edu.au/featureCounts/), [StringTie](https://ccb.jhu.edu/software/stringtie/)) and performs extensive quality-control on the results ([RSeQC](http://rseqc.sourceforge.net/), [dupRadar](https://bioconductor.org/packages/release/bioc/html/dupRadar.html), [Preseq](http://smithlabresearch.org/software/preseq/), [edgeR](https://bioconductor.org/packages/release/bioc/html/edgeR.html), [MultiQC](http://multiqc.info/)). See the [output documentation](docs/output.md) for more details of the results.

Additionally, the pipeline is expanded to be able to quantify transcript, exon, alternative splicing and TxRevise expressions. See [optional quantification methods](docs/extra_phenotype_quantification.md) for details.

The pipeline is built using [Nextflow](https://www.nextflow.io), a bioinformatics workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It comes with docker / singularity containers making installation trivial and results highly reproducible.

### Documentation
The nfcore/rnaseq pipeline comes with documentation about the pipeline, found in the `docs/` directory:

1. [Installation](docs/installation.md)
2. Pipeline configuration
    * [Local installation](docs/configuration/local.md)
    * [Amazon Web Services (aws)](docs/configuration/aws.md)
    * [Swedish UPPMAX clusters](docs/configuration/uppmax.md)
    * [Swedish cs3e Hebbe cluster](docs/configuration/c3se.md)
    * [Tübingen QBiC](docs/configuration/qbic.md)
    * [CCGA Kiel](docs/configuration/ccga.md)
    * [Adding your own system](docs/configuration/adding_your_own.md)
3. [Running the pipeline (Gene expression)](docs/usage.md)
4. [Running the pipeline (With additional quantification methods)](docs/extra_phenotype_quantification.md)
5. [Output and how to interpret the results](docs/output.md)
6. [Troubleshooting](docs/troubleshooting.md)

### General overview 
The schema shown below represents the high level structure of the pipeline.
# ![nfcore/rnaseq](docs/images/pipeline_high_level_schema.svg)

### Credits
These scripts were originally written for use at the [National Genomics Infrastructure](https://portal.scilifelab.se/genomics/), part of [SciLifeLab](http://www.scilifelab.se/) in Stockholm, Sweden, by Phil Ewels ([@ewels](https://github.com/ewels)) and Rickard Hammarén ([@Hammarn](https://github.com/Hammarn)).

Many thanks to other who have helped out along the way too, including (but not limited to):
[@Galithil](https://github.com/Galithil),
[@pditommaso](https://github.com/pditommaso),
[@orzechoj](https://github.com/orzechoj),
[@apeltzer](https://github.com/apeltzer),
[@colindaven](https://github.com/colindaven).
