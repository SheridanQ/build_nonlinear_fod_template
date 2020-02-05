#!/bin/bash
# trap keyboard interrupt (control-c)
# Rakeen
# trap control_c SIGINT
# cleanup()
# {
#   echo "\n*** Performing cleanup, please wait ***\n"

#   runningANTSpids=$( ps --ppid $$ -o pid= )

#   for thePID in $runningANTSpids
#   do
#       echo "killing:  ${thePID}"
#       kill ${thePID}
#   done

#   return $?
# }

# control_c()
# # run if user hits control-c
# {
#   echo -en "\n*** User pressed CTRL + C ***\n"
#   cleanup

#      qdel ${jobIDs}

#   exit $?
#   echo -en "\n*** Script cancelled by user ***\n"
# }

sub="dummy"

temp_dir=${1}
input_scalar=${2}
target_scalar=${3}

output_warp=dp_${sub}Warp.nii.gz
output_affine=dp_${sub}Affine.txt
combined_disp=dp_${sub}Combined.nii.gz

ANTSPATH=/share/apps/ANTs.OLD/bin
ANTS=${ANTSPATH}/ANTS
WARP=${ANTSPATH}/antsApplyTransforms
DIM=3
MAXITERATIONS=10x0x0 #100x100x100
TRANSFORMATION=SyN[0.25]
REGULARIZATION=Gauss[3,0]
RADIUS=5
# MEMORYLIMIT=${4}
# WLT=${5}
affine_iterations=100x100x10x10x10 #10000x10000x10000x10000x10000
affine_gradient_descent=0.05 #0.1x0.5x1.e-4x1.e-4
# jobIDs=""
# id=""
# cpi=0

basecall="${ANTS} ${DIM}"
IMAGEMETRICSET="-m CC[${target_scalar},${input_scalar},1,${RADIUS}]"
IMAGEMETRICLINEARSET="--use-Histogram-Matching --number-of-affine-iterations ${affine_iterations} --MI-option 64x64000 --affine-gradient-descent-option ${affine_gradient_descent}"
stage3="${IMAGEMETRICSET} -t ${TRANSFORMATION} -r ${REGULARIZATION} -o ${temp_dir}/dp_${sub} -i ${MAXITERATIONS} ${IMAGEMETRICLINEARSET}"
OUTPUTTRANSFORMS="-t ${temp_dir}/${output_warp} -t ${temp_dir}/${output_affine}"
exe1="${basecall} ${stage3}"
exe2="${WARP} -d ${DIM} --float 1 --verbose 1 -i ${input_scalar} -o [${temp_dir}/${combined_disp},1] -r ${target_scalar} ${OUTPUTTRANSFORMS}"

echo ${exe1}
echo ${exe2}

${exe1}
${exe2}

# qscript="${temp_dir}/qsub_a_r.sh"
# rm -f ${qscript}
# echo "#!/bin/bash" > ${qscript}
# echo "${exe1}" >> ${qscript}
# echo "${exe2}" >> ${qscript}


# cd ${temp_dir}
# id=`qsub -N dummyheader -v ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=1,OMP_NUM_THREADS=1,LD_LIBRARY_PATH=$LD_LIBRARY_PATH,ANTSPATH=$ANTSPATH -j oe -l nodes=1:CPU -l mem=${MEMORYLIMIT} -l walltime=${WLT} ${qscript}`
# jobIDs="${jobIDs} ${id}"
# cpi=1






# if [ ${cpi} == 1 ]; then
# ${wait_PBS}/waitForPBSQJobs_f.pl 1 100 ${jobIDs}
# fi




