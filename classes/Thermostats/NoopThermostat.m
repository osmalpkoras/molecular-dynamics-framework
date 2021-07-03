% a no operation thermostat - it does nothing. 
% this is to be used with simulations that require no thermostat
classdef NoopThermostat < IThermostat
    methods
        function instantiate(this, simulation)
        end
        function regulate(this, state)
        end
    end
end

