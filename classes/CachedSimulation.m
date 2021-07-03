classdef CachedSimulation < Simulation
    properties
        Times
        getPosition
        getImpulse
        Size
        CacheIndex = 1;
    end
    
    methods
        function this = CachedSimulation(t, getposition, getimpulse)
            this.Times = t;
            this.getPosition = getposition;
            this.getImpulse = getimpulse;
            this.Size = length(this.Times);
        end
        
        function savethis = saveobj(this)
            savethis = this.toSimulation();
        end
        
        function simulation = toSimulation(this, name)
            simulation = Simulation(name);
            simulation.Model = this.Model;
            simulation.State = this.State;
            simulation.Integrator = this.Integrator;
            simulation.Thermostat = this.Thermostat;
            simulation.Trackers = this.Trackers;
            simulation.dt = this.dt;
            simulation.TotalRuntime = this.TotalRuntime;
            simulation.Production = this.Production;
            simulation.Condition = this.Condition;
        end
        
        function this = equillibrate(this)
        end
        
        function b = areConditionsSatisfied(this)
            b = this.CacheIndex >= this.Size || (~this.Condition.hasRemainingConditions() || this.Condition.isSatisfied(this));
        end
        
        function startTrackers(this)
            for Tracker = this.Trackers
                Tracker{1}.initialize(this);
                Tracker{1}.tick(this);
            end
        end
        
        function iterate(this, dt)
            this.State.step = this.Times(this.CacheIndex) / dt;
            this.State.q = Numeral(permute(this.getPosition(this.CacheIndex), [3 4 2 1]));
            this.State.p = Numeral(permute(this.getImpulse(this.CacheIndex), [3 4 2 1]));
            this.Model.Domain.updateDistances(this.Model, this.State);
            this.Model.Potential.updateForces(this.Model, this.State);
            this.State.t = this.Times(this.CacheIndex);
            this.CacheIndex = this.CacheIndex + 1;
        end        
    end
end

