% boundary conditions for a simulation space
classdef IBoundaryConditions  < Parametrized
    properties (Hidden)
        onBoundaryConditionsAppliedHandler = {} % a callback to be called with the changes, that have been applied
    end
    methods
        % add another callback to be called when the boundary conditions have been applied
        function onBoundaryConditionsApplied(this, handler)
            this.onBoundaryConditionsAppliedHandler = [this.onBoundaryConditionsAppliedHandler {handler}];
        end
    end
    methods (Abstract)
        % applies the boundary conditions on the model and state
        apply(this, model, state);
    end
end