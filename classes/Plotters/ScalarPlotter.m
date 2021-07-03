classdef ScalarPlotter < Plotter
    methods        
        function p = createPlot(this, simulation, axes)
            p = plot(axes, simulation.ProductionTime, this.getValue(simulation));
        end
        
        function updatePlotData(this, simulation)
            this.Plot.XData = [this.Plot.XData gather(simulation.ProductionTime)];
            this.Plot.YData = [this.Plot.YData this.getValue(simulation)];
        end
        
        function value = getValue(this, simulation)
            if isa(this.Tracker, 'History')
                value = gather(mean(this.Tracker.getEndValue(), 2));
            else
                value = gather(mean(this.Tracker.getValue(), 1));
            end
        end
    end
end

