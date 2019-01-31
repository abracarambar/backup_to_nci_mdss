#!/bin/bash

source /g/data3/rj76/software/dx-toolkit/environment
pwd
token="$3"
current_dir=`pwd`
#NCIbackupfolder="/g/data3/rj76/research/NCIbackupfolder"
NCIbackupfolder="$current_dir/NCIbackupfolder"
[[ -d $NCIbackupfolder ]] || mkdir $NCIbackupfolder

#login to dnanexus
dx login --token $token --noproject

#for fastq files, retrive all files matching to given sample
if [[ $1 == *"inputFastq"* ]]; then
    #project-FBj2Qjj0py0YVyV03BBpK4by:inputFastq/
    projectname_dir="$1"
    #project-FBj2Qjj0py0YVyV03BBpK4by
    projectname=`cut -f1 -d ':' $projectname_dir`
    #LKCGP-P000204-251965-01-04-01-D1
    samplename="$2"
    [[ -d $NCIbackupfolder\/$samplename\_fastq_files ]] || mkdir $NCIbackupfolder\/$samplename\_fastq_files
    cd $NCIbackupfolder/$samplename\_fastq_files
    #dx find data --property external_id=LKCGP-P000204-251965-01-04-01-D1 --path project-FBj2Qjj0py0YVyV03BBpK4by:inputFastq
    dx find data --property external_id="$samplename" --path "$projectname_dir" | tr -s ' ' ' ' | cut -f6 -d ' '
    #/inputFastq/HH3TCCCXY_2_180304_FD01070327_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M029_R2.fastq.gz
    
    for filepath in `dx find data --property external_id="$samplename" --path "$filepath" | tr -s ' ' ' ' | cut -f6 -d ' '`
    do
    	filename=`cut -f3 -d '/' filepath`
    	#HH3TCCCXY_2_180304_FD01070327_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M029_R2.fastq.gz
    	filedir=`dirname "$filepath"`
    	#inputFastq
        dx download -a -f "$projectname":"$filepath" -o "$NCIbackupfolder"\/"$samplename"\_fastq_files && touch "$filename".done
        #check md5 sums and integrity of file
	    dx-verify-file -l "$filename" -r `dx find data --brief --norecurse --path "$projectname":"$filedir" --name "$filename" | cut -d ':' -f 2`
	    echo "File was downloaded from DNANexus succesfully"
	    touch "$filename".OK
    
       #download the associated attibutes of file stored in json
       dx describe "$projectname":"$filename" --json >> "$filename".json
       echo "File attributes were downloaded from DNANexus successfully";
    done
#all other files
else
    projectname="$1"
    filepath="$2"
    
    filename=`basename "$filepath"`
    filedir=`dirname "$filepath"`
    
    dx download -a -f "$projectname":"$filepath" -o $NCIbackupfolder && touch "$filename".done
    #move into the backup folder
    cd $NCIbackupfolder

    #check md5 sums and integrity of file
    dx-verify-file -l $filename -r `dx find data --brief --norecurse --path "$projectname":"$filedir"  --name "$filename" | cut -d ':' -f 2`

    echo "File was downloaded from DNANexus succesfully"
    touch "$filename".OK

    #download the associated attibutes of file stored in json
    dx describe "$projectname":"$filepath" --json >> "$filename".json
    echo "File attributes were downloaded from DNANexus successfully"
    
    #if file is g.vcf, then fix
    #rename filename
    echo "Fixing g.vcf names"
    if [[ $filename == *"gvcf"* ]]; then
	    newfilename="$(echo ${filename} | sed -e 's/gvcf/g\.vcf/')";
	    mv $filename $newfilename
	    newjson="$(echo ${filename}.json | sed -e 's/gvcf/g\.vcf/')";
	    mv ${filename}.json $newjson
	    filename=$newfilename
	    echo $filename
	fi    
fi

#set permissions
echo "Setting file permissions for $filename $filename.json"
setfacl -m group:tx70:rw-,other::r--,user:cmv562:rwx,user:mw9491:rwx,user:mg3536:rwx $filename
setfacl -m group:tx70:rw-,other::r--,user:cmv562:rwx,user:mw9491:rwx,user:mg3536:rwx $filename.json
echo "Files permissions set"

#tar via jobfs
tar -cvf $PBS_JOBFS/${filename}.tar $filename $filename.json
echo "File tar created"
tar -tf $PBS_JOBFS/${filename}.tar > $PBS_JOBFS/${filename}.tar.contents

if [ $(mdss -P tx70 ls dnanexus_backup/${filename}.tar | wc -l) = 0 ]; then
	echo "Uploading the TAR to massdata"
    mdss -P tx70 put $PBS_JOBFS/${filename}.tar dnanexus_backup/
    #echo "Keep a copy of tar contents"
    cp $PBS_JOBFS/${filename}.tar.contents $NCIbackupfolder
    echo "Verifying the TAR has been transferred successfully"
    mdss -P tx70 verify -v dnanexus_backup/${filename}.tar
else    
    echo "Tar already exists on mdss!"
    exit 1    
fi
echo "File tar created"