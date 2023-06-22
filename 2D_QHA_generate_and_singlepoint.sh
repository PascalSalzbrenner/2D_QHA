# script to generate structures where we must optimise both volumes and angles and then do singlepoint calculations on them

# input variables
# minimum and maximum volumes
vmin=$1
vmax=$2
# minimum and maximum angles
amin=$3
amax=$4
# energy solver - DFT, EDDP
energy_solver=$5

if [ "$#" -lt 5 ]; then
	echo "Usage: 2D_QHA_generate_and_singlepoint.sh vmin vmax amin amax energy_solver"
	exit 1
fi

function generate_R-3m {


}
