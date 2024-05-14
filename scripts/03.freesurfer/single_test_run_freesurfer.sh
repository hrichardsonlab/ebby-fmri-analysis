#!/bin/bash

################################################################################
# RUN FREESURFER ON BIDS DATA
#
# This step must be run before the data can be fully processed through fMRIPrep
#
# The fMRIPrep singularity was installed using the following code:
# 	singularity build /EBC/processing/singularity_images/fmriprep-23.2.1.simg docker://nipreps/fmriprep:23.2.1
################################################################################

# usage documentation - shown if no text file is provided or if script is run outside EBC directory
Usage() {
    echo
	echo
    echo "Usage:"
    echo "./run_freesurfer.sh <list of subjects> <project directory> <STUDYNAME>"
    echo
    echo "Example:"
    echo "bash ./run_freesurfer.sh /PATH/TO/FILE/list.txt /PATH/TO/BIDS STUDYNAME"
    echo
    echo "list.txt is a file containing the participants to run Freesurfer on:"
    echo "001"
    echo "002"
	echo "..."
    echo
	echo
    echo "Script created by Manuel Blesa & Melissa Thye and modified by Naiti Bhatt"
    echo
    exit
}
[ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ] && Usage

# if the script is run outside of the EBC directory (e.g., in home direct
# define subjects from text document
subjs=$(cat $1) 

# define study [directory] from input
bidsDir=$2

# define study name
study=$3

# define directories
singularityDir="/home/naitibhatt/ebby-fmri-analysis/singularity_images"
derivDir="/home/naitibhatt/ebby-fmri-analysis/data/$study/derivatives" # move the contents of this directory to the project directory after running!!!!

# export freesurfer license file location
export license=/home/naitibhatt/ebby-fmri-analysis/freesurfer.txt

# create derivatives directory if it doesn't exist
if [ ! -d ${derivDir} ]
then 
	mkdir -p ${derivDir}
fi

# export freesurfer license file location
export license=/home/naitibhatt/ebby-fmri-analysis/freesurfer.txt

# change the location of the singularity cache ($HOME/.singularity/cache by default, but limited space in this directory)
export SINGULARITY_TMPDIR=${singularityDir}
export SINGULARITY_CACHEDIR=${singularityDir}
unset PYTHONPATH

# prepare some writeable bind-mount points
export SINGULARITYENV_TEMPLATEFLOW_HOME=${singularityDir}/fmriprep/.cache/templateflow

# display subjects
echo
echo "Running Freesurfer via fMRIPrep for..."
echo "${subjs}"

# iterate for all subjects in the text file
# iterate for all subjects in the text file
for subj in ${subjs[@]}; do
	# grab subjid
	NAME=${subj##*-}
 
	# check whether the file already exists
	if [ ! -f ${derivDir}/sourcedata/freesurfer/sub-${NAME}/mri/aparc+aseg.mgz ]
	then

		echo
		echo "Running anatomical workflow contained in fMRIprep for ${subj}"
		echo
		
		# make output subject derivatives directory
		mkdir -p ${derivDir}/$subj

		# run singularity
		singularity run \
		${singularityDir}/fmriprep-23.2.1.simg  							\
		${bidsDir} ${derivDir}												\
		participant															\
		--participant-label ${NAME}											\
		--skip_bids_validation												\
		--nthreads 16														\
		--omp-nthreads 16													\
		--anat-only	--fs-no-reconall								     \
		--output-space MNI152NLin2009cAsym:res-2 T1w						\
		--derivatives ${derivDir}											\
		--stop-on-first-crash												\
		-w ${singularityDir}												\
		--fs-license-file ${license}  > ${derivDir}/sub-${NAME}/log_freesurfer_sub-${NAME}.txt
		
		# move subject report and freesurfer output files to appropriate directories
		mv ${derivDir}/*dseg.tsv ${derivDir}/sourcedata/freesurfer
		mv ${derivDir}/sub-${NAME}.html ${derivDir}/sub-${NAME}
			
		# give other users permissions to created files
		#chmod -R a+wrx ${derivDir}/sub-${NAME}

	fi

done
