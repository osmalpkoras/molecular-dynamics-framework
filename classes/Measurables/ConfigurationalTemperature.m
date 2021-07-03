classdef ConfigurationalTemperature < Scalar
    methods
        function value = measure(this, simulation)
            s = simulation.State;
            if isa(simulation.Model, "HarmonicOscillator")
                value = (-s.f) .* s.q;
            elseif isa(simulation.Model, "DoubleWell")
                value = (-s.f) .* s.q;
            elseif isa(simulation.Model, "PlanarCouetteFlow")
                invr2 = s.dx.^2 + s.dy.^2;          
                invr2(invr2 >= simulation.Model.Potential.COR_2) = 0;
                ind = invr2 > 0;
                invr2(ind) = 1./invr2(ind);
                first = invr2.^7 - 0.5 * invr2.^4;
                second = 14 * invr2.^8 - 4 * invr2.^5;
                factx = 48*(first - s.dx.^2 .* second);
                facty = 48*(first - s.dy.^2 .* second);
                value = sum(sum(s.f.^2)) ./ -(sum(sum(factx + facty)));
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

