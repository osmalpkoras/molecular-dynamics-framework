#!/bin/bash
module load math/MATLAB/2018b
mcc -m -R -nodisplay -a ./classes -a ./Globals.m -a ./ParseSimulationInputParameters.m SimulateOnMogon.m
