#!/bin/bash

# estimate fod images using ACT method. 
# inputs: DWI folder, T1w folder. Masks are contained in the folder.
# outputs: FOD image. optional(resize)
if [ $# -lt 3 ];then
	echo "Usage: `basename $0` DWI_folder T1w_folder voxel_size output_folder"
	exit
fi

# look around
cmdpath=`realpath $0`
cmdpath=`dirname ${cmdpath}`

# parse inputs
dwidir=`realpath $1`
t1wdir=`realpath $2`
voxel_size=$3
outdir=`realpath $4`
lmax=4 # hardcoded

# cluster parameters
njobs=39
threads=4
nthreads="-nthreads ${threads}"
walltime="24:00:00"

# validation of inputs

if [ ! -e ${dwidir} ];then
	echo "DWI directory not exists. Please indicate a valid directory."
	exit
fi
check_count_dwi=`ls -l ${dwidir}/*-dwis.nii.gz 2>/dev/null | wc -l` #hardcoded naming pattern

if [ ! -e ${t1wdir} ];then
	echo "T1w directory not exists. Please indicate a valid directory."
	exit
fi
check_count_t1w=`ls -l ${dwidir}/*.nii.gz | grep -v "mask" 2>/dev/null | wc -l` #hardcoded naming pattern

if [ $check_count_t1w != $check_count_t1w ];then
	echo "Number of t1w images does not match the number of DWI images."
	exit
fi

if [ ! -e ${outdir} ];then
	echo "The indicated output directory does not exist, generating..."
	mkdir -p ${outdir}
fi
outfod="${outdir}/fods"
if [ ! -e ${outfod} ];then
  mkdir -p ${outfod}
fi

outwmmask="${outdir}/wm_masks"
if [ ! -e ${outwmmask} ];then
  mkdir -p ${outwmmask}
fi

if [ ! -e "${outdir}/fods_all" ];then
  mkdir -p ${outdir}/fods_all
fi

# initialtion
jobdir="${outdir}/jobdir_lmax${lmax}"
joblist="${jobdir}/joblist_lmax${lmax}.txt"
if [ -d ${jobdir} ]; then
	rm -rf ${jobdir}
	mkdir -p ${jobdir}
else
	mkdir -p ${jobdir}
fi

# main loop
namedir="${dwidir}"
for i in `ls ${dwidir}/*.bvecs`
do
	filename=$(basename ${i})
	filename=${filename%.*}
	uid=${filename}

	#inputs
	## dwi
	dwi=${dwidir}/${uid}-dwis.nii.gz
	mask=${dwidir}/${uid}-mask.nii.gz
	bvals=${dwidir}/${uid}.bvals
	bvecs=${dwidir}/${uid}.bvecs

	## t1w
	t1w=${t1wdir}/${uid}.nii.gz

	# mrtrix inputs
	mrout="${outdir}/fods_all/${uid}"
	if [ ! -e ${mrout} ];then
    mkdir -p ${mrout}
  fi
	f5tt="${mrout}/5tt.mif"
  dwidata="${mrout}/DWI.mif"
  meanb0="${mrout}/meanb0.mif"
  rfwm="${mrout}/RF_WM.txt"
  rfgm="${mrout}/RF_GM.txt"
  rfcsf="${mrout}/RF_CSF.txt"
  rfvoxel="${mrout}/RF_voxels.mif"
  wmfod="${mrout}/WM_FODs.mif"
  gm="${mrout}/GM.mif"
  csf="${mrout}/CSF.mif"
  tissueRGB="${mrout}/tissueRGB.mif"

  #commands
  # cmdir="/share/apps/mrtrix30RC3/bin"
  cmdir="/share/apps/mrtrix334/bin"
 	myfunc="${cmdpath}/5tt2WMmask.sh"

 	#cmd0="module load gcc/9.2.0"
 	gradcheck="${cmdir}/dwigradcheck ${dwi} -mask ${mask} -fslgrad ${bvecs} ${bvals} -export_grad_mrtrix ${mrout}/${uid}.b ${nthreads} -force"
 	cmd1="${cmdir}/5ttgen fsl ${t1w} ${f5tt} -nocrop -premasked ${nthreads}"
 	cmd2="${cmdir}/mrconvert ${dwi} ${dwidata} -grad ${mrout}/${uid}.b -datatype float32 -stride -2,-3,4,1 -force ${nthreads}"
 	cmd3="${cmdir}/dwiextract ${dwidata} - -bzero | mrmath - mean ${meanb0} -axis 3 ${nthreads} -force"
 	cmd4="${cmdir}/dwi2response -lmax ${lmax} msmt_5tt ${dwidata} ${f5tt} ${rfwm} ${rfgm} ${rfcsf} -voxels ${rfvoxel} ${nthreads} -force"
 	cmd5="${cmdir}/dwi2fod -lmax ${lmax},${lmax},${lmax} msmt_csd ${dwidata} ${rfwm} ${wmfod} ${rfgm} ${gm} ${rfcsf} ${csf} ${nthreads} -force"
 	cmd6="${cmdir}/mrconvert ${wmfod} - -coord 3 0 | mrcat ${csf} ${gm} - ${tissueRGB} -axis 3 ${nthreads} -force"
 	cmd7="${cmdir}/mrcalc ${wmfod} ${mask} -mult ${mrout}/${uid}_fod.mif ${nthreads} -force"
 	cmd8="${cmdir}/mrconvert ${mask} ${mrout}/${uid}_fod_mask.mif -stride -1,-2,3 ${nthreads} -force"
 	cmd9="bash ${myfunc} ${f5tt} ${mrout}/${uid}_wm_mask.nii.gz"
 	cmd10="${cmdir}/mrresize -voxel ${voxel_size} ${mrout}/${uid}_fod.mif ${outfod}/${uid}_fod.mif ${nthreads} -force"
 	cmd11="${cmdir}/mrresize -voxel ${voxel_size} -interp nearest ${mrout}/${uid}_wm_mask.nii.gz ${outwmmask}/${uid}_wm_mask.nii.gz ${nthreads} -force"

 	jobname=${uid}_efod
 	jobscript=${jobdir}/job_${jobname}_qsub.sh
 	echo '#!/bin/bash'>${jobscript}
 	echo ${cmd0} >>${jobscript}
 	echo ${gradcheck}>>${jobscript}
 	echo ${cmd1}>>${jobscript}
 	echo ${cmd2}>>${jobscript}
 	echo ${cmd3}>>${jobscript}
 	echo ${cmd4}>>${jobscript}
 	echo ${cmd5}>>${jobscript}
 	echo ${cmd6}>>${jobscript}
 	echo ${cmd7}>>${jobscript}
 	echo ${cmd8}>>${jobscript}
 	echo ${cmd9}>>${jobscript}
 	echo ${cmd10}>>${jobscript}
 	echo ${cmd11}>>${jobscript}
 	echo ${jobname}>>${joblist}
done
submit_jobs_v9 ${joblist} ${walltime} 45G ${threads} ${jobdir} ${njobs}


