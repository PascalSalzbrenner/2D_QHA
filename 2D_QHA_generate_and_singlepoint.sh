# script to generate structures where we must optimise both volumes and angles and then do singlepoint calculations on them
# note that the .param and .cell (CASTEP) or .par and .eddp (repose) files specifying the job must be present already

# input variables
# minimum and maximum lattice parameters, lattice parameter step
a_min=$1
a_max=$2
a_step=$3
# minimum and maximum angles, angle step
alpha_min=$4
alpha_max=$5
alpha_step=$6
# energy solver - dft, eddp
energy_solver=$7
# number of mpi parallel threads per job
mpinp=$8

if [ "$#" -lt 8 ]; then
	echo "Usage: 2D_QHA_generate_and_singlepoint.sh a_min a_max a_step alpha_min alpha_max alpha_step energy_solver mpinp"
	exit 1
fi

function generate_R3_bar_m {

for a in `seq $a_min $a_step $a_max`; do
	for alpha in `seq $alpha_min $alpha_step $alpha_max`; do
		echo "%block lattice_abc" > temp.cell
		echo "$a $a $a" >> temp.cell
		echo "$alpha $alpha $alpha" >> temp.cell
		echo "%endblock lattice_abc" >> temp.cell
		echo "" >> temp.cell
		echo "%block positions_frac" >> temp.cell
		echo "$element 0 0 0" >> temp.cell
		echo "%endblock positions_frac" >> temp.cell

		cabal cell res < temp.cell > hopper/${element}-a_${a//.}-alpha_${alpha//.}.res

	done
done

rm temp.cell

}

num_threads=`lscpu | awk '/^CPU\(s\)/ {print $2}'`
threads_per_core=`lscpu | awk '/Thread/ {print $4}'`
num_cores=$(awk "BEGIN {print $num_threads/$threads_per_core; exit}")
num_simultaneous_jobs=$(awk "BEGIN {print $num_cores/$mpinp; exit}")

# determine element from the fileroot
if [ $energy_solver == "dft" ]; then
	filename=`ls *.param`
else
	filename=`ls *.par`
fi

element=${filename%.*}

if [ ! -d hopper ]; then
	mkdir hopper
	generate_R3_bar_m
fi

if [ $energy_solver == "dft" ]; then
	exec=""
else
	exec="-repose"
fi

for i in `seq 1 $num_simultaneous_jobs`; do
	crud.pl -mpinp $mpinp $exec &
done

wait
