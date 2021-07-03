classdef ABOBAalternate < IntegratorWithPostProcessing
    methods
        function iterate(this, model, state, thermostat, dt)
            s = state;
            
            s.q = s.q + 0.5*dt * model.dq(s.q, s.p, s.f);   
            model.Domain.updateDistances(model, s);
            model.Potential.updateForces(model, s);
            s.p = s.p + 0.5*dt * model.dp(s.q, s.p, s.f);
            
            thermostat.regulate(state);
            
            s.p = s.p + 0.5*dt * model.dp(s.q, s.p, s.f);
            s.q = s.q + 0.5*dt * model.dq(s.q, s.p, s.f);

        end
    end
end

