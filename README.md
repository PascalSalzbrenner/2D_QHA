A collection of bash scripts to optimise the free energy of structures with 2 degrees of freedom using the quasiharmonic approximation (QHA).

An example is the beta-Po structure, which has R-3m symmetry and a single atom in the unit cell. Those the two degrees of freedom (at a given pressure) are the volume and the rhombohedral angle. Currently, this type of structure is the only supported one. The technique should however be easily extensible to other cases.

The way it works is as follows:
1) Generation and singlepoint energy calculations of input structures with specified ranges of volumes and angles - `2D_QHA_generate_and_singlepoint.sh`. Supports repose and CASTEP.
2) Phonon calculations for every structure we have a singlepoint calculation for - `2D_QHA_phonons.sh`. Due to the generally high expense of these calculations, this is only supported with wobble.
3) Interpolation - `2D_QHA_interpolate.py`

These scripts are connected together by the `2D_QHA.sh` script.
