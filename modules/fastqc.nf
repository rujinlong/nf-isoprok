process FASTQC {
    tag "$sampleID"
    
    input:
    tuple val(sampleID), path(reads)

    output:
    path("*_fastqc.{zip,html}"), emit: fastqc_results_ch

    when:
    params.mode == "fastqc" || params.mode == "clean" || params.mode == "all"

    """
    fastqc -t $task.cpus $reads
    """
}
