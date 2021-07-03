classdef LennardJonesPotential < IPotential
    methods        
        function this = instantiate(this, simulation)
        end
        
        function updateForces(this, model, state)
            fFact =  state.dx.^2 + state.dy.^2;            
            ind = fFact > 0;
            fFact(ind) = 1./fFact(ind);
            fFact(ind) = 48 * (fFact(ind).^4) .* (fFact(ind).^3 - 0.5);            
            
            % x- and y-components of the force vectors
            state.fx = state.dx.*fFact;
            state.fy = state.dy.*fFact;
            state.f = [sum(state.fx); sum(state.fy)];
        end
        
        function E = getEnergy(this, model, state)
            radius =  state.dx.^2 + state.dy.^2;
            ind = radius > 0;
            radius(ind) = 1./(radius(ind).^3);            
            E = sum(sum(4 * radius .*(radius - 1)));
        end
    end
end

