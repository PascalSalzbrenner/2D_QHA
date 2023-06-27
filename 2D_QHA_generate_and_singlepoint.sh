# script to generate structures where we must optimise both volumes and angles and then do singlepoint calculations on them

# input variables
# minimum and maximum lattice parameters, lattice parameter step
a_min=$1
a_max=$2
a_step=$3
# minimum and maximum angles, angle step
alpha_min=$4
alpha_max=$5
alpha_step=$6
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

for a in `seq $a_min $a_max $a_step`; do
	for alpha in `seq $alpha_min $alpha_max $alpha_step`; do
		echo "%block lattice_abc" > temp.cell
		echo "$a $a $a" >> temp.cell
		echo "$alpha $alpha $alpha" >> temp.cell
		echo "%endblock lattice_abc" >> temp.cell
		echo "" >> temp.cell
		echo "%block positions_frac" >> temp.cell
		echo "$element 0 0 0" >> temp.cell
		echo "%endblock positions_frac" >> temp.cell

		cabal cell res < temp.cell > hopper/${element}-a_${a}-alpha_${alpha}.res

	done
done

}
