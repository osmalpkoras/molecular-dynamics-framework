% boundary conditions for a periodic box using peculiar momenta - withou a shear profile
classdef PeriodicLeeEdwardsBoundaryConditions < IBoundaryConditions & DeepCopyable
    methods
        function apply(this, model, state)
            % track the y offset and apply boundary conditions
            yoffsets = floor(state.q(2,:,:) / model.Domain.Parameter.Length);
            state.q(1,:,:) = state.q(1,:,:) - state.BoxOffset * yoffsets;
            state.q(2,:,:) = state.q(2,:,:) - model.Domain.Parameter.Length * yoffsets;
            
            % track the x box offset and apply boundary conditions
            xoffsets = floor(state.q(1,:,:) / model.Domain.Parameter.Length);
            state.q(1,:,:) = state.q(1,:,:) - model.Domain.Parameter.Length * xoffsets;
            
            for i = 1:length(this.onBoundaryConditionsAppliedHandler)
                this.onBoundaryConditionsAppliedHandler{i}(state, xoffsets, yoffsets)
            end
        end
        function this = instantiate(this, simulation)
        end
    end
end

