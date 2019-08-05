#!/bin/bash
#SBATCH --time=65:00:00
#SBATCH --mem=128G
#SBATCH --cpus-per-task=64
#SBATCH --mail-user=aditya.alleear@gmail.com
#SBATCH --mail-type=BEGIN
#SBATCH --mail-type=END
#SBATCH --mail-type=FAIL
#SBATCH --mail-type=REQUEUE
#SBATCH --mail-type=ALL 

#This above lines are instrustions for the server Compute Canada 
#Some of the setting could be reduced but it was increased to ensure that the job deos not quit and fail



#### MANAGING DIRECTIRIES #### 
#The genome index which was made using hisat2 index
GENOMEINDEX=/home/aditalle/scratch/genome/Canis_familiaris.CanFam3.1.dna.toplevel
GENOME=/home/aditalle/scratch/genome/Canis_familiaris.CanFam3.1.dna.toplevel.fa
DATA=/home/aditalle/scratch

#### PARALLEL SETTING #### 
#The number of CPUs that will be used through parallel computing
CPU=64

#Making a log file 
cd $DATA
touch main.log 

#Loading the modules required (compute canada requires this)
module load hisat2
module load samtools
module load bcftools


#### HISAT2 ALIGNMENT #### 
#Going to the directory containing the fq files 
cd $DATA/fullfq

#Running hisat2 for making sam files, parallel computing is used for this step 
parallel -j $CPU hisat2 -x $GENOMEINDEX -U {}.fastq -S {}.sam ::: $(ls -1 *.fastq | sed 's/.fastq//')

#In case of error, there will be a printed message
if [ $? -ne 0 ]; then
	printf There is a problem in the alignment step
	exit 1
fi

if [ $? -eq 0 ]; then
		printf "The alignment step using hisat2 completed successfully.\n" >> $DATA/main.log
fi

mkdir $DATA/samfiles
mv *.sam $DATA/samfiles

cd $DATA/samfiles

#Converting the sam files to bam files 
parallel samtools view -b -S {}.sam ">" {}.temp.bam ::: $(ls -1 *.sam | sed 's/.sam//')

#Samtools view error check 
if [ $? -ne 0 ]; then 
	printf "There is a problem in the samtools-view step"
	exit 1
fi

#Sorting the bam files 
parallel samtools sort {}.temp.bam -o {}.sort.bam ::: $(ls -1 *.temp.bam | sed 's/.temp.bam//')
if [ $? -ne 0 ]; then 
	printf "There is a problem in the samtools-sort step"
	exit 1
fi

#Indexing the bam files
parallel samtools index {} ::: $(ls -1 *.sort.bam)
if [ $? -ne 0 ]; then 
	printf "There is a problem in the samtools-index step"
	exit 1
fi

#Making a bamlist if it is needed in other applications 
for i in $(ls -1 *.sort.bam)
	do
		printf "$PWD/${i}\n" >> "bamlist"
	done
	if [ $? -ne 0 ]; then 
	 	printf "There is a problem in bam file list"
	 	exit 1
	fi

#Writing to log 
if [ $? -eq 0 ]; then
		printf "The sam to bam step using samtools completed successfully.\n" >> $DATA/main.log
fi

#Moving bams files to bam directory 
cd $DATA 
mkdir $DATA/bamfiles
cd $DATA/samfiles/
mv *.bam $DATA/bamfiles

#### BCFTOOLS MPILEUP AND CALL (MAKING VCF) #### 
#Going into bamfiles directory 
cd $DATA/bamfiles

#Making vcf files from bam files 
for BAM in *.sort.bam
	do
		NAME=`echo $BAM | sed 's/[.sort.bam]//g'`
		VCF="$NAME.vcf.gz"
        bcftools mpileup -f $GENOME $BAM | bcftools call -mv -Oz -o $VCF 
	done

#Writing to log 
if [ $? -eq 0 ]; then
		printf "The making of VCF files completed successfully.\n" >> $DATA/main.log
fi

#Moving vcf files into vcffiles directory 
mkdir $DATA/vcffiles
mv *.vcf.gz $DATA/vcffiles

#### BCFTOOLS ISEC #### 
#Going into vcffiles directory 
cd $DATA/vcffiles

#Making index from vcf files 
parallel bcftools index {}.vcf.gz > {}.vcf.gz.csi ::: $(ls -1 *.vcf.gz | sed 's/.vcf.gz//')


#Using bcftools isec (stands for intersection) in order to find common variants in all the files 

for VCF in *.vcf.gz
	do 
		NAME=`echo $VCF`
		FILES+=$NAME' ' 
	done 

bcftools isec $FILES -p dir -n=25  

#Writing to log 
if [ $? -eq 0 ]; then
		printf "bcftools isec completed successfully.\n" >> $DATA/main.log
fi
