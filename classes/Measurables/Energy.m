% defines the total energy consisting of the kinetic and potential energy
classdef Energy < Scalar
    methods
        function value = measure(this, simulation)
            s = simulation.State;
            p = simulation.Model.toThermalMomentum(s, s.p);
            if 1 == this.Dimension
                value = p.^2 + simulation.Model.Potential.getEnergy(simulation.Model, s);
            elseif 2 == this.Dimension
                value = sum(sum(p.^2))/2 + simulation.Model.Potential.getEnergy(simulation.Model, s);
            end
        end
        
        function data = format(this, data)
            data = permute(data, [this.Dimension+1 1:this.Dimension]);
        end
        function data = unformat(this, data)
            data = permute(data, [2:(this.Dimension+1) 1]);
        end
    end
end

