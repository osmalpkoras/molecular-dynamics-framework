function SimulateOnMogon(varargin)
    %% parsing input parameters
    [SAVEDIR, NAME, MODEL, INTEGRATOR, THERMOSTAT, TRACKERS, dt, CONDITION, MODE, NAMINGCONVENTION, useGpu] = ParseSimulationInputParameters(varargin{:});
    
    %% logging
    fprintf('\n');
    Globals.log("Starting simulation '%s' with dt = %s", NAME, num2str(dt));
    Globals.log("Model: %s", MODEL.getDisplayName());
    for name = MODEL.Parameter.names()
        Globals.log("\t%s = %s", name, num2str(gather(MODEL.Parameter.get(name))));
    end
    Globals.log("Integrator: %s", INTEGRATOR.getDisplayName());
    for name = INTEGRATOR.Parameter.names()
        Globals.log("\t%s = %s", name, num2str(gather(INTEGRATOR.Parameter.get(name))));
    end
    Globals.log("Thermostat: %s", THERMOSTAT.getDisplayName());
    for name = THERMOSTAT.Parameter.names()
        Globals.log("\t%s = %s", name, num2str(gather(THERMOSTAT.Parameter.get(name))));
    end
    Globals.log('Saving to: %s', SAVEDIR);
    Globals.log('Running on GPU :  %s', num2str(useGpu));
    Globals.log('Running in mode:  %s', MODE);
    
    %% setup
    if strcmpi(MODE, "test")
        SAVEDIR = sprintf("%s.test", SAVEDIR);
        if ~isfolder(SAVEDIR); mkdir(SAVEDIR); end
    end
    library = Library(SAVEDIR);
    
    exp = Simulation(NAME) ...
        .setup(MODEL, INTEGRATOR, THERMOSTAT, dt);
    
    for i = 1:length(TRACKERS)
        if isa(TRACKERS{i}, "History")
            TRACKERS{i}.dir(sprintf("%s/Histories", SAVEDIR));
        end
        exp.track(TRACKERS{i});
    end
    
    %% actual running code
    library.tryLockSimulation(exp, NAMINGCONVENTION)
    if library.hasLockedSimulation(exp, NAMINGCONVENTION)
        if strcmpi(MODE, "test")
            Globals.log("(1/4) Testing equillibration");
            exp.until(StepLimit(100)) ...
                .equillibrate();

            Globals.log("(2/4) Testing library saving");
            library.saveSimulation(exp, NAMINGCONVENTION);

            pause("on");
            pause(1);
            Globals.log("(3/4) Testing library loading");
            exp = library.loadSimulation(exp, NAMINGCONVENTION);

            Globals.log("(4/4) Running a test run");
            exp.until(StepLimit(100)) ...
                .run();
            library.saveSimulation(exp, NAMINGCONVENTION);
        else        
            if strcmpi(MODE, "equillibrate")
                if library.hasSimulation(exp, NAMINGCONVENTION)
                    Globals.log("Equillibrated data for simulation with name '%s' already exists. Either delete data or change simulation name.", NAME);
                    return;
                end
                exp.until(CONDITION) ...
                    .equillibrate();
                library.saveSimulation(exp, NAMINGCONVENTION);
            else % else, the simulation has already been generated and we want to continue it with new conditions
                exp = library.loadSimulation(exp, NAMINGCONVENTION);
                if isempty(exp)
                    Globals.log("No equillibrated data found for this simulation with name '%s'. Please run the same simulation with MODE set to 'equillibrate' and a fitting condition as UNTIL.", NAME);
                    return;
                end
                exp.until(CONDITION);
                while exp.Condition.hasRemainingConditions()
                    exp.run();
                    library.saveSimulation(exp, NAMINGCONVENTION);
                    exp.Condition.advanceToNextCondition();
                end
            end
        end
        library.releaseSimulation();
    else
        Globals.log("Failed to lock Simulation '%s', because it's already locked.", NAME);
    end
end

