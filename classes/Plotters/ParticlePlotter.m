classdef ParticlePlotter < Plotter
    properties
        X
        Y
        g
    end
    methods
        function this = ParticlePlotter(varargin)
            this@Plotter(varargin{:});
        end
        
        function p = createPlot(this, simulation, axes)
            s = simulation.State;
            %ind = 1:this.Report.Simulation.Model.N;
            %redInd = [207     2];
            p = scatter(axes, s.q(1, 1, :), s.q(1, 2, :), 'filled');
            %hold on;
            %p2 = scatter(axes, this.state.q(1, redInd, 1), this.state.q(2, redInd, 1), 'filled', 'g');
            %hold off;
            if this.Tracker.Measurable.unfoldPositions
                this.X.min = -10;
                this.X.max = simulation.Model.Domain.Parameter.Length + 10;
                this.Y.min = -10;
                this.Y.max = simulation.Model.Domain.Parameter.Length + 10;
                axes.XLim = gather([this.X.min this.X.max]);
                axes.YLim = gather([this.Y.min this.Y.max]);
            end
            this.g = max(1, simulation.Model.Domain.Parameter.Length * ceil(simulation.Model.Parameter.ShearRate * 10));
            %p = {p1 p2};
        end
        
        function updatePlotData(this, state)
            %q = this.state.q;
            %this.Report.Simulation.Model.applyBoundaryConditions(this.state);
            %redInd = [207     2];
                data = this.Tracker.getValue();
                if isa(this.Tracker, 'History')
                    this.Plot.XData = gather(data(end, 1, 1, :));
                    this.Plot.YData = gather(data(end, 1, 2, :));
                else
                    this.Plot.XData = gather(data(1, 1, :));
                    this.Plot.YData = gather(data(1, 2, :));
                end
%                 if this.Tracker.Measurable.unfoldPositions
%                     this.X.min = floor(min([this.X.min data(1, :, 1)]) / this.g) * this.g;
%                     this.X.max = ceil(max([this.X.max data(1, :, 1)]) / this.g) * this.g;
%                     this.Y.min = floor(min([this.Y.min data(2, :, 1)]) / this.g) * this.g;
%                     this.Y.max = ceil(max([this.Y.max data(2, :, 1)]) / this.g) * this.g;
%                     this.Axes.XLim = [this.X.min this.X.max];
%                     this.Axes.YLim = [this.Y.min this.Y.max];
%                 end
                
%                 this.Plot{2}.XData = gather(this.state.q(1, redInd, 1));
%                 this.Plot{2}.YData = gather(this.state.q(2, redInd, 1));
            %this.state.q = q;
        end
    end
end

