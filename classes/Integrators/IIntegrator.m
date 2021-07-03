classdef IIntegrator < DeepCopyable &  Parametrized
    methods
        % instantiates the integrator and possible parameters
        function instantiate(this, simulation)
        end
        function name = getName(this)
            name = class(this);
        end
        function name = getDisplayName(this)
            name = this.getName();
        end
        function StatePostProcessingForMeasurement(this, model, state, thermostat, dt)
        end
        function UndoStatePostProcessingForMeasurement(this, model, state, thermostat, dt)
        end
    end
    methods (Abstract)
        % executes an iteration of this integrator
        iterate(this, model, state, thermostat, dt)
    end
end

