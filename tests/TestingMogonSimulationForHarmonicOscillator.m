Globals.includeSubfolders;

mode = "run";
savedir = "HarmonicOscillator.mogonlib";

dts = [1.9000    1.5477    1.2607    1.0269    0.8365    0.6814    0.5550    0.4521    0.3683    0.3000];
solvers = ["ABOBA"];
thermostats = ["LangevinThermostat().set('FrictionConstant', 1)"];
Ndatapoints = "1000000";
for k = 1:1
    tLen = length(solvers);
    for i = 1:tLen
        for Ndp = Ndatapoints
            parfor j = 1:length(dts)
                dt = dts(j);
                NAMINGCONVENTION = "{Model.Class}/{Integrator.Class}.{Thermostat.Class}/N_{Model.N}/Temperature_{Model.Temperature}/dt{dt}";
                MODEL = "HarmonicOscillator(20000).set('Temperature', 1)";
                POTENTIAL = "HarmonicOscillatorPotential().set('SpringRate', 1)";
                INTEGRATOR = solvers(i);
                THERMOSTAT = thermostats(i);
                NAME = sprintf("simul_%s_%s", num2str(Ndp), num2str(k));
                DT = dt;
                skip="0";
                TRACKERS=sprintf("Average(Temperature).skip(%s) Average(ConfigurationalTemperature).skip(%s) Average(Energy).skip(%s) Average(SquaredPosition).skip(%s)", skip, skip, skip, skip);
                if isequal(mode, "run")
                    UNTIL=sprintf("StepLimit(%s)", Ndp);
                else
                    UNTIL="StepLimit(100)";
                end
                SimulateOnMogon("SAVEDIR", savedir, "NAME", NAME, "MODEL", MODEL, "POTENTIAL", POTENTIAL, "INTEGRATOR", INTEGRATOR, "THERMOSTAT", THERMOSTAT, "UNTIL", UNTIL, "DT", DT, "TRACKERS", TRACKERS, "NAMINGCONVENTION", NAMINGCONVENTION, "MODE", mode);
            end
        end
    end
end