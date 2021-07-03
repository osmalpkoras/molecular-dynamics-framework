Globals.includeSubfolders;
Globals.VerbosityLevel("log");
Options.usingGpuComputation(false);
rng("shuffle", "twister");

srs = [0 0.1 0.2 0.3 0.4 0.5];
steps = [0.01 0.005 0.001];
limits = [5000 2500 500];
srs = [0.2];
steps = [0.01];
limits = [5];
maxSteps = length(steps);

for sr = srs
    for i = 1:maxSteps
        Globals.log("Start of new iteration with\n\tshear rate: %f\n\tstep size:  %f\n\ttime limit: %f", sr, steps(i), limits(i));
        model = PlanarCouetteFlow(10);
        model.Parameter.ShearRate = sr;
        model.Parameter.Density = 0.8;
        model.Parameter.Temperature = 1;
        model.Parameter.N = 400;
        model.Potential = WCAPotential;
        model.Potential.Parameter.CutOffRadius = 2^(1/6);
        thermostat = IsokineticThermostat;
        
        simulation = Simulation() ...
            .setup(model, VVASLLOD, thermostat, steps(i)) ...
            .track(History(Energy)) ...
            .track(History(StressTensor)) ...
            .until(TimeLimit(limits(i))) ...
            .run();
    end
end