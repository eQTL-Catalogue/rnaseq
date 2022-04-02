# nfcore/rnaseq Installation

To start using the eQTL-Catalogue/rnaseq pipeline, there are three steps described below:

- [nfcore/rnaseq Installation](#nfcorernaseq-installation)
  - [1) Install NextFlow](#1-install-nextflow)
  - [2) Install the Pipeline](#2-install-the-pipeline)


## 1) Install NextFlow
Nextflow runs on most POSIX systems (Linux, Mac OSX etc). It can be installed by running the following commands:

```bash
# Make sure that Java v7+ is installed:
java -version

# Install Nextflow
curl -fsSL get.nextflow.io | bash

# Add Nextflow binary to your PATH:
mv nextflow ~/bin/
# OR system-wide installation:
# sudo mv nextflow /usr/local/bin
```

**You need NextFlow version >= 0.24 to run this pipeline.**

See [nextflow.io](https://www.nextflow.io/) and [NGI-NextflowDocs](https://github.com/SciLifeLab/NGI-NextflowDocs) for further instructions on how to install and configure Nextflow.

## 2) Install the Pipeline
First clone the GitHub repository

```bash
git clone https://github.com/eQTL-Catalogue/rnaseq.git
cd rnaseq

nextflow run main.nf [...parameters...]
```

