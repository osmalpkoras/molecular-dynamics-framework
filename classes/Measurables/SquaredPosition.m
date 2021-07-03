classdef SquaredPosition < Scalar    
    methods                
        function value = measure(this, simulation)
            s = simulation.State;
            value = s.q.^2;
        end
        
        function data = format(this, data)
            data = permute(data, [this.Dimension+1 1:this.Dimension]);
        end
        function data = unformat(this, data)
            data = permute(data, [2:(this.Dimension+1) 1]);
        end
    end
end

