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

# Main function
main() {
    if [ "$#" -ne 1 ]; then
        log_error "Usage: $0 <samplesheet_number_or_name>"
        log_info "Example: $0 1          # Uses samplesheet_1.csv"
        log_info "Example: $0 my_samples.csv  # Uses my_samples.csv"
        exit 1
    fi
    
    # Get samplesheet file path
    local param=$1
    local samplesheet
    
    # If parameter is 1, 2, 3, or 4, use corresponding samplesheet
    if [[ "$param" =~ ^[1-4]$ ]]; then
        samplesheet="./samplesheet_${param}.csv"
    else
        # Otherwise, use the parameter as the samplesheet name
        samplesheet="$param"
    fi
    
    # Check if the samplesheet exists
    if [ ! -f "$samplesheet" ]; then
        log_error "File not found: $samplesheet"
        exit 1
    fi
    log_info "Using samplesheet: $samplesheet"
    
    # Create output directory name
    local samplesheet_basename=$(basename "$samplesheet" .csv)
    local output_dir="results_${samplesheet_basename}"
    log_info "Output directory: $output_dir"
    
    # Run nfcore rnaseq
    log_section "Running nfcore rnaseq"
    
    # Check if required files/directories exist
    if [ ! -f "./Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa" ]; then
        log_error "Reference fasta file not found"
        exit 1
    fi

    if [ ! -f "./Homo_sapiens.GRCh38.111.gtf" ]; then
        log_error "GTF file not found"
        exit 1
    fi

    # Run nfcore rnaseq
    log_info "Starting nfcore rnaseq pipeline..."
    latest_release=$(curl -s 'http://rest.ensembl.org/info/software?content-type=application/json' | grep -o '"release":[0-9]*' | cut -d: -f2)
    ./nextflow -log ./nf.log \
        run ./rnaseq/3_14_0/ \
        -profile singularity \
        --input "$samplesheet" \
        --outdir "$output_dir" \
        --fasta ./Homo_sapiens.GRCh38.dna_sm.primary_assembly.fa \
        --gtf ./Homo_sapiens.GRCh38.${latest_release}.gtf
        
    check_command $? "nfcore rnaseq pipeline"
    
    log_section "Pipeline Complete"
    log_success "nfcore rnaseq pipeline completed successfully"
}

# Call main function with all arguments
main "$@"
