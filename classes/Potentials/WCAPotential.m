classdef WCAPotential < IPotential
    properties
        COR_2
        ECO % energy cut off
        FCO % force cut off
    end
        
    methods
        function this = WCAPotential()
            this@IPotential()
            this.Parameter = WCAPotentialParameters;
        end
        
        function this = instantiate(this, simulation)
            this.COR_2 = this.Parameter.CutOffRadius^2;
            invCOR_2 = 1/this.COR_2;
            this.FCO = (invCOR_2^4) .* (invCOR_2^3 - 0.5);
            
            invCOR_6 = 1/(this.COR_2^3);
            this.ECO = 4 * invCOR_6 * (invCOR_6 - 1);
        end
        
        function updateForces(this, model, state)
            fFact =  state.dx.^2 + state.dy.^2;            
            fFact(fFact >= this.COR_2) = 0;
            ind = fFact > 0;
            fFact(ind) = 1./fFact(ind);
            fFact(ind) = (fFact(ind).^4) .* (fFact(ind).^3 - 0.5);
            fFact(ind) = 48 * (fFact(ind) - this.FCO);
            
            % x- and y-components of the force vectors
            state.fx = state.dx.*fFact;
            state.fy = state.dy.*fFact;
            state.f = [sum(state.fx); sum(state.fy)];
        end
        
        function E = getEnergy(this, model, state)            
            r2 =  state.dx.^2 + state.dy.^2;
            r2(r2 >= this.COR_2) = 0;
            ind = r2 > 0;
            r2(ind) = 1./(r2(ind).^3);
            E = 4 * r2 .*(r2 - 1);
            E(ind) = E(ind) - this.ECO;
            E = sum(sum(E));
        end
    end
end

