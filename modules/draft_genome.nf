process RAGTAG {
    tag "$sampleID"
    publishDir "$params.outdir/$sampleID/p04_RagTag"
    publishDir "$params.report/$sampleID", pattern: "*.stats"

    input:
    path(ref_gbk)
    tuple val(sampleID), path(scaffolds)

    output:
    tuple val(sampleID), path('ragtag_output/*') 
    tuple val(sampleID), path("${sampleID}_long.fna"), emit: genome_ch
    tuple val(sampleID), path('*.stats') 

    when:
    params.mode == "all"|| params.mode == 'genome'

    """
    any2fasta -u $ref_gbk > ref.fna
    ragtag.py scaffold ref.fna $scaffolds -t $task.cpus -o ragtag_output
    ln -s ragtag_output/*.stats .
    sed "s/^>/>${sampleID}_/" ragtag_output/ragtag.scaffolds.fasta | sed 's/ /_/g' > ${sampleID}.fna
    seqkit seq -m $params.contig_minlen ${sampleID}.fna > ${sampleID}_long.fna
    """
}
