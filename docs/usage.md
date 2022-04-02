# nfcore/rnaseq Usage

## General Nextflow info
Nextflow handles job submissions on SLURM or other environments, and supervises running the jobs. Thus the Nextflow process must run until the pipeline is finished. We recommend that you put the process running in the background through `screen` / `tmux` or similar tool. Alternatively you can run nextflow within a cluster job submitted your job scheduler.

It is recommended to limit the Nextflow Java virtual machines memory. We recommend adding the following line to your environment (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## Running the pipeline
The typical command for running the pipeline is as follows:
```bash
nextflow run main.nf --readPathsFile data/read_pathes_GEUVADIS_GBR_20samples.tsv -profile singularity
```

Note that the pipeline will create the following files in your working directory:

```bash
work            # Directory containing the nextflow working files
results         # Finished results (configurable, see below)
.nextflow_log   # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

## Main Arguments


### `--run_ge_quant`
Enables quantification of gene expression

### `--run_salmon`
Enables quantification of transcript usage

### `--run_txrevise`
Enables quantification of transcriptional event expression (TxRevise)

### `--run_exon_quant`
Enables quantification of exon expression

### `--run_leafcutter`
Enables quantification of intron-slicing expression

**Note: If none of the `run_[quantification method]` is set to `true` pipeline will only align the reads and stop the pipeline execution**


### `-profile`
Use this parameter to choose a configuration profile. Each profile is designed for a different compute environment - follow the links below to see instructions for running on that system. Available profiles are:

* `docker`
    * A generic configuration profile to be used with [Docker](http://docker.com/)
    * Runs using the `local` executor and pulls software from dockerhub: [`nfcore/rnaseq`](http://hub.docker.com/r/nfcore/rnaseq/)
* `uppmax`, `uppmax_modules`, `uppmax_devel`
    * Designed to be used on the Swedish [UPPMAX](http://uppmax.uu.se/) clusters such as `milou`, `rackham`, `bianca` and `irma`
    * See [`docs/configuration/uppmax.md`](configuration/uppmax.md)
* `hebbe`
    * Designed to be run on the [c3se Hebbe cluster](http://www.c3se.chalmers.se/index.php/Hebbe) in Chalmers, Gothenburg.
    * See [`docs/configuration/c3se.md`](configuration/c3se.md)
* `binac`, `cfc`
    * Profiles for clusters at QBiC in Tübingen, Germany
    * See [`docs/configuration/qbic.md`](configuration/qbic.md)
* `awsbatch`
    * Profile for running on AWSBatch, specific parameters are described below
* `aws`
    * A starter configuration for running the pipeline on Amazon Web Services. Uses docker and Spark.
    * See [`docs/configuration/aws.md`](configuration/aws.md)
* `standard`
    * The default profile, used if `-profile` is not specified at all. Runs locally and expects all software to be installed and available on the `PATH`.
    * This profile is mainly designed to be used as a starting point for other configurations and is inherited by most of the other profiles.
* `none`
    * No configuration at all. Useful if you want to build your own config from scratch and want to avoid loading in the default `base` config profile (not recommended).

### `--readPathsFile`
Use this to specify the location of your input FastQ files. For example:

```bash
--readPathsFile 'path/to/data/file.tsv
```
This file should have 3 columns for pair-end data and 2 columns for single-end data.
Make sure the separator between the column is a tab and not a white-space
Please see the example of the file [here](../data/read_pathes_GEUVADIS_GBR_20samples.tsv)

### `--singleEnd`
By default, the pipeline expects paired-end data. If you have single-end data, you need to specify `--singleEnd` on the command line when you launch the pipeline. 

```bash
--singleEnd 
```

### Library strandedness
Three command line flags / config parameters set the library strandedness for a run:

* `--forward_stranded`
* `--reverse_stranded`
* `--unstranded`

If not set, the pipeline will be run as unstranded. 

You can set a default in a cutom Nextflow configuration file such as one saved in `~/.nextflow/config` (see the [nextflow docs](https://www.nextflow.io/docs/latest/config.html) for more). For example:

```groovy
params {
    reverse_stranded = true
}
```

If you have a default strandedness set in your personal config file you can use `--unstranded` to overwrite it for a given run.

These flags affect the commands used for several steps in the pipeline - namely HISAT2, featureCounts, leafcutter:

* `--forward_stranded`
  * HISAT2: `--rna-strandness F` / `--rna-strandness FR`
  * featureCounts: `-s 1`
  * leafcutter: `1`
* `--reverse_stranded`
  * HISAT2: `--rna-strandness R` / `--rna-strandness RF`
  * featureCounts: `-s 2`
  * leafcutter: `2`
  
## FeatureCounts Extra Gene Names
By default, the pipeline uses `gene_names` as additional gene identifiers apart from ENSEMBL identifiers in the pipeline.
This behaviour can be modified by specifying `--fcExtraAttributes` when running the pipeline, which is passed on to featureCounts as an `--extraAttributes` parameter.
See the user guide of the [Subread package here](http://bioinf.wehi.edu.au/subread-package/SubreadUsersGuide.pdf).
Note that you can also specify more than one desired value, separated by a comma:
``--fcExtraAttributes gene_id,...``

## Alignment tool
The only supported aligner is [HISAT2](https://ccb.jhu.edu/software/hisat2/index.shtml). Developed by the same group behind the popular Tophat aligner, HISAT2 has a much smaller memory footprint.



###  `--hisat2_index`, `--gtf_hisat2_index`, `--fasta`, `--gtf_fc`, `--txrevise_gffs`, `--tx_fasta`
If you prefer, you can specify the full path to your reference genome when you run the pipeline:

```bash
--hisat2_index '[path to HISAT2 index]' \
--gtf_hisat2_index '[path to gtf file to build HISAT2 index]' \
--fasta '[path to Fasta reference]' \
--gtf_fc '[path to GTF file to be used by featureCounts]' \
--txrevise_gffs '[GFF reference files for txRevise]' \
--tx_fasta '[path to the Fasta file to be used by Salmon to quantify transcript usage]' 
```


### `--saveReference`
Supply this parameter to save any generated reference genome files to your results folder.
These can then be used for future pipeline runs, reducing processing times.

### `--saveTrimmed`
By default, trimmed FastQ files will not be saved to the results directory. Specify this
flag (or set to true in your config file) to copy these files when complete.

### `--saveAlignedIntermediates`
As above, by default intermediate BAM files from the alignment will not be saved. Set to true to also copy out BAM files from HISAT2 and sorting steps.

### `--saveIndividualQuants`
By default outputs of quantification for each individual will not be saved and only merged output quantification matrices will be saved. Set to true to also keep individual quantification files.

### `--saveInfoLogs`
By default info and log files generated while quantification process will not be saved. Set to true to also keep info and log files.


## Skipping QC steps
The pipeline contains a large number of quality control steps. Sometimes, it may not be desirable to run all of them if time and compute resources are limited.
The following options make this easy:

* `--skip_edger` -             Skip edgeR MDS plot and heatmap


## Job Resources
### Automatic resubmission
Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the steps in the pipeline, if the job exits with an error code of `143` (exceeded requested resources) it will automatically resubmit with higher requests (2 x original, then 3 x original). If it still fails after three times then the pipeline is stopped.

### Custom resource requests
Wherever process-specific requirements are set in the pipeline, the default value can be changed by creating a custom config file. See the files in [`conf`](../conf) for examples.

## AWS Batch specific parameters
Running the pipeline on AWS Batch requires a couple of specific parameters to be set according to your AWS Batch configuration. Please use the `-awsbatch` profile and then specify all of the following parameters.
### `--awsqueue`
The JobQueue that you intend to use on AWS Batch.
### `--awsregion`
The AWS region to run your job in. Default is set to `eu-west-1` but can be adjusted to your needs.

Please make sure to also set the `-w/--work-dir` and `--outdir` parameters to a S3 storage bucket of your choice - you'll get an error message notifying you if you didn't.

###
## Other command line parameters
### `--outdir`
The output directory where the results will be saved.


### `-name`
Name for the pipeline run. If not specified, Nextflow will automatically generate a random mnemonic.

This is used in the MultiQC report (if not default) and in the summary HTML / e-mail (always).

**NB:** Single hyphen (core Nextflow option)

### `-resume`
Specify this when restarting a pipeline. Nextflow will used cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

**NB:** Single hyphen (core Nextflow option)

### `-c`
Specify the path to a specific config file (this is a core NextFlow command).

**NB:** Single hyphen (core Nextflow option)

### `--max_memory`
Use to set a top-limit for the default memory requirement for each process.
Should be a string in the format integer-unit. eg. `--max_memory '8.GB'``

### `--max_time`
Use to set a top-limit for the default time requirement for each process.
Should be a string in the format integer-unit. eg. `--max_time '2.h'`

### `--max_cpus`
Use to set a top-limit for the default CPU requirement for each process.
Should be a string in the format integer-unit. eg. `--max_cpus 1`

### `--clusterOptions`
Submit arbitrary cluster scheduler options (not available for all config profiles). For instance, you could use `--clusterOptions '-p devcore'` to run on the development node (though won't work with default process time requests).

## Stand-alone scripts
The `bin` directory contains some scripts used by the pipeline which may also be run manually:

* `dexseq/*`
  * Script used to prepare annotation for exon expression
* `edgeR_heatmap_MDS.r`
  * edgeR script used in the _Sample Correlation_ process
