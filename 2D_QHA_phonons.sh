#!/bin/bash

# script that uses the EDDP wobble phonon code to calculate the vibrational energies of a set of structures which were generated and whose whose static-lattice energies were calculated using the 2D_QHA_generate_and_singlepoint.sh script
# must be run in the corresponding good_castep directory

#input variables
max_temp=$1 # highest temperature at which to print out the thermal energies
t_step=$2 # temperature increment
natom_supercell=$3 # number of atoms in the supercell used for the phonon calculation

if [ "$#" -lt 8 ]; then
        echo "Usage: 2D_QHA_phonons.sh max_temp t_step natom_supercell"
        exit 1
fi

# translate [max_temp, step] into the wobble-used [max_temp,ntemp]
ntemp=$(awk "BEGIN {print 1+$max_temp/$t_step; exit}")

# iterate over every single res file present in the directory
for i in *.res; do
	seed=${i%.*}
	form_name=`echo $i | awk 'BEGIN {FS="-"} {print $1}'`
	
	# copy the relevant .eddp to match the complete fileroot of the .res file
	awk '{print "../" $0}' ../${form_name}.eddp > ${seed}.eddp
	
	cabal res cell < ${seed}.res > ${seed}.cell

	# run wobble - stdout contains nothing but the energies [eV] as a function of temperature
	wobble -therm -natom $natoms_supercell -unit meV -tmax $max_temp -ntemp $ntemp $seed 1> ${seed}_temperature_energy.dat 2> wobble.log
	
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
