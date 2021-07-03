classdef DoubleWell < NBody
    methods
        function this = DoubleWell(m)
            this@NBody(1, m);
            this.Domain = RSpace;
            this.Potential = DoubleWellPotential;
            this.Parameter.N = 1;
        end
        function this = instantiate(this, simulation)
            state = NBodyState;
            simulation.State = state;
            
            state.q = Globals.GpuArrayFunctionWrapper(@rand, 1, this.M);
            state.p = Globals.GpuArrayFunctionWrapper(@rand, 1, this.M);                

            t = state.p.^2;
            pScale = sqrt(this.Parameter.Temperature./t);
            state.p = state.p .* pScale;
            
            this.Domain.updateDistances(this, state)
            this.Potential.updateForces(this, state);
        end
        function name = getDisplayName(this)
            if this.M * this.Parameter.N > 1
                name = [this.getName() ' (' num2str(this.Parameter.N * this.M) ' runs in parallel)'];
            else
                name = this.getName();
            end
        end
    end
end

