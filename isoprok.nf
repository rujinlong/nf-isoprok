#!/usr/bin/env nextflow
// Usage: nextflow run phanno.nf -profile hpc_slurm --mode "all" -resume --predictor prodigal
// nextflow run isoprok.nf -profile hpc_slurm --mode "all" -resume --predictor prodigal --reads "data/*_R{1,2}.fq.gz" --ref_genome CP000521.1.fna

nextflow.enable.dsl=2

log.info """\
NF-PHANNO PIPELINE
==================
Result: ${params.outdir}
Report: ${params.report}
Minimum contig length: ${params.contig_minlen} bp
"""

include { FASTQC } from './modules/fastqc'
include { CLEAN_READS } from './modules/clean_reads'
include { ASSEMBLY_SPADES } from './modules/assembly_spades'
include { RAGTAG } from './modules/draft_genome'
include { DFAST } from './modules/draft_annotation'
include { ANNO_ARG } from './modules/anno_ARG'
include { MULTIQC } from './modules/multiqc'


workflow {
    raw_reads_ch = channel.fromFilePairs(params.reads)
    FASTQC(raw_reads_ch)
    CLEAN_READS(raw_reads_ch)
    ASSEMBLY_SPADES(CLEAN_READS.out.clean_reads_deduped_ch)

    if( params.mode == "fastqc" ) {
        MULTIQC(FASTQC.out.fastqc_results_ch.collect())
    }
    else {
        MULTIQC(FASTQC.out.fastqc_results_ch.flatten().concat(CLEAN_READS.out.fastp_json_ch.flatten()).collect())
    }

    if( params.ref_genome ) {
        ref_ch = channel.fromPath(params.ref_genome)
        RAGTAG(ref_ch, ASSEMBLY_SPADES.out.contigs_ch)
        draft_genome = RAGTAG.out.genome_ch
    } else {
        draft_genome = ASSEMBLY_SPADES.out.contigs_ch
    }

    DFAST(draft_genome)
    ANNO_ARG(DFAST.out.cds_ch)
}

    
