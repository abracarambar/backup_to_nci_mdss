#!/bin/env python

import argparse
import os
import subprocess

def main():
    '''
    '''
    parser = argparse.ArgumentParser()
    normal_sample, tumour_sample, runID = my_parse_args(parser)
    print normal_sample, tumour_sample, runID
    SCRIPTDIR='g/data3/rj76/scripts'
    toekn = ()
    with open ('./token.txt') as fin:
        #fin.readline()
        for line in fin:
            token = str(line.strip())
            print token 

    #vcf_backup(runID, normal_sample, tumour_sample, token)
    #backup alignment folders:
    #bam_backup(runID, normal_sample, tumour_sample, token)
    inputfastq_backup(runID, normal_sample, tumour_sample, token)

   
def my_parse_args(parser):
    parser.add_argument('-n','--normal', help= 'Enter normal sample', required=True)
    parser.add_argument('-t','--tumour', help= 'Enter tumour sample', required=True)
    parser.add_argument('-r','--runID', help= 'Enter runID', required=True)

    args = parser.parse_args()
    return args.normal, args.tumour, args.runID

def bam_backup(runID, normal_sample, tumour_sample, token):
    bam_file_paths = ['alignments/' + normal_sample + '.dedup.realigned.bam',
                     'alignments/' + normal_sample + '.dedup.realigned.bam.bai',
                     'alignments/' + normal_sample + '.dedup.realigned.bam.tdf',
                     'alignments/' + tumour_sample + '.merged.dedup.realigned.bam',
                     'alignments/' + tumour_sample + '.merged.dedup.realigned.bam.bai',
                     'alignments/' + tumour_sample + '.merged.dedup.realigned.bam.tdf']
    print bam_file_paths
    for file_path in bam_file_paths:
        cmd = ['bash', 'dnanexus_backup_to_mdss.sh', runID, file_path, token]
        subprocess.check_call(cmd)

def vcf_backup(runID, normal_sample, tumour_sample, token):
    normal_code=normal_sample.strip().split('-')[-1]
    tumour_code=tumour_sample.strip().split('-')[-1]
    sample_code=tumour_sample.strip().split('-')[1]
    print normal_code, tumour_code
    vcf_file_paths = ['variants/' + normal_sample + '.dedup.realigned.hc.gvcf.gz',
                    'variants/' + normal_sample + '.dedup.realigned.hc.gvcf.gz.tbi',
                    'variants/' + sample_code + '.' + tumour_code + 'vs' + normal_code + '.strelka.vcf.gz',
                    'variants/' + sample_code + '.' + tumour_code + 'vs' + normal_code + '.strelka.vcf.gz.tbi',
                    'variants/' + sample_code + '.' + tumour_code + 'vs' + normal_code + '.strelka.filtered.vep.vcf.gz',
                    'variants/' + sample_code + '.' + tumour_code + 'vs' + normal_code + '.strelka.filtered.vep.vcf.gz.tbi']
    print vcf_file_paths
    for file_path in vcf_file_paths:
        cmd = ['bash', 'dnanexus_backup_to_mdss.sh', runID, file_path, token]
        subprocess.check_call(cmd)

def inputfastq_backup(runID, normal_sample, tumour_sample, token):
    inputfastq_file_path = 'inputFastq/'
    print inputfastq_file_path
    for sample in [normal_sample, tumour_sample]:
    #for sample in normal_sample:
        cmd = ['bash', 'dnanexus_backup_to_mdss.sh', '"' + runID + '":"' + inputfastq_file_path + '"', sample + token]
        print cmd
        #subprocess.check_call(cmd)                           
    

#remove the file and json file
#rm $filename $filename.json 
if __name__ == "__main__":
    main()
