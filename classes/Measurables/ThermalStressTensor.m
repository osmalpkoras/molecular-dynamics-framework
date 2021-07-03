% calculates the stress tensor using thermal momenta
classdef ThermalStressTensor < Measurable   
    methods
        function value = measure(this, simulation)
            s = simulation.State;
            p = simulation.Model.toThermalMomentum(s, s.p);
            
            value(1,1,:) = sum(p(1,:,:).^2) + 0.5*sum(sum(s.dx .* s.fx));
            value(2,2,:) = sum(p(2,:,:).^2) + 0.5*sum(sum(s.dy .* s.fy));
            
            value(1,2,:) = sum(p(1,:,:).*p(2,:,:));
            value(2,1,:) = value(1,2,:);
            value(1,2,:) = value(1,2,:) + 0.5*sum(sum(s.dx .* s.fy));
            value(2,1,:) = value(2,1,:) + 0.5*sum(sum(s.dy .* s.fx));
            value = value / simulation.Model.Domain.Parameter.Length^2;
            value = -value;
        end
        
        function plotter = createPlotter(this, simulation)
            plotter = NoopPlotter;
        end
        
        function data = format(this, data)
            data = permute(data, [this.Dimension+1 1:this.Dimension]);
        end
        function data = unformat(this, data)
            data = permute(data, [2:(this.Dimension+1) 1]);
        end
    end
end

