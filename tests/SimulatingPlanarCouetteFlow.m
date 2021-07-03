Globals.includeSubfolders;
Globals.VerbosityLevel("debug");
Options.usingGpuComputation(true);
rng("shuffle", "twister");

model = PlanarCouetteFlow(50);
model.Parameter.ShearRate = 0;
model.Parameter.Density = 0.8;
model.Parameter.Temperature = 1;
model.Parameter.N = 400;
model.Potential = WCAPotential;
model.Potential.Parameter.CutOffRadius = 2^(1/6);
langthermostat = LangevinThermostat;
langthermostat.Parameter.FrictionConstant = 1;
thermostat = FlyingIsokineticThermostat;

dt = 0.01;
NAME = "meansquaredisplacement";
simulation = Simulation(NAME) ...
    .setup(model, BAOAB, langthermostat, dt) ...   
    .track(Average(MeanSquareDisplacement(unique(round(logspace(-2, 1, 30), 2)))).from(0).to(200)) ...
    .track(Average(MeanSquareDisplacement(unique(round(logspace(-2, 1, 30), 2)))).from(1000).to(1200)) ...
    .track(Average(MeanSquareDisplacement(unique(round(logspace(-2, 1, 30), 2)))).from(2000).to(2200)) ...
    .track(Average(MeanSquareDisplacement(unique(round(logspace(-2, 1, 30), 2)))).from(3000).to(3200)) ...
    .track(Average(MeanSquareDisplacement(unique(round(logspace(-2, 1, 30), 2)))).from(4000).to(4200)) ...
    .track(Average(MeanSquareDisplacement(unique(round(logspace(-2, 1, 30), 2)))).from(5000).to(5200));

simulation.until(SampleSizeLimit(10)) ...
    .run();
    
SAVEDIR = "MeanSquareDisplacement.mogonlib";
NAMINGCONVENTION = "{Model.Class}/{Integrator.Class}.{Thermostat.Class}/N_{Model.N}/Temperature_{Model.Temperature}/ShearRate_{Model.ShearRate}/dt_{dt}";
library = Library(SAVEDIR);
library.tryLockSimulation(simulation, NAMINGCONVENTION)
if library.hasLockedSimulation(simulation, NAMINGCONVENTION)
    simulation.until(SampleSizeLimit(10000)) ...
        .run();
    library.saveSimulation(simulation, NAMINGCONVENTION);
    library.releaseSimulation();
else
    Globals.log("Failed to lock Simulation '%s', because it's already locked.", NAME);
end