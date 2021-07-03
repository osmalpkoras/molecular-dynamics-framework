classdef Plotter < handle
    properties
        FrameRate = 10000; % number of draw calls per simulated second
        TimeWindow = 10; % the plotted time window in seconds;
    end
    properties
        FrameNumber = -1; % current frame number
        Delay = 0 % the delay in seconds. the plotting starts only after this many seconds have passed
        hasPlotStarted = 0;
        Tracker
        Plot
        Figure
        Axes
        YLim
    end    
    methods (Static)
        function n = nextFigureNumber(n)
            persistent NEXT_FIGURE_NUMBER;
            if nargin
                NEXT_FIGURE_NUMBER = n;
            else
                n = NEXT_FIGURE_NUMBER;
                NEXT_FIGURE_NUMBER = NEXT_FIGURE_NUMBER + 1;
            end
        end
    end
    
    methods
        
        function this = Plotter(delay)
            if (exist('delay', 'var'))
                this.Delay = delay;
            end
        end
        
        function setTracker(this, tracker)
            this.Tracker = tracker;
        end
        
        function update(this, simulation)
            if ~this.hasPlotStarted
                this.hasPlotStarted = simulation.ProductionTime >= this.Delay;
                
                if this.hasPlotStarted
                    if isempty(this.Figure)
                        this.Figure = figure(Plotter.nextFigureNumber);
                    end
                    clf(this.Figure, 'reset');
                    this.Axes = axes('parent', this.Figure);
                    this.Plot = this.createPlot(simulation, this.Axes);
                    title(this.Axes, this.Tracker.getName());
                end
            end
            
            this.tick();
            if this.hasPlotStarted
                currentFrameNumber = floor((simulation.ProductionTime - this.Delay) * this.FrameRate);
                if currentFrameNumber > this.FrameNumber
                    this.FrameNumber = currentFrameNumber;
                    updatePlotData(this, simulation);
                    %title(this.Axes, num2str(state.step));
                    drawnow;
                end
            end
        end
        
        function tick(this)
        end
        
        function savethis = saveobj(this)
            savethis = this;
            savethis.Figure = [];
            savethis.Axes = [];
            savethis.Plot = [];
            savethis.hasPlotStarted = false;
        end
    end
    
    methods (Abstract)
        p = createPlot(this, state, axes)
        updatePlotData(this, state)
    end
end

