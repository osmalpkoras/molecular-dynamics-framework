Globals.includeSubfolders;
Options.usingGpuComputation(false);
rng('shuffle', 'twister');

model = DoubleWell(10000);
model.Parameter.Temperature = 1;
integrator = VVASLLOD;
thermostat = LangevinThermostat;
thermostat.Parameter.FrictionConstant = 1;
dt = 1;

NAME = 'simulation_1';
simulation = Simulation(Name) ...
    .setup(model, integrator, thermostat, dt) ...
    .track(Average(ConfigurationalTemperature)) ...
    .until(StepLimit(10^9));

% set the directory in which to save the library
SAVEDIR = 'cpu.Doublewell.mogonlib';
% set the directory naming convention, where each simulation should be saved
NAMINGCONVENTION = '{Model.Class}/{Integrator.Class}.{Thermostat.Class}/N_{Model.N}/Temperature_{Model.Temperature}/ShearRate_{Model.ShearRate}/dt_{dt}';

% initialize library
library = Library();
% lock the simulation inside the library
library.tryLockSimulation(simulation, NAMINGCONVENTION)
if library.hasLockedSimulation(simulation, NAMINGCONVENTION)
    % run the simulation when lock has been acquired
    simulation.run();
    % save simulation and release lock
    library.saveSimulation(exp, NAMINGCONVENTION);
    library.releaseSimulation();
else
    Globals.log('Failed to lock Simulation "%s", because its already locked.', NAME);
end