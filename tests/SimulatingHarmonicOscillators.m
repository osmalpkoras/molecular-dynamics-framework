Globals.includeSubfolders;
Options.usingGpuComputation(false);
rng('shuffle', 'twister');

for M = [1 10 100 1000 10000 20000 50000 10^5]
    model = HarmonicOscillator(1000);
    model.Parameter.Temperature = 1;
    model.Potential.Parameter.SpringRate = 1;
    thermostat = LangevinThermostat;
    thermostat.Parameter.FrictionConstant = 1;

    simulation = Simulation() ...
        .setup(model, BAOAB, thermostat, 0.2) ...
        .track(Average(Temperature)) ...
        .track(Average(Energy)) ...
        .track(Average(ConfigurationalTemperature)) ...
        .until(StepLimit(10^5)) ...
        .run();
    fprintf(" & %s", num2str(round(simulation.TotalRuntime, 2)));
end