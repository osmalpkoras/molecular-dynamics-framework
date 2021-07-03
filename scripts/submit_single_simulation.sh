#!/bin/bash
#SBATCH -J MAT
#SBATCH -N 1
#SBATCH -n 1
#SBATCH -e STDERR.%J
#SBATCH -o STDOUT.%J
#SBATCH -A account_name
#SBATCH --mem-per-cpu=700M

module purge
module load math/MATLAB/2018b

# Param     Bedeutung
#-----------------------------------------------------
#  $1       Ausgabepfad (ohne trailing slash)
#  $4+      matlab-like name-value parameter pairs

matlabdir=/parentdir/MATLAB/2018b

srun -n 1 ../../../run_SimulateOnMogon.sh "$matlabdir" "SAVEDIR" "../../../$1" MODE "$3" "${@:4}"