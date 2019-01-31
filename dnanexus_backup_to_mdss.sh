#!/bin/bash


source /g/data3/rj76/software/dx-toolkit/environment
pwd
token="$3"

[[ -d $NCIbackupfolder ]] || mkdir NCIbackupfolder
NCIbackupfolder="/g/data3/rj76/research/NCIbackupfolder"
dx login --token $token --noproject

#for fastq files, retrive all files matching to given sample
if [[ $1 == *"inputFastq"* ]]; then
    filepath="$1"
    filedir=`dirname "$filepath"`
    samplename="$2"
    mkdir $NCIbackupfolder/$samplename\_fastq_files
    cd $NCIbackupfolder/$samplename\_fastq_files
    dx find data --property external_id="$samplename" --path "$filepath" --brief
    
    for filename in `dx find data --property external_id="$samplename" --path "$filepath" --brief`
    do
       dx download -a -f "$filename" -o $NCIbackupfolder && touch "$filename".done
       #check md5 sums and integrity of file
	   dx-verify-file -l $filename -r `dx find data --brief --norecurse --path "inputFastq" --name "$filename" | cut -d ':' -f 2`
	   echo "File was downloaded from DNANexus succesfully"
	   touch "$filename".OK
    
       #download the associated attibutes of file stored in json
       dx describe "$filepath" --json >> "$filename".json
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