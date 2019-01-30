#!/bin/bash
#PBS -q copyq
#PBS -l ncpus=1
#PBS -l walltime=10:00:00
#PBS -l mem=2GB
#PBS -l other=mdss,gdata3
#PBS -l wd
#PBS -M mgauthier@ccia.org.au
#PBS -m abe
#PBS -j oe
#PBS -l jobfs=6000GB
#PBS -P rj76
#PBS -W umask=027


set -euf -o pipefail

module load python/2.7.3
module load parallel

python dnanexus_backup_to_mdss.py -n 'LKCGP-P000204-251963-02-04-07-G1' -t 'LKCGP-P000204-251965-01-04-01-D1' -r 'project-FBj2Qjj0py0YVyV03BBpK4by'

#bash dnanexus_backup_to_mdss.sh "project-FBj2Qjj0py0YVyV03BBpK4by" "variants/P000204.D1vsG1.strelka.pass.vcf.gz"
#bash dnanexus_backup_to_mdss.sh  
