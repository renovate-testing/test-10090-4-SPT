
Primer on scheduling LSF jobs
=============================
To run a job on the HPC, you need to:

1. Create an executable script that will actually be the "meat" of the job to be run.
2. Submit it to the scheduler

You can then monitor it (if desired) with `bjobs -l`.


Create the job script
---------------------
Make sure you're in an area that will be accessible by the cluster nodes. For example, anything under `/nadeem_lab`.

Create a subdirectory:

```bash
mkdir example_job_directory
```

Then make a file called `run_example.sh` with the contents:

```bash
#!/bin/bash
N=$1
for i in $(seq 1 1 $N);
do
    COUNT=$(( COUNT + 1 ))
done

echo "COUNT value in the end was: $COUNT"
```

Submit to the scheduler
-----------------------
Create a file called `example_job.sh`, with contents:

```bash
#!/bin/bash
#BSUB -J example_job
#BSUB -n "1"
#BSUB -W 0:30
#BSUB -R "rusage[mem=2]"
#BSUB -R "span[hosts=1]"
#BSUB -R "select[hname!=plvimphctrl1]"
cd example_job_directory
./run_example.sh 5000000
```

This file, `example_job.sh`, has some bash "comments" that will be interpreted by the LSF scheduler.

To actually schedule it, do:

```
bsub < example_job.sh
```

Monitor progress
----------------
Use `bjobs -l`.

