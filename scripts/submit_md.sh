#!/bin/bash

# Param   Bedeutung
#-----------------------------------------------------
#  $1     Temperatur
#  $2     Scherrate
#  $3     Reibungskonstante
#  $4     Der Modus, in dem die Simulation ausgeführt wird.
#         Mit "test" wird für die eingegebenen Parameter ein kurzer Testlauf gestartet und beendet.
#         Mit "equillibrate" werden equillibrierte Daten generiert, die dann mit "run" fortgesetzt werden können
#         Mit "run" wird die fortgeschrittenste Simulation mit angegebenem Namen für die jeweiligen Parameter fortgesetzt.

temperature="$1";
shearrate="$2";
frictionconstant="$3";
mode="${4:-run}";
savedir="cpu.PlanarCouetteFlow.mogonlib";
outputdir="$savedir/OUTPUT/$mode";
mkdir -p "$outputdir";

dts=(0.001);
NSteps=("150000+[10000 20000 30000 40000 50000]");
dts=(0.0063 0.0079);
NSteps=("(1:10)*10000" "(1:10)*10000");

N=100;
M=10;

for k in {1..10}; do
    iLen=${#dts[@]}
    for (( p=0; p<${iLen}; p++ )); do
        NAMINGCONVENTION="{Model.Class}/{Integrator.Class}.{Thermostat.Class}/N_{Model.N}/Temperature_{Model.Temperature}/ShearRate_{Model.ShearRate}/dt_{dt}";
        MODEL="PlanarCouetteFlow(${M}).set('N', $N, 'Density', 0.8, 'Temperature', $temperature, 'ShearRate', $shearrate)";
        POTENTIAL="WCAPotential().set('CutOffRadius', 2^(1/6))";
        GPU="false";
        DT="${dts[$p]}";
        NAME="simul_M${M}_${k}"
        if [ "$mode" == "run" ]; then
            sbatchParams="-p smp -t 05-00:00";
            UNTIL="SampleSizeLimit(${NSteps[$p]})";
        else
            sbatchParams="-p smp -t 00-05:00";
            UNTIL="TimeLimit(10)";
        fi
        
        solvers=(VVASLLOD);
        skip="0.12";
        TRACKERS="History(Temperature).skip(${skip}) History(ThermalStressTensor).skip(${skip}) History(Energy).skip(${skip}) History(ConfigurationalTemperature).skip(${skip})";    
        THERMOSTAT=("IsokineticThermostat");
        tLen=${#solvers[@]}
        for (( i=0; i<${tLen}; i++ )); do
            INTEGRATOR="${solvers[$i]}";   
            sbatch $sbatchParams -D "$outputdir" submit_single_simulation.sh "$savedir" MODE "$mode" NAME "$NAME" MODEL "$MODEL" POTENTIAL "$POTENTIAL" INTEGRATOR "$INTEGRATOR" THERMOSTAT "$THERMOSTAT" TRACKERS "$TRACKERS" DT "$DT" UNTIL "$UNTIL" NAMINGCONVENTION "$NAMINGCONVENTION" GPU "$GPU"
        done

        solvers=(ABOBA BAOAB);
        skip="0.4";
        TRACKERS="History(Temperature).skip(${skip}) History(ThermalStressTensor).skip(${skip}) History(Energy).skip(${skip}) History(ConfigurationalTemperature).skip(0.2)";
        THERMOSTAT=("LangevinThermostat().set('FrictionConstant', $frictionconstant)");
        tLen=${#solvers[@]}
        for (( i=0; i<${tLen}; i++ )); do
            INTEGRATOR="${solvers[$i]}";
            sbatch $sbatchParams -D "$outputdir" submit_single_simulation.sh "$savedir" MODE "$mode" NAME "$NAME" MODEL "$MODEL" POTENTIAL "$POTENTIAL" INTEGRATOR "$INTEGRATOR" THERMOSTAT "$THERMOSTAT" TRACKERS "$TRACKERS" DT "$DT" UNTIL "$UNTIL" NAMINGCONVENTION "$NAMINGCONVENTION" GPU "$GPU"
        done
    done  
done

