% include all subfolders, allows Matlab to find other classes
Globals.includeSubfolders; 
% run the simulation on the GPU
Options.usingGpuComputation(true);

% initialize the planar couette flow
model = PlanarCouetteFlow(10); 
model.Parameter.ShearRate = 2;
model.Parameter.Density = 0.8;
model.Parameter.Temperature = 1;
model.Parameter.N = 100;
% initialize the potential
model.Potential = WCAPotential;
model.Potential.Parameter.CutOffRadius = 2^(1/6);
% initialize the integrator
integrator = VVASLLOD;
% initialize the thermostat
thermostat = IsokineticThermostat;
% set the integrator step size
dt = 0.01;

simulation = Simulation('dummy_name') ...
    .setup(model, integrator, thermostat, dt) ... 
    .track(Average(Pressure)) ...
    .track(Average(Energy).plot) ...
    .track(Value(Position).plot) ...
    .track(History(Temperature).skip(0.4)) ...
    .until(TimeLimit(10)) ...
    .equillibrate() ...
    .until(StepLimit(10^5)) ...
    .run(); 