#!/bin/bash

# script that uses the EDDP wobble phonon code to calculate the vibrational energies of a set of structures which were generated and whose whose static-lattice energies were calculated using the 2D_QHA_generate_and_singlepoint.sh script
# must be run in the corresponding good_castep directory

#input variables
max_temp=$1 # highest temperature at which to print out the thermal energies
t_step=$2 # temperature increment
natoms_supercell=$3 # number of atoms in the supercell used for the phonon calculation
ompnp=$4 # number of parallel threads per job

if [ "$#" -lt 4 ]; then
        echo "Usage: 2D_QHA_phonons.sh max_temp t_step natoms_supercell ompnp"
        exit 1
fi

# translate [max_temp, step] into the wobble-used [max_temp,ntemp]
ntemp=$(awk "BEGIN {print 1+$max_temp/$t_step; exit}")

# calculate number of simultaneous jobs such that the node is filled up
num_threads=`lscpu | awk '/^CPU\(s\)/ {print $2}'`
threads_per_core=`lscpu | awk '/Thread/ {print $4}'`
num_cores=$(awk "BEGIN {print $num_threads/$threads_per_core; exit}")
num_simultaneous_jobs=$(awk "BEGIN {print $num_cores/$ompnp; exit}")

# set up counter to launch a number of jobs simultaneously
counter=0

# iterate over every single res file present in the directory
for i in *.res; do
	seed=${i%.*}
	form_name=`echo $i | awk 'BEGIN {FS="-"} {print $1}'`

	# check if we have an appropriate EDDP file - else exit
        if [ ! -f ../${form_name}.eddp ]; then
                echo "No appropriate EDDP file ../${form_name}.eddp. Exiting."
                exit 1
        fi
	
	# copy the relevant .eddp to match the complete fileroot of the .res file
	awk '{print "../" $0}' ../${form_name}.eddp > ${seed}.eddp
	
	cabal res cell < ${seed}.res > ${seed}.cell

	# run wobble - stdout contains nothing but the energies [eV] as a function of temperature
	wobble -therm -ompnp $ompnp -natom $natoms_supercell -unit meV -tmax $max_temp -ntemp $ntemp $seed 1> ${seed}_temperature_energy.dat 2> wobble.log &
	
	counter=$((counter+1))

	if [ $counter -eq $num_simultaneous_jobs ]; then
                wait
                # all jobs are done; next num_cores jobs can be started
                counter=0
	fi

done

for i in *.res; do
        seed=${i%.*}

	# wobble seems to create this even when -dos is not specified in the command - here, we delete it
	rm -f ${seed}-dos.agr
	
	while read line; do

		temp=`echo $line | awk '{print $1}'`
		energy=`echo $line | awk '{print $2}'`

		if [ ! -d temp_${temp}_K ]; then
			mkdir temp_${temp}_K
		fi
		
		if [ $energy != "-Infinity" ]; then
		
			# the energy in wobble becomes infinite when there are (a large number of?) soft modes - we neglect them here as they break the fit
			# add the vibrational energy to the enthalpy
			awk -v CONVFMT=%.14g -v awk_energy=$energy '/TITL/ {gsub(/\-[1-9]+[0-9]*\.\S*/, $5+awk_energy)} 1' $i > temp_${temp}_K/${i}

		fi

	done < ${seed}_temperature_energy.dat
	
	# rm ${seed}.eddp	

done
