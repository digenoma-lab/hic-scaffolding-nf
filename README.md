

# Hi-C Scaffolding Nextflow Pipeline

![Nextflow](https://img.shields.io/badge/Nextflow-%E2%89%A520.04.0-brightgreen)  
A Nextflow pipeline for scaffolding genome assemblies using Hi-C reads with [CHROMAP][chromap], [YAHS][yahs], and [Juicer Tools][juicer_tools].

---

## Table of Contents
- [Introduction](#introduction)
- [Quick Start](#quick-start)
- [Inputs](#inputs)
- [Outputs](#outputs)
- [Dependencies](#dependencies)
- [Configuration](#configuration)
  - [Running on Lewis Cluster](#running-on-lewis-cluster)
  - [Running Locally/Elsewhere](#running-locally-or-on-other-clusters)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)
- [References](#references)

---

## Introduction
This pipeline scaffolds draft genome assemblies using Hi-C data in three steps:
1. **Alignment**: Hi-C reads are mapped to contigs using [CHROMAP][chromap].
2. **Scaffolding**: Contigs are ordered/oriented using [YAHS][yahs].
3. **Visualization**: Prepares files for manual curation in [Juicebox][juicer_tools].

---

## Quick Start
```bash
nextflow run digenoma-lab/hic-scaffolding-nf \
    --contigs contigs.fa \
    --r1Reads hic_R1.fastq.gz \
    --r2Reads hic_R2.fastq.gz \
    -profile conda  # Use conda for dependencies
```

---

## Inputs
| Parameter     | Format               | Description                     |
|--------------|----------------------|---------------------------------|
| `--contigs`  | FASTA                | Draft assembly contigs.         |
| `--r1Reads`  | FASTQ(.gz)           | Hi-C paired-end reads (R1).     |
| `--r2Reads`  | FASTQ(.gz)           | Hi-C paired-end reads (R2).     |

---

## Outputs
Directory               | Files                          | Description
------------------------|--------------------------------|-----------------------------
`out/chromap/`          | `aligned.bam`                  | Hi-C read alignments.
`out/scaffolds/`        | `yahs.out_scaffolds_final.fa`  | Scaffolded assembly (FASTA).
`out/scaffolds/`        | `yahs.out_scaffolds_final.agp` | AGP file for scaffolding.
`out/juicebox_input/`   | `out_JBAT.hic`                 | Juicebox-compatible Hi-C map.
`out/juicebox_input/`   | `out_JBAT.assembly`            | Assembly file for Juicebox.

---

## Dependencies
- **Core**:
  - [Nextflow][nextflow] (≥20.04.0)
  - [CHROMAP][chromap] (alignment)
  - [YAHS][yahs] (scaffolding)
  - [Juicer Tools][juicer_tools] (visualization)

Install Juicer Tools:
```bash
wget http://hicfiles.tc4ga.com.s3.amazonaws.com/public/juicer/juicer_tools_1.11.09_jcuda.0.8.jar
```

---

## Configuration

### Running Locally or on Other Clusters
1. **Conda** (recommended for CHROMAP/YAHS):
   ```bash
   -profile conda
   ```
2. **Manual dependency paths**:
   ```bash
   --juicer_tools_jar /path/to/juicer_tools.jar
   ```

Add custom paths in `nextflow.config`:
```nextflow
params {
  juicer_tools_jar = "/path/to/juicer_tools.jar"
}
```

---

## Examples

### Basic Run
```bash
nextflow run hic-scaffolding-nf/main.nf \
    --contigs sl_female_ont_purge_r2.fasta \
    --r1Reads DDU_AAOSDF_4_1_HFYVJDSX7.UDI488_clean.fastq.gz \
    --r2Reads DDU_AAOSDF_4_2_HFYVJDSX7.UDI488_clean.fastq.gz \
    -profile uoh  # Example profile
```

---

## Troubleshooting
- **Missing files**: Ensure all input paths are correct.
- **Conda issues**: Use `-profile conda` or install dependencies manually.
- **Juicer Tools**: Specify the JAR path with `--juicer_tools_jar`.

---

## References
- [CHROMAP][chromap]  
- [YAHS][yahs]  
- [Juicer Tools][juicer_tools]  
- [Nextflow Docs][nextflow]  

[nextflow]: https://www.nextflow.io/
[chromap]: https://github.com/haowenz/chromap
[yahs]: https://github.com/c-zhou/yahs
[juicer_tools]: https://github.com/aidenlab/JuicerTools
