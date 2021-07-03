#!/bin/bash

# Param   Bedeutung
#-----------------------------------------------------
#   $1    Der Modus, in dem die Simulation ausgeführt wird.
#         Mit "test" wird für die eingegebenen Parameter ein kurzer Testlauf gestartet und beendet.
#         Mit "equillibrate" werden equillibrierte Daten generiert, die dann mit "run" fortgesetzt werden können
#         Mit "run" wird die fortgeschrittenste Simulation mit angegebenem Namen für die jeweiligen Parameter fortgesetzt.

mode="${1:-run}";
savedir="DoubleWell.mogonlib";
outputdir="$savedir/OUTPUT/$mode";
mkdir -p "$outputdir";

dts=(0.02    0.2000    0.21    0.22    0.231    0.243    0.255    0.268    0.281);
solvers=(BAOAB ABOBA SPV VVASLLOD);
thermostats=("LangevinThermostat().set('FrictionConstant',1)" "LangevinThermostat().set('FrictionConstant',1)" "LangevinThermostat().set('FrictionConstant',1)" "LangevinThermostat().set('FrictionConstant',1)");
Ndatapoints=("(1:10)*10^8");
M=500

for k in {1..1}; do
    tLen=${#solvers[@]}
    for (( i=0; i<${tLen}; i++ )); do
        for Ndp in ${Ndatapoints[@]}; do
            for dt in ${dts[@]}; do
                NAMINGCONVENTION="{Model.Class}/{Integrator.Class}.{Thermostat.Class}/dt_{dt}";
                MODEL="DoubleWell(${M}).set('Temperature',1)";
                INTEGRATOR="${solvers[$i]}";
                THERMOSTAT="${thermostats[$i]}";
                DT="$dt";
                NAME="simul_M${M}_${k}"
                TRACKERS="Average(Temperature) Average(ConfigurationalTemperature) Average(Energy)";
                if [ "$mode" == "run" ]; then
                    sbatchParams="-p smp -t 05-00:00";
                    UNTIL="StepLimit($Ndp)";
                else
                    sbatchParams="-p smp -t 00-05:00";
                    UNTIL="StepLimit(100)";
                fi
                sbatch $sbatchParams -D "$outputdir" submit_single_simulation.sh "$savedir" MODE "$mode" NAME "$NAME" MODEL "$MODEL" INTEGRATOR "$INTEGRATOR" THERMOSTAT "$THERMOSTAT" TRACKERS "$TRACKERS" DT "$DT" UNTIL "$UNTIL" NAMINGCONVENTION "$NAMINGCONVENTION"
            done
        done  
    done
done