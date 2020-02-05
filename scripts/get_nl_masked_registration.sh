#!/bin/bash
# Descrption: get nl fod registration with restricted masking rules, \
#             dealing with mif files, cutted brains.

# utils
BASEDIR=$(dirname $0)
mul="${BASEDIR}/../utils/mul_images.sh"
convert="${BASEDIR}/convert_miftrans2ants.sh"

if [ $# -lt 5 ]
then
	echo "Usage: `basename $0` moving_fod moving_mask target_template outdir threads"
	exit
fi

moving_fod=$1
moving_mask=$2
target_template=$3
outdir=$4
threads=$5

filename=$(basename ${moving_fod})
filename="${filename%.*}"

tmpdir=${outdir}/tmp_${RANDOM}_${RANDOM}_${RANDOM}_$$
(umask 077 && mkdir ${tmpdir}) || {
	echo "Could not create temporary directory! Exiting." 1>&2
	exit 1
}

# apply restricted masking rules
bash ${mul} ${moving_fod} ${moving_mask} ${tmpdir}/fod_masked.mif
bash ${mul} ${target_template} ${moving_mask} ${tmpdir}/template_masked.mif

# registration
# keep the mif warp files.
mrregister ${tmpdir}/fod_masked.mif ${tmpdir}/template_masked.mif \
			-type nonlinear \
			-nl_warp ${outdir}/${filename}_warp.mif ${outdir}/${filename}_warp_inv.mif \
			-transformed ${outdir}/${filename}_warped.mif \
			-nl_warp_full ${tmpdir}/${filename}_warpfull.mif \
			-mask1 ${moving_mask} \
			-mask2 ${moving_mask} \
			-nthreads ${threads} \
			-datatype float32 -force
bash ${mul} ${outdir}/${filename}_warp.mif ${moving_mask} ${outdir}/${filename}_warp.mif
bash ${mul} ${outdir}/${filename}_warp_inv.mif ${moving_mask} ${outdir}/${filename}_warp_inv.mif

# convert mif transformation to ants

bash ${convert} ${tmpdir}/fod_masked.mif ${tmpdir}/${filename}_warpfull.mif \
	 ${tmpdir}/template_masked.mif ${outdir}/${filename}_warp.nii.gz
#bash ${convert} ${tmpdir}/template_masked.mif ${outdir}/${filename}_warp_inv.mif \
#     ${tmpdir}/fod_masked.mif ${outdir}/${filename}_warp_inv.nii.gz

# clean up
rm -rf ${tmpdir}
