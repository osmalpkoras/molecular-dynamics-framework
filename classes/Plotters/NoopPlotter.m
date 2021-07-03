classdef NoopPlotter < Plotter
    methods
        function plt = createPlot(this, state, axes)
            plt = [];
        end
        
        function update(this, state)
        end
        
        function updatePlotData(this, state)
        end
    end
end

