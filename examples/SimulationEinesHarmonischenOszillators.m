% include all subfolders, allows Matlab to find other classes
Globals.includeSubfolders; 
% run the simulation on the GPU
Options.usingGpuComputation(false);
rng('shuffle', 'twister');

% initialize the harmonic oscillator
M = 1000;
model = HarmonicOscillator(M);
model.Parameter.Temperature = 1;
% initialize the potential
model.Potential.Parameter.SpringRate = 1;
% initialize the integrator
integrator = ABOBA;
% initialize the thermostat
thermostat = LangevinThermostat;
thermostat.Parameter.FrictionConstant = 1;
% set the integrator step size
dt = 0.2;

simulation = Simulation() ...
    .setup(model, integrator, thermostat, dt) ...
    .track(Average(Temperature)) ...
    .track(Average(Energy)) ...
    .track(Average(ConfigurationalTemperature)) ...
    .until(StepLimit(10^5)) ...
    .run();