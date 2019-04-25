# Running Transcript, Exon, Alternative Splicing and TxRevise expression quantification
With default parameters this pipeline will only quantify gene expression. Other phenotypes can be quantified with providing the necessary parameters.

## Running Transcript Expression Quantification
Pipeline uses [Salmon](https://combine-lab.github.io/salmon/) tool to quantify transcript expression.
In order to run transcript expression quantification the following parameters should be provided:

### `--run_tx_exp_quant`
Flag to enable transcript level quantification. Default value of the parameter is **false** 

### `--tx_fasta`
Path of the reference transcriptome file (fasta). By default this file is downloaded from [gencode reference transcriptome](ftp://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_29/gencode.v29.transcripts.fa.gz).

Archived (fa.gz) file is also accepted as a value to this parameter

For example:

```bash
--run_tx_exp_quant --tx_fasta '/rnaseq/annotation/reference_transcriptome/gencode.v29.transcripts.fa.gz'
```

You can set a default in a cutom Nextflow configuration file such as one saved in `~/.nextflow/config` (see the [nextflow docs](https://www.nextflow.io/docs/latest/config.html) for more). For example:

```groovy
params {
    run_tx_exp_quant = true
    tx_fasta = """$baseDir/annotation/reference_transcriptome/gencode.v29.transcripts.fa.gz"""
}
```
---
## Running Exon Expression Quantification
Pipeline uses [DEXseq](https://bioconductor.org/packages/release/bioc/vignettes/DEXSeq/inst/doc/DEXSeq.pdf) tool to quantify exon expression.
In order to run exon expression quantification the following parameters should be provided:

### `--run_exon_quant`
Flag to enable exon level quantification. Default value of the parameter is **false** 

For example:

```bash
--run_exon_quant
```

```groovy
params {
    run_exon_quant = true
}
```
---
## Running Alternative Splicing Expression Quantification
Pipeline uses [LeafCutter](https://github.com/davidaknowles/leafcutter) tool to quantify alternative splicing expression.
In order to run exon expression quantification the following parameters should be provided:

### `--run_splicing_exp_quant`
Flag to enable alternative splicing level quantification. Default value of the parameter is **false** 

For example:

```bash
--run_splicing_exp_quant
```

```groovy
params {
    run_splicing_exp_quant = true
}
```
---
## Running Txrevise Expression Quantification
[TxRevise](https://elifesciences.org/articles/41673) is a quantification method is based on running Salmon tool with customly designed reference transcriptome to quantify expression level of specific events.
In order to run TxRevise the following parameters should be provided:

### `--run_txrevise`
Flag to enable alternative splicing level quantification. Default value of the parameter is **false** 

### `--txrevise_gffs`
Path of the customly designed reference transcriptome(s).

### `--fasta`
Path of the fasta reference genome. 


For example:

```bash
--run_txrevise\
 --txrevise_gffs 'annotation/txrevise_gff/*.gff3'\
 --fasta 'annotation/GRCh38/Homo_sapiens.GRCh38.dna.primary_assembly.fa'
```

```groovy
params {
    run_txrevise = true
    txrevise_gffs = """$baseDir/annotation/txrevise_gff/*.gff3"""
    fasta = """$baseDir/annotation/GRCh38/Homo_sapiens.GRCh38.dna.primary_assembly.fa"""
}
```
---
