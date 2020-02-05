fac1=${1}
fac2=${2}
product=${3}

if [ $# -lt 3 ]
then
	echo "Usage: `basement $0` factor1 factor2 product"
	exit
fi

mrcalc ${fac1} ${fac2} -mul ${product} -force -nthreads 0