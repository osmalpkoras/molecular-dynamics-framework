% defines the BAAB scheme
classdef BAAB < IIntegrator
    methods     
        function iterate(this, model, state, thermostat, dt)
            s = state; % since state is a handle, no actual copying is done
            
            s.p = s.p + 0.5*dt * model.dp(s.q, s.p, s.f);
            s.q = s.q + 0.5*dt * model.dq(s.q, s.p, s.f);
            s.q = s.q + 0.5*dt * model.dq(s.q, s.p, s.f);
            model.Domain.updateDistances(model, s);
            model.Potential.updateForces(model, s);
            s.p = s.p + 0.5*dt * model.dp(s.q, s.p, s.f);
        end
    end
end

