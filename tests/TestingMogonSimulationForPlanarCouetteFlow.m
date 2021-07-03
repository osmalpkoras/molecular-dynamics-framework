Globals.includeSubfolders;

mode = "equillibrate";
savedir = "gpu.PlanarCouetteFlow.mogonlib";

dts = [0.01 0.005 0.0025 0.001];
skips = ["0.12" "0.4"];
solvers = ["VVASLLOD" "BAOAB"];
thermostats = ["IsokineticThermostat" "LangevinThermostat().set('FrictionConstant', 1)"];
M = "25";
for k = 1:1
    tLen = length(solvers);
    for i = 1:tLen
        parfor (j = 1:length(dts), 3)
            dt = dts(j);
            NAMINGCONVENTION = "{Model.Class}/{Integrator.Class}.{Thermostat.Class}/N_{Model.N}/Temperature_{Model.Temperature}/ShearRate_{Model.ShearRate}/dt_{dt}";
            MODEL = sprintf("PlanarCouetteFlow(%s).set('N', 400, 'Density', 0.8, 'Temperature', 1, 'ShearRate', 0)", M);
            POTENTIAL = "WCAPotential().set('CutOffRadius', 2^(1/6))";
            INTEGRATOR = solvers(i);
            THERMOSTAT = thermostats(i);
            NAME = sprintf("simul_M%s_%s", M, num2str(k));
            DT = dt;
            skip=skips(i);
            TRACKERS=sprintf("Average(Temperature).skip(%s) Average(ConfigurationalTemperature).skip(%s) Average(Energy).skip(%s) Average(ThermalStressTensor).skip(%s)", skip, skip, skip, skip);
            if isequal(mode, "run")
                UNTIL="SampleSizeLimit((1:10)*1000)";
            else
                UNTIL="TimeLimit(10)";
            end
            SimulateOnMogon("SAVEDIR", savedir, "NAME", NAME, "MODEL", MODEL, "POTENTIAL", POTENTIAL, "INTEGRATOR", INTEGRATOR, "THERMOSTAT", THERMOSTAT, "UNTIL", UNTIL, "DT", DT, "TRACKERS", TRACKERS, "NAMINGCONVENTION", NAMINGCONVENTION, "MODE", mode, "GPU", "true");
        end
    end
end