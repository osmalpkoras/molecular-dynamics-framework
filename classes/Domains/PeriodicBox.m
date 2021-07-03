% defines a periodic box with periodic lee edwards boundary conditions
classdef PeriodicBox < IDomain
    methods
        function this = PeriodicBox()
            this.BoundaryConditions = PeriodicLeeEdwardsBoundaryConditions();
            this.Parameter = PeriodicBoxParameters;
        end
        
        function this = instantiate(this, simulation)
            this.BoundaryConditions.instantiate(simulation);
        end
        
        function updateDistances(this, model, state)
            this.BoundaryConditions.apply(model, state);
            state.dx = state.q(1,:,:) - permute(state.q(1,:,:), [2 1 3]);
            state.dy = state.q(2,:,:) - permute(state.q(2,:,:), [2 1 3]);  
            % y~=L
            ind = state.dy > this.Parameter.Length/2;
            state.dx(ind) = state.dx(ind) - state.BoxOffset;
            state.dy(ind) = state.dy(ind) - this.Parameter.Length;
            
            % y~=0
            ind = state.dy < -this.Parameter.Length/2;
            state.dx(ind) = state.dx(ind) + state.BoxOffset;
            state.dy(ind) = state.dy(ind) + this.Parameter.Length;
            
            state.dx = mod(state.dx , this.Parameter.Length);
            ind = state.dx > this.Parameter.Length/2;
            state.dx(ind) = state.dx(ind) - this.Parameter.Length; % periodic BC remain unchanged
            ind = state.dx < -this.Parameter.Length/2;
            if sum(ind, 'all') > 0
                disp("hello");
            end
        end
    end
end

