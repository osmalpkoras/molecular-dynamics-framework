% defines the 2d vector space without any boundary conditions
classdef RSpace < IDomain
    methods
        function this = RSpace()
            this.BoundaryConditions = NoopBoundaryConditions();
        end
        
        function this = instantiate(this, simulation)
        end
        
        function updateDistances(this, model, state)
            % Pairwise distance between particles in x and y
            switch model.D
                case 1
                case 2
                    state.dx = state.q(1,:,:) - permute(state.q(1,:,:), [2 1 3]);
                    state.dy = state.q(2,:,:) - permute(state.q(2,:,:), [2 1 3]);     
            end
        end
    end
end

