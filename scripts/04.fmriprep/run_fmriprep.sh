#!/bin/bash

################################################################################
# RUN FMRIPREP ON BIDS DATA ALREADY RUN THROUGH FREESURFER
#
# The fMRIPrep singularity was installed using the following code:
# 	singularity build /EBC/processing/singularity_images/fmriprep-23.2.1.simg docker://nipreps/fmriprep:23.2.1
################################################################################

# usage documentation - shown if no text file is provided or if script is run outside EBC directory
Usage() {
    echo
	echo
    echo "Usage:"
    echo "./run_fmriprep.sh <list of subjects> <study name?"
    echo
    echo "Example:"
    echo "./run_fmriprep.sh list.txt STUDYNAME"
    echo
    echo "list.txt is a file containing the participants to run fMRIPrep on:"
    echo "001"
    echo "002"
	echo "..."
    echo
    echo "Script created by Manuel Blesa & Melissa Thye and modified by Naiti Bhatt"
    echo
    exit
}
[ "$1" = "" ] || [ "$2" = "" ] && Usage

# define subjects from text document
subjs=$(cat $1) 

# define study [directory] from text document
study=$2

# define directories
projDir=`cat ../../PATHS.txt`
singularityDir=$(realpath ../../singularity_images)
bidsDir="$projDir/$study/data/BIDS_anon"
derivDir="/home/naitibhatt/ebby-fmri-analysis/data/$study/derivatives"

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
echo "Running fMRIPrep for..."
echo "${subjs}"

# iterate for all subjects in the text file
for subj in ${subjs[@]}; do
	# grab subjid
	NAME=${subj##*-}
	
	echo
	echo "Running fMRIprep for ${subj}"
	echo

	# run singularity
	singularity run --cleanenv	\
	${singularityDir}/fmriprep-23.2.1.simg  							\
	${bidsDir} ${derivDir}												\
	participant															\
	--participant-label ${NAME}											\
	--skip_bids_validation												\
	--nthreads 16														\
	--omp-nthreads 16													\
	--ignore slicetiming												\
	--fd-spike-threshold 1												\
	--dvars-spike-threshold 1.5											\
	--output-space MNI152NLin2009cAsym:res-2 T1w						\
	--derivatives ${derivDir}											\
	--stop-on-first-crash												\
	-w ${singularityDir}												\
	--fs-license-file ${license}  > ${derivDir}/${subj}/log_fmriprep_${subj}.txt
	
	# give other users permissions to created files
	chmod -R a+wrx ${derivDir}/${subj}
done
