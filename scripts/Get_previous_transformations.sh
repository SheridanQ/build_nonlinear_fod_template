#!/bin/bash

filename=$1
zigzag=$2
DTorT1orFOD=$3

declare -A transform=()

#####################################################
DT_zz0_def_dir=/data/ywu94/data/redo_oldAtlas/0_Initial_DT_registration_to_T1/nonlinear_pons_b0truncated_to_t1inverted
#####################################################
DT_zz0_aff=${DT_zz0_def_dir}/${filename}_pons_nonlinear_Affine.txt
DT_zz0_def=${DT_zz0_def_dir}/${filename}_pons_nonlinear_Warp.nii.gz
#####################################################
transform[0]="-t ${DT_zz0_def} -t ${DT_zz0_aff}"
#####################################################



#####################################################
T1_zz1_rigid_dir=/data/ywu94/data/redo_oldAtlas/1_T1_template_construction/new_corrected_total_rigid_dir
T1_zz1_def_dir=/data/ywu94/data/redo_oldAtlas/1_T1_template_construction/output_dir/defiteration7-average_T1_zz1_template

#####################################################
T1_zz1_rigid=${T1_zz1_rigid_dir}/${filename}_rigidto_ICBM152.txt
T1_zz1_aff=${T1_zz1_def_dir}/def_${filename}_rigidto_ICBM152_masked_to_temp7_init.txt
T1_zz1_def=${T1_zz1_def_dir}/def_${filename}_rigidto_ICBM152_masked_to_temp7_init.nii.gz
T1_zz1_update=${T1_zz1_def_dir}/update_meandeformation.nii.gz
#####################################################
transform[1]="-t ${T1_zz1_update} -t ${T1_zz1_def} -t ${T1_zz1_aff} -t ${T1_zz1_rigid}"
#####################################################


# GET DT transformations
#####################################################
for i in {2..20..3}
do 
	DT_def_dir="/data/ywu94/data/redo_oldAtlas/${i}_DTI_template_construction/DRTAMAS_iter6"
	DT_def="${DT_def_dir}/${filename}_DT_MINV_masked.nii.gz"
	DT_update="${DT_def_dir}/${filename}_DT_deffields_update.nii.gz"
	transform[$i]="-t ${DT_update} -t ${DT_def}"
done
#####################################################


# GET T1 transformations
#####################################################
for i in {4..19..3}
do 
	if [ -d "/data/ywu94/data/redo_oldAtlas/${i}_T1_template_construction/output_dir" ]
	then
	#last_folder=`ls /data/ywu94/data/redo_oldAtlas/${i}_T1_template_construction/output_dir/  | tail -1`
	#last_iter=${last_folder#defiteration}
	#T1_def_dir="/data/ywu94/data/redo_oldAtlas/${i}_T1_template_construction/output_dir/${last_folder}"

    T1_def_dir="/data/ywu94/data/redo_oldAtlas/${i}_T1_template_construction/output_dir/defiteration7"
    last_iter=7

	T1_aff="${T1_def_dir}/def_${filename}_to_temp${last_iter}_init.txt"
	T1_def="${T1_def_dir}/def_${filename}_to_temp${last_iter}_init.nii.gz"
	T1_update="${T1_def_dir}/update_meandeformation.nii.gz"
	transform[$i]="-t ${T1_update} -t ${T1_def} -t ${T1_aff}"
	fi
done
#####################################################



# GET FOD transformations
#####################################################
for i in {3..21..3}
do 
	FOD_def_dir="/data/ywu94/Final_template/3way_tests/T1-DTI-FOD/${i}_FOD_template_construction/template_fod"
	FOD_def="${FOD_def_dir}/${filename}_fod_warp.nii.gz"
	FOD_update="${FOD_def_dir}/${filename}_fod_warp_su.nii.gz"
	transform[$i]="-t ${FOD_update} -t ${FOD_def}"
done
#####################################################



#####################################################
trans_iter=${zigzag#zz}
trans_iter=$(($trans_iter+0))

output_transformations=""

if [[ "$DTorT1orFOD" == "DT" ]]
then
	for ((count=${trans_iter}; count>=0; count--))
	do 
		output_transformations="${output_transformations} ${transform[$count]}"
	done

elif [[ "$DTorT1orFOD" == "T1" ]]
then
	for ((count=${trans_iter}; count>=1; count--))
	do 
		output_transformations="${output_transformations} ${transform[$count]}"
	done

elif [[ "$DTorT1orFOD" == "FOD" ]]
then
	for ((count=${trans_iter}; count>=0; count--))
	do 
		output_transformations="${output_transformations} ${transform[$count]}"
	done
fi

output_transformations="${output_transformations#"${output_transformations%%[![:space:]]*}"}"
echo "${output_transformations}"



















