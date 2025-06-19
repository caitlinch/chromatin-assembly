# DANPOS3

Download DANPOS3 from: https://github.com/sklasfeld/DANPOS3


## Why is DANPOS included in the pipeline?

DANPOS3 is provided within this workflow because the original implementation on the CSIRO HPC system Petrichor had a known issue: https://www.biostars.org/p/457084/

This version is identical to 3.1.1 on Petrichor with the following exceptions:

- Within the file `reads.py`, the original script had the function `isunmapped`. `isunmapped` is not a function from pysam.AlignmentFile (the pysam python package). Both instances have been replaced with the correct function name `is_unmapped`.

## DANPOS3 requirements

- Package and Library versions
	- Python 3.7.6
	- R version 4.0.1
	- samtools 1.7 using htslib 1.7
- Python Libraries
	- rpy2 3.3.3
	- argparse 1.1
	- numpy 1.18.5
	- pysam 0.16.0.1
