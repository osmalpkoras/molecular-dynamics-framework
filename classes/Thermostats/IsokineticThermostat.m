classdef IsokineticThermostat < IThermostat
    properties
        T0
    end
    methods
        function this = instantiate(this, simulation)
            this.T0 = simulation.Model.Parameter.Temperature;
        end
        % p is the peculiar velocity/impuls
        function regulate(this, state)
            state.p = state.p - mean(state.p, 2);
            
            N = size(state.p, 2); % number of cols = number of particles
            % Current temperature
            T = 0.5 * sum(sum(state.p.^2))/N;
            state.p = state.p .* sqrt(this.T0/T);
        end
    end
end

