#!/usr/bin/env bash
#set -e -o pipefail
dx_env="/g/data3/rj76/software/dx-toolkit/environment"
source $dx_env
pwd
token="$3"
scriptdir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#NCIbackupfolder="/g/data3/rj76/research/NCIbackupfolder"
NCIbackupfolder="$scriptdir/NCIbackupfolder"
[[ -d $NCIbackupfolder ]] || mkdir $NCIbackupfolder

#login to dnanexus
dx login --token $token --noproject

#for fastq files, retrive all files matching to a given sample
if [[ $1 == *"inputFastq"* ]]; then
    #project-FBj2Qjj0py0YVyV03BBpK4by:inputFastq/
    projectname_dir="$1"
    #project-FBj2Qjj0py0YVyV03BBpK4by
    projectname=`echo $projectname_dir | cut -f1 -d ':'`
    echo "$projectname"
    #LKCGP-P000204-251965-01-04-01-D1
    samplename="$2"
    [[ -d $NCIbackupfolder\/$samplename\_fastq_files ]] || mkdir $NCIbackupfolder\/$samplename\_fastq_files
    cd $NCIbackupfolder/$samplename\_fastq_files
    echo "Extract all fastq files for $samplename";
    cmd="dx find data --class file --norecurse --property external_id=$samplename --path $projectname_dir | tr -s ' ' ' ' | cut -f6 -d ' ' | cut -f2- -d '/'";
    echo $cmd;
    eval $cmd;
    #dx find data --property external_id=LKCGP-P000204-251965-01-04-01-D1 --path project-FBj2Qjj0py0YVyV03BBpK4by:inputFastq
    #/inputFastq/HH3TCCCXY_2_180304_FD01070327_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M029_R2.fastq.gz
    
    for filepath in `dx find data --class file --norecurse --property external_id="$samplename" --path "$projectname_dir"  | tr -s ' ' ' ' | cut -f6 -d ' ' | cut -f2- -d '/'`
    do
    	filename=`echo $filepath | cut -f2 -d '/'`
    	echo "$filename"
    	#HH3TCCCXY_2_180304_FD01070327_Homo-sapiens__R_160805_EMIMOU_LIONSDNA_M029_R2.fastq.gz
    	filedir=`echo $filepath | cut -f1 -d '/'`
    	echo "$filedir"
    	fastqfilepathmd5=$filepath\.md5
    	echo "$fastqfilepathmd5"
       	#inputFastq
    	echo "Downloading $filename from DNANexus into $samplename fastq folder"
        dx download -a -f "$projectname":"$filepath" -o "$NCIbackupfolder"\/"$samplename"\_fastq_files \
        && touch $NCIbackupfolder/$filename.done
        dx download -a -f "$projectname":"$fastqfilemd5" -o "$NCIbackupfolder"\/"$samplename"\_fastq_files \
        && touch $NCIbackupfolder/$filename.md5.done
        
        #check md5 sums and integrity of file
	    dx-verify-file -l "$filename" -r `dx find data --brief --norecurse --path "$projectname":"$filedir" --name "$filename" | cut -d ':' -f 2` \
	    && touch $NCIbackupfolder/$filename.OK
    
        #download the associated attibutes of file stored in json
        echo "Downloading $filename attributes from DNANexus"
        dx describe "$projectname":"$filepath" --json >> "$filename".json

    done
        
    echo "Setting file permissions for $samplename fastq folder"
	cd $NCIbackupfolder
	setfacl -Rm group:tx70:rw-,other::r--,user:cmv562:rwx,user:mw9491:rwx,user:mg3536:rwx $NCIbackupfolder/$samplename\_fastq_files
	setfacl -Rm group:tx70:rw-,other::r--,user:cmv562:rwx,user:mw9491:rwx,user:mg3536:rwx $NCIbackupfolder/$samplename\_fastq_files
	
	#create tar file via jobfs
	echo "Creating a tar file for $samplename fastq folder"
	tar -cvf $PBS_JOBFS/$samplename\_fastq_files.tar $NCIbackupfolder\/$samplename\_fastq_files
	tar -tf $PBS_JOBFS/$samplename\_fastq_files.tar > $PBS_JOBFS/$samplename\_fastq_files.tar.contents

	if [ $(mdss -P tx70 dnanexus_backup/ | grep ${samplename}.tar | wc -l) = 0 ]; then
		echo "Uploading the tar file to massdata"
    	mdss -P tx70 put $PBS_JOBFS/${samplename}\_fastq_files.tar dnanexus_backup/
    	#echo "Keep a copy of tar contents"
    	cp $PBS_JOBFS/${samplename}\_fastq_files.tar.contents $NCIbackupfolder
    	echo "Verifying the tar file has been transferred successfully"
    	mdss -P tx70 verify -v dnanexus_backup/${samplename}\_fastq_files.tar
	else    
		echo "The tar file already exists on mdss!"
	exit 1
	fi
    
#all other files
else
    projectname="$1"
    filepath="$2"
    
    filename=`basename "$filepath"`
    filedir=`dirname "$filepath"`
    
    echo "Downloading $filename from DNANexus"
    dx download -a -f "$projectname":"$filepath" -o $NCIbackupfolder \
    && touch $NCIbackupfolder/$filename.done
    #move into the backup folder
    cd $NCIbackupfolder

    #check md5 sums and integrity of file
    dx-verify-file -l $filename -r `dx find data --brief --norecurse --path "$projectname":"$filedir"  --name "$filename" | cut -d ':' -f 2` \
    & touch "$filename".OK

    #download the associated attibutes of file stored in json
    echo "Downloading $filename attributes from DNANexus"
    dx describe "$projectname":"$filepath" --json >> "$filename".json
    
    #if file is g.vcf, then fix
    #rename filename
    echo "Fixing g.vcf names"
    if [[ $filename == *"gvcf"* ]]; then
	    newfilename="$(echo ${filename} | sed -e 's/gvcf/g\.vcf/')"
	    mv $filename $newfilename
	    newjson="$(echo ${filename}.json | sed -e 's/gvcf/g\.vcf/')"
	    mv ${filename}.json $newjson
	    filename=$newfilename
	    echo $filename
	fi
	
	#set permissions
	echo "Setting file permissions for $filename and for $filename.json"
	setfacl -m group:tx70:rw-,other::r--,user:cmv562:rwx,user:mw9491:rwx,user:mg3536:rwx $filename
	setfacl -m group:tx70:rw-,other::r--,user:cmv562:rwx,user:mw9491:rwx,user:mg3536:rwx $filename.json
	
	#create tar file via jobfs
	echo "Creating tar file"
	tar -cvf $PBS_JOBFS/${filename}.tar $filename $filename.json
	tar -tf $PBS_JOBFS/${filename}.tar > $PBS_JOBFS/${filename}.tar.contents
	
	if [ $(mdss -P tx70 ls dnanexus_backup/ | grep ${filename}.tar | wc -l) = 0 ]
	then
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
fi
