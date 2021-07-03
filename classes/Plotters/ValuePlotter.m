classdef ValuePlotter < Plotter    
    properties
        X
        Scale
    end
    methods
        function this = ValuePlotter(report, scale, x, varargin)
            this@Plotter(varargin{:});
            this.Scale = scale;
            this.X = x;
        end
        
        function p = createPlot(this, simulation, axes)
            v = this.Tracker.getValue();
            p = plot(axes, this.X, gather(v(1,:)));
            if isequal(this.Scale, 'log')
                set(axes, 'YScale', 'log');
                set(axes, 'XScale', 'log');
            end
        end
        
        function updatePlotData(this, state)
            v = this.Tracker.getValue();
            this.Plot.YData = gather(mean(v,1));
        end
    end
end

