# Running The pipeline with the test data
Test data contains 20 open-access pair-end RNAseq samples from [GEUVADIS](https://www.nature.com/articles/nature12531) study.

To execute the pipeline with reference and annotation files they should be manually downloaded first:
```bash
# Make sure you are in the root directory of the pipeline (where the main.nf is located)
wget ftp://ftp.ebi.ac.uk/pub/databases/spot/eQTL/references/rnaseq_complete_reference_290322.tar.gz
tar -xzvf rnaseq_complete_reference_290322.tar.gz
rm rnaseq_complete_reference_290322.tar.gz
```

After these steps you should have `rnaseq_complete_reference` folder in the pipeline directory.

Then you can start the pipeline using `test` profile
```bash
nextflow run main.nf -profile test
```

If you have a specific needs for your local cluster please prepare the configuration file accordingly.
As example you cna check-out [configuration file prepared for University of Tartu HPC](../conf/tartu_hpc.config)

Users of University of Tartu HPC can run the pipeline with test dataset using the pre-generated sbatch script:
```bash
sbatch run_GEUVADIS_test.sh
```
