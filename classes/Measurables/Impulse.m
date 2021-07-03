classdef Impulse < Measurable
    methods
        function value = measure(this, simulation)
            value = simulation.State.p;
        end
        
        function data = format(this, data)
            data = permute(data, [this.Dimension+1 1:this.Dimension]);
        end
        function data = unformat(this, data)
            data = permute(data, [2:(this.Dimension+1) 1]);
        end
        
        function plotter = createPlotter(this, simulation)
            plotter = NooPlotter();
        end
    end
end

