#!/usr/bin/env nextflow


nextflow.enable.dsl = 2





// Validate inputs
def checkPath(path, paramName) {
    if (!file(path).exists()) {
        log.error "ERROR: File not found for --${paramName}: ${path}"
        exit 1
    }
}



// Check required parameters
def checkParams() {
    def required = ["r1Reads", "r2Reads", "contigs"]
    def missing = required.findAll { !params.containsKey(it) }
    if (missing) {
        log.error "Missing required parameters: ${missing.join(', ')}"
        exit 1
    }
}

checkParams()
checkPath(params.r1Reads, "r1Reads")
checkPath(params.r2Reads, "r2Reads")
checkPath(params.contigs, "contigs")




process PRINT_VERSIONS {

    publishDir "$params.outdir/chromap", mode: "copy" 

 //singularity and nextflow container
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' :
        'community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' }"
    
  output:
    path("versions.txt")

    """
    echo "Chromap: \$(chromap --version 2>&1)" > versions.txt
    echo "YAHS: \$(yahs --version)" >> versions.txt
    java -jar $params.juicerToolsJar -V | grep Version >> versions.txt
    echo "assembly-stats: \$(assembly-stats -v)" >> versions.txt
    """
}

process SAMTOOLS_FAIDX {

 //singularity and nextflow container
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' :
        'community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' }"
 
    input:
    path(contigsFasta)

    output:
    path("${contigsFasta}.fai")

    """
    samtools faidx $contigsFasta
    """
}

process CHROMAP_INDEX {

 //singularity and nextflow container
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' :
        'community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' }"

    input:
    path(contigsFasta)

    output:
    path("contigs.index")
   

    script:
    def pchr=""
    if(params.large==true){
	pchr=" -k 21 -w 14 "
    }
    """
    chromap -i $pchr -r $contigsFasta -o contigs.index
    """
}

process CHROMAP_ALIGN {
    
    publishDir "$params.outdir/chromap", mode: "copy" 

 //singularity and nextflow container
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' :
        'community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d'}"

    input:
    path(contigsFasta)
    path(contigsChromapIndex)
    path(r1Reads)
    path(r2Reads)

    output:
    path("aligned.bam")

   script:
    def pchr=""
    if(params.large==true){
	pchr=" -k 21 -w 14 "
    }

    """
    chromap \
        --preset hic \
        -r $contigsFasta \
        -x $contigsChromapIndex \
        --remove-pcr-duplicates \
        -1 $r1Reads \
        -2 $r2Reads \
        --SAM $pchr \
        -o aligned.sam \
        -t ${task.cpus}

    samtools view -@4 -h aligned.sam | sed 's:/[12]\\b::' | samtools view -@4 -Sb - | samtools sort -@6 -m 5G -n -o aligned.bam -

    """
}

process YAHS_SCAFFOLD {

    publishDir "$params.outdir/scaffolds", mode: "copy"

 //singularity and nextflow container
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' :
        'community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d'}"
 
    input:
    path("contigs.fa")
    path("contigs.fa.fai")
    path("aligned.bam")

    output:
    path("yahs.out.bin"), emit: bin
    path("yahs.out_scaffolds_final.agp"), emit: agp
    path("yahs.out_scaffolds_final.fa"), emit: fasta

    """
    yahs contigs.fa aligned.bam
    """
}

process JUICER_PRE {

    publishDir "$params.outdir/juicebox_input", mode: "copy"

    input:
    path("yahs.out.bin")
    path("yahs.out_scaffolds_final.agp")
    path("contigs.fa.fai")

    output:
    path("out_JBAT.*")

    """
    juicer pre -a -o out_JBAT \
        yahs.out.bin \
        yahs.out_scaffolds_final.agp \
        contigs.fa.fai

    asm_size=\$(awk '{s+=\$2} END{print s}' contigs.fa.fai)
    java -Xmx36G -jar $params.juicerToolsJar \
        pre out_JBAT.txt out_JBAT.hic <(echo "assembly \${asm_size}")
    """
}

process ASSEMBLY_STATS {

    publishDir "$params.outdir/scaffolds", mode: "copy"


 //singularity and nextflow container
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' :
        'community.wave.seqera.io/library/assembly-stats_chromap_samtools_yahs:0c3cc8595aab615d' }"

    input:
    path("yahs.out_scaffolds_final.fa")

    output:
    path("assembly_stats.txt")

    """
    assembly-stats yahs.out_scaffolds_final.fa > assembly_stats.txt
    """
}

workflow {
    // TODO do a parameter check
    PRINT_VERSIONS()

    r1Reads = Channel.fromPath(params.r1Reads)
    r2Reads = Channel.fromPath(params.r2Reads)
    contigs = Channel.fromPath(params.contigs)

    SAMTOOLS_FAIDX(contigs)
    CHROMAP_INDEX(contigs)

    CHROMAP_ALIGN(contigs, CHROMAP_INDEX.out, r1Reads, r2Reads)

    YAHS_SCAFFOLD(contigs, SAMTOOLS_FAIDX.out, CHROMAP_ALIGN.out)

    JUICER_PRE(YAHS_SCAFFOLD.out.bin, YAHS_SCAFFOLD.out.agp, SAMTOOLS_FAIDX.out)

    ASSEMBLY_STATS(YAHS_SCAFFOLD.out.fasta)
}

// Workflow completion message
workflow.onComplete {
    log.info "YAHS scaffolding finished! Results saved to ${params.outdir}"
}


