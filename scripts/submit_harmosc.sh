#!/bin/bash

# Param   Bedeutung
#-----------------------------------------------------
#   $1    Der Modus, in dem die Simulation ausgeführt wird.
#         Mit "test" wird für die eingegebenen Parameter ein kurzer Testlauf gestartet und beendet.
#         Mit "equillibrate" werden equillibrierte Daten generiert, die dann mit "run" fortgesetzt werden können
#         Mit "run" wird die fortgeschrittenste Simulation mit angegebenem Namen für die jeweiligen Parameter fortgesetzt.

mode="${1:-run}";
savedir="HarmonicOscillator.history.mogonlib";
outputdir="$savedir/OUTPUT/$mode";
mkdir -p "$outputdir";

dts=(1.9000    1.5477    1.2607    1.0269    0.8365    0.6814    0.5550    0.4521    0.3683    0.3000);
solvers=(BAOAB ABOBA SPV VVASLLOD);
thermostats=("LangevinThermostat().set('FrictionConstant', 1)" "LangevinThermostat().set('FrictionConstant', 1)" "LangevinThermostat().set('FrictionConstant', 1)" "LangevinThermostat().set('FrictionConstant', 1)");
Ndatapoints=(1000000 10000000 100000000);
for k in {1..1}; do
    tLen=${#solvers[@]}
    for (( i=0; i<${tLen}; i++ )); do
        for Ndp in ${Ndatapoints[@]}; do
            for dt in ${dts[@]}; do
                NAMINGCONVENTION="{Model.Class}/{Integrator.Class}.{Thermostat.Class}/N_{Model.N}/Temperature_{Model.Temperature}/dt_{dt}"
                MODEL="HarmonicOscillator(2*10^10/$Ndp).set('Temperature', 1)";
                POTENTIAL="HarmonicOscillatorPotential().set('SpringRate', 1)";
                INTEGRATOR="${solvers[$i]}";
                THERMOSTAT="${thermostats[$i]}";
                DT="$dt";
		        skip="0";
		        TRACKERS="Average(Temperature).skip(${skip}) Average(ConfigurationalTemperature).skip(${skip}) Average(Energy).skip(${skip}) Average(SquaredPosition).skip(${skip})";
                if [ "$mode" == "run" ]; then
                    sbatchParams="-p smp -t 05-00:00";
                    UNTIL="SampleSizeLimit($Ndp)";
                else
                    sbatchParams="-p smp -t 00-05:00";
                    UNTIL="StepLimit(100)";
                fi
                sbatch $sbatchParams -D "$outputdir" submit_single_simulation.sh "$savedir" MODE "$mode" NAME "simul_${Ndp}_${k}" MODEL "$MODEL" POTENTIAL "$POTENTIAL" INTEGRATOR "$INTEGRATOR" THERMOSTAT "$THERMOSTAT" TRACKERS "$TRACKERS" DT "$DT" UNTIL "$UNTIL" NAMINGCONVENTION "$NAMINGCONVENTION"
            done
        done  
    done
done
