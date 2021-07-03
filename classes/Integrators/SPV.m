% defines the stochastic position verlet method
classdef SPV < IntegratorWithPostProcessing    
    properties
        c
    end
    methods
        function this = instantiate(this, simulation)
            this.c = (1 - exp(- simulation.Thermostat.Parameter.FrictionConstant * simulation.dt)) / simulation.Thermostat.Parameter.FrictionConstant;
        end
        
        function iterate(this, model, state, thermostat, dt)
            s = state; % since state is a handle, no actual copying is done
            
            s.q = s.q + 0.5*dt * model.dq(s.q, s.p, s.f);
            model.Domain.updateDistances(model, s);
            model.Potential.updateForces(model, s);
            thermostat.regulate(state);
            s.p = s.p + this.c * model.dp(s.q, s.p, s.f);
            s.q = s.q + 0.5*dt * model.dq(s.q, s.p, s.f); 
        end
    end
end

