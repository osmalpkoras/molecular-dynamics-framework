classdef ParticlePlotter1D < Plotter
    methods
        function this = ParticlePlotter1D(varargin)
            this@Plotter(varargin{:});
        end
        function p = createPlot(this, simulation, axes)
            p = scatter(axes, [simulation.State.q(1)], [0], 'filled');
            xlim(axes, [-5, 5]);
            ylim(axes, [-1, 1]);
        end
        
        function updatePlotData(this, simulation)
            this.Plot.XData = [simulation.State.q(1)];
        end
    end
end

