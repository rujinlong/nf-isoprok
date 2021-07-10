#!/usr/bin/env nextflow
// Usage: nextflow run phanno.nf -profile hpc_slurm --mode "all" -resume --predictor prodigal

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


workflow {
    if( params.contigs != "false" ) {
            contigs_ch = channel.fromPath(params.contigs)
    }
    else {
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

    RAGTAG(ref_ch, ASSEMBLY_SPADES.out.contigs_ch)
    DFAST(RAGTAG.out.genome_ch)
    ANNO_ARG(DFAST.out.cds_ch)
}

    