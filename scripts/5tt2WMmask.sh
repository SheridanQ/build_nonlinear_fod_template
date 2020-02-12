#!/bin/bash

input5ttmif=${1}
strides="-1,-2,3,4"
threshold=0.5
outputWMmasknii=${2}


tmp_dir=$(mktemp -d -t cb-XXXXXXXXXX)

mrconvert ${input5ttmif} ${tmp_dir}/5tt.nii.gz -stride ${strides}
fslsplit ${tmp_dir}/5tt.nii.gz ${tmp_dir}/wm
fslmaths ${tmp_dir}/wm0002.nii.gz -thr ${threshold} -bin ${outputWMmasknii}

rm -rf ${tmp_dir}