#!/bin/bash
# python dependencies: line 39: clusterneuroimaging (numpy, nibabel)# hardcoded

# TOOLS
BASEDIR=$(dirname $0)
tool_dummy="${BASEDIR}/../utils/make_dummy_header_ANTs.sh"
tool_df2dp="${BASEDIR}/../utils/def2disp_with_dummy.py"

if [ $# -lt 4 ];then
	echo "`basename ${0}` fod_source FOD_warp_mif fod_target out_fod_displacement"
	echo "The FOD transformation should be used with MRtrix303 (.mif)"
	exit
fi

fod_source=${1}
fod_warp=${2}
fod_target=${3}
outdp=${4}

outdir=`dirname ${outdp}`
tmpdir=${outdir}/tmp_${RANDOM}_${RANDOM}_${RANDOM}_$$
(umask 077 && mkdir ${tmpdir}) || {
	echo "Could not create temporary directory! Exiting." 1>&2
	exit 1
}

#expected temporary files:
origin_dp=${tmpdir}/trans.nii.gz
scalar_template=${tmpdir}/power_template.nii.gz
scalar_source=${tmpdir}/power_source.nii.gz

combined_disp=${tmpdir}/dp_dummyCombined.nii.gz
corrected_dp=${outdp} 

warpconvert ${fod_warp} -type deformation2displacement -template ${fod_target} ${origin_dp} -nthreads 1
sh2power ${fod_target} ${scalar_template} -nthreads 1
sh2power ${fod_source} ${scalar_source} -nthreads 1
bash ${tool_dummy} ${tmpdir} ${scalar_source} ${scalar_template}
source activate clusterneuroimaging
python ${tool_df2dp} ${origin_dp} ${combined_disp} ${corrected_dp}
conda deactivate 

rm -rf ${tmpdir}