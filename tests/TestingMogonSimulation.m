Globals.includeSubfolders;

model = "PlanarCouetteFlow(25).set('N', 400, 'Density', 0.8, 'Temperature', 1, 'ShearRate', 0)";
potential = "WCAPotential().set('CutOffRadius', 2^(1/6))";
trackers = "History(Position).skip(0.2) History(Impulse).skip(0.2)";
namingconvention = "{Model.Class}/{Integrator.Class}.{Thermostat.Class}/Temperature_{Model.Temperature}/ShearRate_{Model.ShearRate}/dt_{dt}";
dts=["0.01" "0.005" "0.0025" "0.001"];
solvers=["VVASLLOD" "BAOAB"];
thermostats=["IsokineticThermostat" "LangevinThermostat().set('FrictionConstant', 1)"];
limit="TimeLimit(10)";

for dt = dts
    for i = 1:length(solvers)
        SimulateOnMogon("SAVEDIR", "testmogonlib", "NAME", "simul5", "MODEL", model, "POTENTIAL", potential, "INTEGRATOR", solvers(i), "THERMOSTAT", thermostats(i), "UNTIL", limit, "DT", dt, "TRACKERS", trackers, "NAMINGCONVENTION", namingconvention, "MODE", "equillibrate", "GPU", "true");
    end
end

