Globals.includeSubfolders;
Options.usingGpuComputation(false);
rng('shuffle', 'twister');

model = HarmonicOscillator(2000);
model.Parameter.Temperature = 1;
model.Potential.Parameter.SpringRate = 1;
integrator = VVASLLOD;
thermostat = LangevinThermostat;
thermostat.Parameter.FrictionConstant = 1;
dt = 1;

NAME = "sim2";
simulation = Simulation("sim2") ...
    .setup(model, integrator, thermostat, dt) ...
    .track(Average(Temperature)) ...
    .track(Average(Energy)) ...
    .track(Average(ConfigurationalTemperature)) ...
    .until(StepLimit(10^7));

SAVEDIR = "cpu.MeanSquareDisplacement.mogonlib";
NAMINGCONVENTION = "{Model.Class}/{Integrator.Class}.{Thermostat.Class}/N_{Model.N}/Temperature_{Model.Temperature}/ShearRate_{Model.ShearRate}/dt_{dt}";
library = Library();
library.tryLockSimulation(simulation, NAMINGCONVENTION)
if library.hasLockedSimulation(simulation, NAMINGCONVENTION)
    simulation.run();
    library.saveSimulation(exp, NAMINGCONVENTION);
    library.releaseSimulation();
else
    Globals.log("Failed to lock Simulation '%s', because it's already locked.", NAME);
end