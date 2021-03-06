Despite the limited language features of MATLAB, I followed object-oriented paradigms to design a simulation framework for molecular dynamics. The framework supports running simulations on CPU as well as GPU. Every mathematical model of a physical system is derived from the `IModel` interface, defining the dynamics and initialization of a physical system, as well as the potential (`IPotential`) and the domain (`IDomain`) optionally including boundary conditions (`IBoundaryConditions`), each derived from their respective interfaces. The models in `classes/Models` serve as a good reference for how to implement a new model.

Running a simulation can be done using a fluent API, as seen below. 
``` matlab
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
```
Here, the `Simulation` class is used to instantiate and setup a new simulation going by the name of `'dummy_name'`, after which configuration of quantity-tracking, visualization and simulation conditions happens. Tracking a quantity amounts to capturing information generated by simulation while visualization allows for live-tracking these quantities and spotting erratic or curious behaviour more easily. Simulations are run as long as the simulation conditions are met.

Below is an example of how to use the library to save and store simulation data, making even huge datasets loadable and processible.
``` matlab
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
```
A library in instantiated using the `Library` class and allows for locking to prevent concurrent write access, which might lead to data corruption. A naming convention allows for fine control of the folder structure, that is built as one runs simulations with different models and/or parameters.

Below is another complimentary example of how to use the fluent API.
``` matlab
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
```