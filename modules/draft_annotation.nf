process DFAST {
    tag "$sampleID"
    publishDir "$params.outdir/$sampleID/p05_dfast"
    publishDir "$params.report/$sampleID", pattern: "statistics.txt"

    input:
    tuple val(sampleID), path(genome)
    
    output:
    path("dfast_output/*")
    tuple val(sampleID), path("dfast_output/genome.gbk"), emit: draft_gbk
    tuple val(sampleID), path("dfast_output/genome.fna"), emit: draft_genome_fna
    tuple val(sampleID), path("dfast_output/cds.fna"), emit: cds_ch
    tuple val(sampleID), path("protein_LOCUS.faa"), emit: protein_locus
    path("statistics.txt")

    when:
    params.mode == 'genome' || params.mode == "all"

    """
    dfast --genome ${genome} -o dfast_output --use_original_name t --cpu $task.cpus --minimum_length 30
    sed 's/>.*|LOCUS_/>LOCUS_/' dfast_output/protein.faa > protein_LOCUS.faa
    ln -s dfast_output/statistics.txt .
    """
}


process PROKKA {
    tag "$sampleID"
    publishDir "$params.outdir/$sampleID/p05_prokka"
    publishDir "$params.report/$sampleID", pattern: "output_prokka/*"

    input:
    tuple val(sampleID), path(genome)
    
    output:
    path("output_prokka/*")
    tuple val(sampleID), path("output_prokka/${sampleID}.fna"), emit: cds_ch

    when:
    params.mode == 'genome' || params.mode == "all"

    """
    if [ "$params.with_ref" == "true" ];then
        singularity exec ~/prokka.sif prokka --cpus $task.cpus --proteins $params.ref --outdir output_prokka --prefix $sampleID --rawproduct --centre X --compliant $genome
    else
        singularity exec ~/prokka.sif prokka --cpus $task.cpus --outdir output_prokka --prefix $sampleID --rawproduct --centre X --compliant $genome
    fi
    """
}
