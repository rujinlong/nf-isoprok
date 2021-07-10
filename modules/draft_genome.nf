process RAGTAG {
    tag "$sampleID"
    label "small"
    publishDir "$params.outdir/$sampleID/p01_RagTag"
    publishDir "$params.report/$sampleID", pattern: "*.stats"

    input:
    tuple val(sampleID), path(ref_fna)
    tuple val(sampleID), path(scaffolds)

    output:
    tuple val(sampleID), path('ragtag_output/*') 
    tuple val(sampleID), path("${sampleID}_1k.fna"), emit: genome_ch
    tuple val(sampleID), path('*.stats') 

    when:
    params.mode == "all"|| params.mode == 'genome'

    """
    ragtag.py scaffold $ref_fna $scaffolds -t $task.cpus -o ragtag_output
    ln -s ragtag_output/*.stats .
    sed "s/^>/>${sampleID}_/" ragtag_output/ragtag.scaffolds.fasta | sed 's/ /_/g' > ${sampleID}.fna
    seqkit seq -m 1000 ${sampleID}.fna > ${sampleID}_1k.fna
    """
}