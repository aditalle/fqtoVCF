# FqtoVCF and finding common variants in all VCF files Pipeline 
The script was built using Canada Compute servers in mind but it can be run locally or on server with minimal modification to the script. 

## Tools used
There were three main tools used alongside with parallel. 
First tool used was hisat2 which was responsible for alignment of the Fq files and creation of sam files. Samtools was used for converting sam files to bam files. Bcftools mpileup was used for genotype likelihood calculations and the bcftools call function was used for VCF creation. Last step was finding common variants in all the VCF files which was done using the bcftools isec fucntion. 

 | Tools    | Verision           | 
 | :------------- |:-------------|
 | bash | 4.2.46 |
 | hisat2 | 2.1.0 |
 | parallel | 20180122 | 
 | samtools | 1.9 | 
 | bcftools | 1.9 |
 
### Note: The genome needs to be indexed using hisat2 index prior to using pipeline
