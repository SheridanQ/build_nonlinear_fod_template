input_subj=${1}
mean=${2}

if [ $# -lt 2 ]
then
	echo "Usage: `basement $0` input_subj_list average_mif"
	exit
fi

string=""
for subj in `cat ${input_subj}`
do
	string="${string} ${subj}"
done

echo ${string}

mrmath ${string} mean ${mean} -force -nthreads 0