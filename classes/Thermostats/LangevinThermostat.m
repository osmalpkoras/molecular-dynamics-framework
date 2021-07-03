classdef LangevinThermostat < IThermostat & Parametrized
    properties
        egdt
        sigma
    end
    methods
        function this = LangevinThermostat()
            this.Parameter = LangevinThermostatParameters;
        end
        function instantiate(this, simulation)
            this.egdt = exp(-this.Parameter.FrictionConstant * simulation.dt);
            this.sigma = sqrt(simulation.Model.Parameter.Temperature *(1-exp(-2*this.Parameter.FrictionConstant*simulation.dt)));
        end
        function regulate(this, state)            
            if Options.usingGpuComputation
                state.p = this.egdt * state.p + this.sigma.* randn(size(state.f), 'gpuArray');
            else
                state.p = this.egdt * state.p + this.sigma.* randn(size(state.f));
            end
        end
    end
end

