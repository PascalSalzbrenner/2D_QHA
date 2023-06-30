#!/bin/bash

# script that uses the EDDP wobble phonon code to calculate the vibrational energies of a set of structures which were generated and whose whose static-lattice energies were calculated using the 2D_QHA_generate_and_singlepoint.sh script
# must be run in the corresponding good_castep directory

while getopts ":t:s:n:r:m:h" opt; do
        case $opt in
                t)
			# maximum temperature at which we evaluate the vibrational energy
                        max_temp=$OPTARG;;
                s)
			# step between temperatures
                        t_step=$OPTARG;;
                n)
			# number of atoms for the supercell
			natoms_supercell=$OPTARG;;
                h)
                        echo "Script to calculate the vibrational energy of structures at different temperatures"
                        echo "Usage: 2D_QHA_phonons.sh [-t max_temp] [-s t_step] [-n natoms_supercell]"
                        echo ""
                        echo "Optional arguments"
                        echo "-t max_temp [K]        : the highest temperature at which the vibrational energy is evaluated"
                        echo "-s t_step [K]          : the increment between successive temperatures at which the vibrational energy is evaluated "
                        echo "-n natoms_supercell    : the number of atoms in the supercell used for the phonon calculation"
                        echo "-h                     : print this message and exit"
                        echo ""
                        echo "If no variables are supplied, the following defaults are used: -t 1000 -s 25 -n 1000"
                        exit 1
        esac
done

if [ -z $max_temp ]; then
	max_temp=1000
fi

if [ -z $t_step ]; then
	t_step=25
fi

if [ -z $natoms_supercell ]; then
	natoms_supercell=1000
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
