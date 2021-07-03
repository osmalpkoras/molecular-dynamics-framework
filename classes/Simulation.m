classdef Simulation < handle
    properties
        Model 
        State 
        Integrator 
        Thermostat
        Trackers
        dt % time step size
        TotalRuntime = 0 % run time accumulated over the entire run (sums up)
        Name = ""
        Production = struct("StartTime", 0, "StartStep", 0);
    end
    properties (Transient)
        Condition
    end
    
    methods        
        function this = Simulation(name)
            if nargin > 0; this.Name = name; end
            this.Production.StartTime = 0;
            this.Production.StartStep = 0;
        end
        
        function this = run(this)
            Plotter.nextFigureNumber(1);
            if Options.usingGpuComputation
                Debug.log('Simulation is running on GPU...');
            else
                Debug.log('Simulation is running on CPU...');
            end            
             
            this.initialize();
            if this.ProductionTime == 0
                this.startTrackers();
            end
            
            tic
            while ~this.areConditionsSatisfied()
                this.iterate(this.dt);
                
                % this post processing allows the integrator to update
                % information, that is required solely for measuring
                % physical quantities. it must be undone below, in order to
                % not interfere with the actual iteration step.
                % by default, the post processing does nothing. For
                % integrators like ABOBA, this is not the case.
                for Tracker = this.Trackers
                    Tracker{1}.tick(this);
                    if Tracker{1}.needsUpdate(this)
                        this.Integrator.StatePostProcessingForMeasurement(this.Model, this.State, this.Thermostat, this.dt);
                        Tracker{1}.update(this);
                        this.Integrator.UndoStatePostProcessingForMeasurement(this.Model, this.State, this.Thermostat, this.dt);
                    end
                end
            end            
            time = toc;
            this.TotalRuntime = this.TotalRuntime + time;
            
            Debug.log('Simulation finished with %.2f seconds (total time: %.2f seconds)', round(time, 2), round(this.TotalRuntime, 2));
        end
        
        function b = areConditionsSatisfied(this)
            b = ~this.Condition.hasRemainingConditions() || this.Condition.isSatisfied(this);
        end
        
        function this = track(this, tracker)
            this.Trackers{length(this.Trackers) + 1} = copy(tracker);
        end
        
        function this = until(this, condition)
            this.Condition = copy(condition);
            if ~isempty(this.State)
               while this.Condition.hasRemainingConditions() && this.Condition.isSatisfied(this)
                   this.Condition.advanceToNextCondition();
               end
            end
        end
        
        function this = equillibrate(this)
            if this.ProductionTime > 0; return; end
            
            if Options.usingGpuComputation
                Debug.log('Simulation equillibration is running on GPU...');
            else
                Debug.log('Simulation equillibration is running on CPU...');
            end            
             
            this.initialize();
            
            while this.Condition.hasRemainingConditions() && ~this.Condition.isSatisfied(this)
                this.iterate(this.dt);
            end
            
            this.Production.StartTime = this.State.t;
            this.Production.StartStep = this.State.step;
        end
        
        function t = ProductionTime(this)
            if isempty(this.State); t = 0; return; end
            t = this.State.t - this.Production.StartTime;
        end
        
        function step = ProductionStep(this)
            step = this.State.step - this.Production.StartStep;
        end
        
        function this = setup(this, model, integrator, thermostat, dt)            
            this.Model = copy(model);
            this.Integrator = copy(integrator);
            this.Thermostat = copy(thermostat);
            this.dt = dt;
        end
        
        function iterate(this, dt)
            this.State.step = this.State.step + 1;            
            this.Model.updatePreIteration(this.State);
            
            this.State.p = this.Model.toThermalMomentum(this.State, this.State.p);
            % update q, p and other parameters
            this.Integrator.iterate(this.Model, this.State, this.Thermostat, dt);
            this.State.p = this.Model.toTotalMomentum(this.State, this.State.p);
            
            this.Model.updatePostIteration(this.State);            
            this.State.t = this.State.step * dt;
        end
        
        function initialize(this)            
            if isempty(this.State)
                this.Model.instantiate(this);
                this.State.t = Numeral(0);
                this.State.step = Numeral(0);
                this.Integrator.instantiate(this);
                this.Thermostat.instantiate(this);
            end
        end
        
        function startTrackers(this)
            for Tracker = this.Trackers
                Tracker{1}.initialize(this);
                Tracker{1}.tick(this);
                if Tracker{1}.needsUpdate(this)
                    Tracker{1}.update(this);
                end
            end
        end
    end
    
    methods (Static)       
        function this = loadobj(loadthis)
            this = loadthis;
            % call necessary functions to recalculate values of transient
            % variables of the state (like f, fx, fy, dx, dy...)
            this.Model.Domain.updateDistances(this.Model, this.State);
            this.Model.Potential.updateForces(this.Model, this.State);
        end 
    end
end

