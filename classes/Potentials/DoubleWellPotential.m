classdef DoubleWellPotential < IPotential
    methods
        function this = instantiate(this, simulation)
        end
        
        function this = DoubleWellPotential()
        end
        
        function updateForces(this, model, state)
            state.f = -4 * state.q .* (state.q.^2 - 1) - 1;
        end
        
        function E = getEnergy(this, model, state)
            E = (state.q.^2 - 1).^2 + state.q;
        end
    end
end

