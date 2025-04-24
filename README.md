# nf-core-rnaseq-opt
Modified nf-core/rnaseq pipeline to include multithreaded versions of tools and a different workflow

## Instructions to run the pipeline

### Requirements:

1. Make sure to have Java v11+ installed on your system
You can check this by running `java -version`

2. The script uses `pip` to install several packages. So, ensure that the script runs in an environment
where you have sufficient permissions to install packages.

### Fetching pipeline and datasets

1. Clone the repo and `cd` into it
```
git clone https://github.com/PramodRaoB/nf-core-rnaseq-opt`
cd nf-core-rnaseq-opt
```

3. Now, run the script
```
./fetch.sh
```

The script fetches several things:
* The sample datasets under the folder `fetched/`
* The rnaseq pipeline to be run offline under the folder `rnaseq/`
* The baseline and optimized containers for the tools
* The `nextflow` tool

### Running the pipeline

1. To run the pipeline with the sample datasets, run
```
./run.sh fetched/samplesheet/samplesheet.csv
```

3. If you wish to run it on other datasets, then create a samplesheet in the format as specified [here](https://github.com/PramodRaoB/nf-core-rnaseq-opt#)
and run the command
```
./run.sh <path to samplesheet>
```
