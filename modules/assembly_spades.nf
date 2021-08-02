process ASSEMBLY_SPADES {
    tag "$sampleID"
    publishDir "$params.outdir/$sampleID/p03_assembly", pattern: "*.fna"
    publishDir "$params.report/$sampleID", pattern: "*.fna"
    
    input:
    tuple val(sampleID), path(reads_int), path(reads_single)

    output:
    path("*")
    tuple val(sampleID), path("${sampleID}_spades.fna"), emit: contigs_ch
    tuple val(sampleID), path("${sampleID}_spades_long.fna"), emit: long_contigs_ch

    when:
    params.mode == "assembly" || params.mode == "all"

    """
    spades.py -o output_assembler --12 $reads_int -t $task.cpus -m $params.spades_mem -k 21,33,55,77,99,111 --isolate
    sed "s/^>/>${sampleID}__/" output_assembler/scaffolds.fasta | sed 's/ /_/g' > ${sampleID}_spades.fna
    seqkit seq -m $params.min_contig_length ${sampleID}_spades.fna > ${sampleID}_spades_long.fna
    """
}