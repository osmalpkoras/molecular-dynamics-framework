% defines the velocity verlet algorithmus without thermostat
classdef VVA < IIntegrator
    methods   
        function iterate(this, model, state, thermostat, dt)                
            s = state; % since state is a handle, no actual copying is done
            
            s.p = s.p + 0.5*dt * model.dp(s.q, s.p, s.f);
            s.q = s.q + dt * model.dq(s.q, s.p, s.f);
            model.Domain.updateDistances(model, s);
            model.Potential.updateForces(model, s);
            s.p  = s.p + 0.5*dt * model.dp(s.q, s.p, s.f);
        end
    end
end

