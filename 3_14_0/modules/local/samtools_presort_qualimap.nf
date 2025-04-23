process SAMTOOLS_PRESORT_QUALIMAP {
    tag "$meta.id"
    label 'process_medium'

    conda "bioconda::samtools=1.17"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.17--h00cdaf9_0' :
        'biocontainers/samtools:1.17--h00cdaf9_0' }"

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.namesorted.bam"), emit: bam
    path "versions.yml"                      , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    samtools sort \\
        -n \\
        $args \\
        -@ $task.cpus \\
        -o ${prefix}.namesorted.bam \\
        $bam

    # First write version to a temp file to check output
    samtools --version | head -n1 | cut -d ' ' -f 2 > samtools_version.txt

    # Echo the entire versions.yml content before writing
    echo "Writing versions.yml with content:" > versions_debug.txt
    echo "${task.process}:" >> versions_debug.txt
    echo "    samtools: \$(cat samtools_version.txt)" >> versions_debug.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        samtools: \$(cat samtools_version.txt)
    END_VERSIONS

    #cat <<-END_VERSIONS > versions.yml
    #"${task.process}":
    #    samtools: \$(echo \$(samtools --version 2>&1) | sed 's/^.*samtools //; s/Using.*\$//')
    #END_VERSIONS
    """
}
