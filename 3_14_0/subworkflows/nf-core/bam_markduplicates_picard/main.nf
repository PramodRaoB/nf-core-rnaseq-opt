//
// Picard MarkDuplicates, index BAM file and run samtools stats, flagstat and idxstats
//

include { PICARD_MARKDUPLICATES } from '../../../modules/nf-core/picard/markduplicates/main'
include { SAMTOOLS_INDEX        } from '../../../modules/nf-core/samtools/index/main'
include { BAM_STATS_SAMTOOLS    } from '../bam_stats_samtools/main'

workflow BAM_MARKDUPLICATES_PICARD {
    take:
    ch_bam         // channel: [ val(meta), path(bam), path(bai) ]
    ch_fasta       // channel: [ val(meta), path(fasta) ]
    ch_fai         // channel: [ val(meta), path(fai) ]
    ch_bedgraph    // channel: [ val(meta), path(bedgraph) ]

    main:
    ch_versions = Channel.empty()

    // Join BAM with bedgraph data
    ch_bam_with_bg = ch_bam
        .map { meta, bam, bai -> [meta.id, meta, bam, bai] }
        .cross(ch_bedgraph.map { meta, bg -> [meta.id, bg] })
        .map { bam_data, bg_data ->
            def id = bam_data[0]
            def meta = bam_data[1]
            def bam = bam_data[2]
            def bai = bam_data[3]
            def bg = bg_data[1]
            [meta, bam, bai, bg]
        }

    // Run Picard MarkDuplicates
    PICARD_MARKDUPLICATES (
        ch_bam_with_bg,
        ch_fasta,
        ch_fai
    )
    ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions.first())

    // Index the marked BAM file
    SAMTOOLS_INDEX (PICARD_MARKDUPLICATES.out.bam)
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    // Prepare channel for BAM stats
    ch_bam_bai = PICARD_MARKDUPLICATES.out.bam
        .join(SAMTOOLS_INDEX.out.bai, by: [0], remainder: true)
        .join(SAMTOOLS_INDEX.out.csi, by: [0], remainder: true)
        .map {
            meta, bam, bai, csi ->
                if (bai) {
                    [ meta, bam, bai ]
                } else {
                    [ meta, bam, csi ]
                }
        }

    // Run stats on marked BAM file
    BAM_STATS_SAMTOOLS (ch_bam_bai, ch_fasta)
    ch_versions = ch_versions.mix(BAM_STATS_SAMTOOLS.out.versions)

    emit:
    bam      = PICARD_MARKDUPLICATES.out.bam     // channel: [ val(meta), path(bam) ]
    metrics  = PICARD_MARKDUPLICATES.out.metrics // channel: [ val(meta), path(metrics) ]
    bai      = SAMTOOLS_INDEX.out.bai                    // channel: [ val(meta), path(bai) ]
    csi      = SAMTOOLS_INDEX.out.csi                    // channel: [ val(meta), path(csi) ]
    stats    = BAM_STATS_SAMTOOLS.out.stats              // channel: [ val(meta), path(stats) ]
    flagstat = BAM_STATS_SAMTOOLS.out.flagstat           // channel: [ val(meta), path(flagstat) ]
    idxstats = BAM_STATS_SAMTOOLS.out.idxstats           // channel: [ val(meta), path(idxstats) ]
    versions = ch_versions                               // channel: [ versions.yml ]
}
