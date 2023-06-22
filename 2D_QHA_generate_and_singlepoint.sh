# script to generate structures where we must optimise both volumes and angles and then do singlepoint calculations on them

# input variables
# minimum and maximum volumes, volume step
vmin=$1
vmax=$2
vstep=$3
# minimum and maximum angles, angle step
amin=$4
amax=$5
astep=$6
# element - currently, single element is supported
element=$7
# energy solver - DFT, EDDP
energy_solver=$8

if [ "$#" -lt 8 ]; then
	echo "Usage: 2D_QHA_generate_and_singlepoint.sh vmin vmax vstep amin amax astep element energy_solver"
	exit 1
fi

function generate_R-3m {

mkdir hopper

for vol in `seq $vmin $vmax $vstep`; do
	for angle in `seq $amin $amax $astep`; do
		echo "TITL ${element}-${vol}_${angle} 0.000000000000 $vol 0.000000000000  0.00  0.00 1 (R-3m) n - 1" > hopper/${element}-${vol}_${angle}.res
		
				

	done
done

}
