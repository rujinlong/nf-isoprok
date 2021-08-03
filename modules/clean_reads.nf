process CLEAN_READS {
    tag "$sampleID"
    publishDir "$params.outdir/$sampleID/p02_reads_clean", pattern: "*.gz"
    
    input:
    tuple val(sampleID), path(reads)

    output:
    path("*.json"), emit: fastp_json_ch
    path("*.fq.gz"), emit: fastp_reads_ch
    tuple val(sampleID), path("${sampleID}_clean_nc.fq.gz"), path("${sampleID}_singletons_nc.fq.gz"), emit: clean_reads_ch
    tuple val(sampleID), path("${sampleID}_clean_nc_deduped.fq.gz"), path("${sampleID}_singletons_nc_deduped.fq.gz"), emit: clean_reads_deduped_ch
    tuple val(sampleID), path("${sampleID}_clean_norm.fq.gz"), path("${sampleID}_singletons_norm.fq.gz"), emit: norm_reads_ch

    when:
    params.mode == "clean" || params.mode == "all"

    script:
    """
    fastp -i ${reads[0]} -I ${reads[1]} -o ${sampleID}_clean_R1.fq.gz -O ${sampleID}_clean_R2.fq.gz --unpaired1 ${sampleID}_singletons.fq.gz --unpaired2 ${sampleID}_singletons.fq.gz --failed_out ${sampleID}_fail.fq.gz -f $params.leftcutR1 -t $params.rightcutR1 -F $params.leftcutR2 -T $params.rightcutR2 --detect_adapter_for_pe -p -w $task.cpus -n 1 -l 20 -W 4 -M 15 -r -c -g -x -j ${sampleID}_fastp.json -h ${sampleID}_fastp.html
    mem=\$(echo ${task.memory} | sed 's/ //g' | sed 's/B//g')
    echo "Using memory \$mem"
    if [ "$params.decontam" == "true" ];then
        bbmap.sh minid=0.99 maxindel=1 bwr=0.16 bw=12 quickmatch fast minhits=2 path=$params.decontam_ref qtrim=rl trimq=10 pigz=True threads=$task.cpus untrim -Xmx\$mem in=${sampleID}_clean_R1.fq.gz in2=${sampleID}_clean_R2.fq.gz outu=${sampleID}_clean_nc.fq.gz interleaved=true
        bbmap.sh minid=0.99 maxindel=1 bwr=0.16 bw=12 quickmatch fast minhits=2 path=$params.decontam_ref qtrim=rl trimq=10 pigz=True threads=$task.cpus untrim -Xmx\$mem in=${sampleID}_singletons.fq.gz outu=${sampleID}_singletons_nc.fq.gz interleaved=false
    else
        reformat.sh in1=${sampleID}_clean_R1.fq.gz in2=${sampleID}_clean_R2.fq.gz out=${sampleID}_clean_nc.fq.gz
        ln -s ${sampleID}_singletons.fq.gz ${sampleID}_singletons_nc.fq.gz
    fi
    
    dedupe.sh -Xmx\$mem  in=${sampleID}_clean_nc.fq.gz out=${sampleID}_clean_nc_deduped.fq.gz ac=f threads=$task.cpus interleaved=true
    dedupe.sh -Xmx\$mem  in=${sampleID}_singletons_nc.fq.gz out=${sampleID}_singletons_nc_deduped.fq.gz ac=f threads=$task.cpus interleaved=false

    if [ "$params.normalize" == "true" ];then
        bbnorm.sh -Xmx\$mem in=${sampleID}_clean_nc_deduped.fq.gz out=${sampleID}_clean_norm.fq.gz target=$params.norm_max min=$params.norm_min threads=$task.cpus interleaved=true
        bbnorm.sh -Xmx\$mem in=${sampleID}_singletons_nc_deduped.fq.gz out=${sampleID}_singletons_norm.fq.gz target=$params.norm_max min=$params.norm_min threads=$task.cpus interleaved=false
    else
        ln -s ${sampleID}_clean_nc_deduped.fq.gz ${sampleID}_clean_norm.fq.gz
        ln -s ${sampleID}_singletons_nc_deduped.fq.gz ${sampleID}_singletons_norm.fq.gz
    fi
    """
}
