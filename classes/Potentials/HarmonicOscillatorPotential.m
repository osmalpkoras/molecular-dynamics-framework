classdef HarmonicOscillatorPotential < IPotential
    methods
        function this = instantiate(this, simulation)
        end
        
        function this = HarmonicOscillatorPotential()
            this.Parameter = HarmonicOscillatorPotentialParameters;
        end
        
        function updateForces(this, model, state)
            state.f = -this.Parameter.SpringRate * state.q;
        end
        
        function E = getEnergy(this, model, state)
            E = this.Parameter.SpringRate * state.q.^2 / 2;
        end
    end
end

