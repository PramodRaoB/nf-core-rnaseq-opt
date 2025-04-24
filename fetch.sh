#!/bin/bash

# Define color codes for output styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} ${1}"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} ${1}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} ${1}"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} ${1}"
}

log_section() {
    echo -e "\n${BOLD}${BLUE}====== ${1} ======${NC}\n"
}

# Error handling function
handle_error() {
    log_error "An error occurred during: ${1}"
    log_error "Exit code: $2"
    exit $2
}

# Function to check command success
check_command() {
    if [ $1 -ne 0 ]; then
        handle_error "$2" $1
    else
        log_success "$2 completed successfully."
    fi
}

# Function to check if a file exists
check_file_exists() {
    if [ ! -f "$1" ]; then
        log_error "File not found: $1"
        exit 1
    else
        log_info "Using samplesheet: $1"
    fi
}

# Install nextflow
install_nextflow() {
    curl -s https://get.nextflow.io | bash
    if [ ! -f "./nextflow" ]; then
        log_error "Could not install nextflow"
        exit 1
    fi
    chmod +x nextflow
    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    export PATH="$SCRIPT_DIR:$PATH"
}

# Install nf-core tools
install_nf() {
    pip install nf-core
    check_command $? "Installing nf-core tools"
}

# Main function
main() {
    java -version
    check_command $? "Checking java installation"
    
    # Install nextflow
    log_section "Installing nextflow"
    install_nextflow

    # Install nf-core tools
    log_section "Installing nf-core tools"
    install_nf

    log_success "Installed nextflow and nf-core successfully"

    # Download the rnaseq pipeline
    log_section "Fetching rnaseq 3.14.0 pipeline"
    log_info "Fetching pipeline and singularity images now..."
    nf-core pipelines download -s singularity -r 3.14.0 -x none -u copy -o rnaseq rnaseq
    check_command $? "Fetching nf-core/rnaseq pipeline"

    cp 3_14_0/ rnaseq -r

    # Download the optimized singularity images
    pip install gdown
    check_command $? "Installing gdown"
    gdown --folder https://drive.google.com/drive/folders/1r_CyQzVlR7y6-8ANZjH8pblpoPCA23sE
    check_command $? "Fetching optimized singularity images"
    mv ./Optimized\ NF\ Images/* ./rnaseq/singularity-images/
    
    # Fetch the datasets
    log_section "Fetching datasets"
    log_info "Fetching datasets and reference genomes now..."
    latest_release=$(curl -s 'http://rest.ensembl.org/info/software?content-type=application/json' | grep -o '"release":[0-9]*' | cut -d: -f2)
    wget -L ftp://ftp.ensembl.org/pub/release-${latest_release}/fasta/homo_sapiens/dna/Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa.gz
    wget -L ftp://ftp.ensembl.org/pub/release-${latest_release}/gtf/homo_sapiens/Homo_sapiens.GRCh38.${latest_release}.gtf.gz
    nextflow run nf-core/fetchngs \
    	-c ./custom.config \
    	-profile singularity \
    	--input ./fetch.csv \
    	--nf_core_pipeline rnaseq \
    	--outdir ./fetched/
    check_command $? "Fetching datasets"
}

# Call main function with all arguments
main "$@"
