process MULTIQC {
    publishDir "$params.outdir/p98_multiqc"
    
    input:
    file(qc_rst)

    output:
    file("*")

    when:
    params.mode == "fastqc" || params.mode == "clean" || params.mode == "all"

    """
    multiqc -o . -n multiqc -s --interactive .
    """
}

