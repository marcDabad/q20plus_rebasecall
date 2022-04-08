# Q20 rebasecalling

This pipeline is based on ONT instructions to rebasecall Q20+ samples.

It does simplex + 2 step duplex_tools + duplex call + MinIONQC.R

## Dependencies
- [Conda](https://docs.conda.io/en/latest/) or [Mamba](https://github.com/mamba-org/mamba)
- [Snakemake](https://snakemake.github.io/) 
- [Guppy](https://community.nanoporetech.com/)
- [Duplex_tools](https://github.com/nanoporetech/duplex-tools/)
- [Fastq_merge](https://github.com/heathsc/fastq_merge)
- [minion_qc ]( https://github.com/roblanf/minion_qc )

## Config file
Example of config.yaml fill:

```yaml
Flowcell_id: "FZZ0000"
RawData: "/data/path/Q20_RawData/FZZ0000"
modelFile: "dna_r10.4_e8.1_sup.cfg"
modelPath: "/software//guppy/ont-guppy_5.0.1X/data"
cuda: "cuda:0"
firstCall:
  gpu_runners: 20
secondCall:
  gpu_runners: 20
bin:
  guppy_bin: "/software/guppy/ont-guppy_5.0.1X/bin"
  guppy_duplex_bin: "/software/guppy/ont-guppy_0.0.0_duplexbeta/bin"
  duplex_tool: "/home/user/.local/bin/"
  minionqc: "/software/minion_qc/minion_qc-1.4.2/"
  fastq_merge_bin: "/software/fastq_merge/0.2.0/bin/"
```

It generates all output folders and outputs at current working directory. 
A best practice will be create a new folder called `${Flowcell_id}_Analysis` and run 
the pipeline form it. 

## Run
```bash
snakemake -s /path/to/Snakefile --configfile config.yaml --use-conda  -j ${cores}
```

> If you didn't installed `mamba`, you have to add `--conda-frontend conda`.

### Extra
If you want to save space and time, you can run a first run, once, with this two paramaters extra:

```bash
 --conda-create-envs-only --conda-prefix /path/to/prefix
```

Then, you will specify in each run `--conda-prefix` and will use these environments.

If you copy the `Snakefile` you don't need to specify `-s`
