fc = config["Flowcell_id"]
guppy_bin = config["bin"]["guppy_bin"]
guppyduplex_bin = config["bin"]["guppy_duplex_bin"]
duplextools_bin = config["bin"]["duplex_tool"]
fastq_merge_bin = config["bin"]["fastq_merge_bin"]
MinIONQC = config["bin"]["minionqc"] 

rule all:
    input: 
        "{fc}_FastqMerge/MinIONQC_Q7".format(fc=fc),
        "{fc}_FastqMerge/sequencing_summary.txt".format(fc=fc),
        "{fc}_DuplexTool/pair_ids_filtered.txt".format(fc=fc),
        "{fc}_SecondBasecall/sequencing_summary.txt".format(fc=fc)


rule FirstBasecaller:
    input:
        config["RawData"]
    output:
        outdir = directory("{fc}_FirstBasecall"),
        seqsum = "{fc}_FirstBasecall/sequencing_summary.txt"
    threads: 10
    params:
        model_path=config["modelPath"],
        model=config["modelFile"],
        gpu_runners=config["firstCall"]["gpu_runners"],
        device=config["cuda"],
    log:
        "{fc}_FirstBasecaller.log",
    shell:
        """
	mkdir -p {output.outdir}
        {guppy_bin}/guppy_basecaller \
            -r --fast5_out \
            --device {params.device} \
            -i {input} \
            -s {output.outdir} \
            -d {params.model_path} \
            -c {params.model} \
            --num_callers 20 \
            --gpu_runners_per_device {params.gpu_runners} \
            2> {log}
        """


rule DuplexPair:
    input:
        "{fc}_FirstBasecall/sequencing_summary.txt",
    output:
        outdir = directory("{fc}_DuplexTool"), 
        pairids="{fc}_DuplexTool/pair_ids.txt"
    conda:
        "env/duplextool.yaml" 
    log:
        "{fc}_DuplexPair.log",
    shell:
        """
	mkdir -p {output.outdir}
        {duplextools_bin}/duplex_tools pairs_from_summary \
            {input} {output.outdir}/. 2> {log}
        """


rule DuplexFilter:
    input:
        "{fc}_DuplexTool/pair_ids.txt",
    output:
        pair_filtered="{fc}_DuplexTool/pair_ids_filtered.txt"
    params:
        FirstBasecall="{fc}_FirstBasecall",
    conda:
        "env/duplextool.yaml"
    log:
        "{fc}_DuplexFilter.log",
    shell:
        """
        {duplextools_bin}/duplex_tools filter_pairs \
            {input} \
            {params.FirstBasecall} 2>{log}
        """


rule GuppyDuplex:
    input:
        rawData=config["RawData"],
        pair_filtered="{fc}_DuplexTool/pair_ids_filtered.txt"
    output:
        outdir = directory("{fc}_SecondBasecall"),
        seqsum = "{fc}_SecondBasecall/sequencing_summary.txt"


    params:
        model_path=config["modelPath"],
        model=config["modelFile"],
        gpu_runners=config["secondCall"]["gpu_runners"],
        device=config["cuda"],
    log:
        "{fc}_GuppyDuplex.log",
    threads: 10
    shell:
        """
	mkdir -p {output.outdir}
        {guppyduplex_bin}/guppy_basecaller_duplex \
            --compress_fastq \
	    -r \
            -i {input.rawData} \
            -s {output.outdir} \
            -d {params.model_path} \
            -c {params.model} \
            --duplex_pairing_mode from_pair_list \
            --duplex_pairing_file {input.pair_filtered} \
            -x {params.device} \
            --chunk_size 1000 \
            --chunks_per_runner 20 \
            --read_batch_size 1000 \
            --gpu_runners_per_device {params.gpu_runners} \
            2>{log}
        """

rule fastqMerge:
    input:
        FirstBasecall="{fc}_FirstBasecall",
        SecondBasecall="{fc}_SecondBasecall",
    output:
        fastq="{fc}_FastqMerge/{fc}_merged.fastq.gz",
        report="{fc}_FastqMerge/{fc}_merged.report.log",
        seqsum="{fc}_FastqMerge/sequencing_summary.txt",
    #conda:
    #    "env/fastqmerged.yaml"
    log:
        "{fc}_fastqMerge.log",
    shell:
        """
	mkdir -p {fc}_FastqMerge
	{fastq_merge_bin}/fastq_merge -r {output.report} \
	    -S {output.seqsum} \
            {input.SecondBasecall} \
            {input.FirstBasecall} \
            | gzip -c > {output.fastq} 2>{log}
        """


rule minIONQC:
    input:
        "{fc}_FastqMerge/sequencing_summary.txt",
    output:
        directory("{fc}_FastqMerge/MinIONQC_Q7"),
    threads: 10
    conda:
        "env/minionqc.yaml"
    shell:
        """
        mkdir -p {output}
	Rscript {MinIONQC}/MinIONQC.R -p {threads} -i {input} -o {output}
        """
