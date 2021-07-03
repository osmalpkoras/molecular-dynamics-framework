Globals.includeSubfolders;

Options.usingGpuComputation(false);
rng('shuffle', 'twister');

model = DoubleWell(10000);
model.Parameter.Temperature = 1;
thermostat = LangevinThermostat;
thermostat.Parameter.FrictionConstant = 1;
simulation = Simulation("simul_1") ...
    .setup(model, BAOAB, thermostat, 0.2) ...
    .track(Average(ConfigurationalTemperature)) ...
    .track(Average(Temperature)) ...
    .track(Average(Energy));

simulation.until(TimeLimit(10)) ...
    .equillibrate();

simulation.until(StepLimit(5000)) ...
    .run();