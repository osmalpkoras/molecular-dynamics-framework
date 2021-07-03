% calculates the pressure using total momenta
classdef Pressure < Scalar
    methods
        function value = measure(this, simulation)
            s = simulation.State;
            value = (sum(sum(s.p.^2)) + 0.5*sum(sum(s.dx .* s.fx)) + ...
                + 0.5*sum(sum(s.dy .* s.fy))) / 2 / simulation.Model.Domain.Parameter.Length^2;
        end
        
        function data = format(this, data)
            data = permute(data, [this.Dimension+1 1:this.Dimension]);
        end
        function data = unformat(this, data)
            data = permute(data, [2:(this.Dimension+1) 1]);
        end
    end
end

