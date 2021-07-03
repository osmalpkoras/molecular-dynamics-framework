classdef Tracker < DeepCopyable
    properties
        Interval
        Measurable
        isPlotterEnabled = false;
    end
    properties (Transient, NonCopyable)
        Plotter
    end
    methods
        function this = Tracker(measurable)
            this.Measurable = measurable;
            this.Interval.Start = 0;
            this.Interval.End = Inf;
            this.Interval.Gap = 0;
            this.Interval.LastTimeUpdated = -Inf;
        end
        % called after every tick if a new measurement is due
        function update(this, simulation)
            this.Interval.LastTimeUpdated = simulation.ProductionTime;
            this.onUpdate(simulation);

            if isempty(this.Plotter)
                if this.isPlotterEnabled
                    this.Plotter = this.Measurable.createPlotter(simulation);
                    this.Plotter.setTracker(this);
                else
                    this.Plotter = NoopPlotter;
                end
            end

            this.Plotter.update(simulation);
        end
        
        % called after initialization and after every iteration
        function tick(this, simulation)
            this.Measurable.onTick(simulation);
            this.onTick(simulation);
        end
        
        % returns true if the tracker needs to make another measurement
        function b = needsUpdate(this, simulation)
            b = simulation.ProductionTime >= this.Interval.Start ...
                && simulation.ProductionTime <= this.Interval.End ...
                && Globals.geq(simulation.ProductionTime - this.Interval.LastTimeUpdated, this.Interval.Gap, simulation.dt / 1000);
        end
        
        function this = initialize(this, simulation)
            this.Measurable.initialize(this, simulation);
        end
        
        % sets the time at which to start the tracking
        function this = from(this, time)
            this.Interval.Start = Numeral(time);
        end
        
        % sets the time at which to stop the tracking
        function this = to(this, time)
            this.Interval.End = Numeral(time);
        end
        
        % sets the gap size between measurements
        function this = skip(this, time)
            this.Interval.Gap = Numeral(time);
        end
        
        function this = plot(this)
            this.isPlotterEnabled = true;
        end
        
        function name = getName(this)
            name = sprintf("%s of %s", class(this), this.Measurable.getName());
        end
        
        function name = getDisplayName(this)
            name = this.getName();
        end
        
        % create the key of this tracker, used to distinct different trackers
        function key = toKey(this)
            key.Class = class(this);
            key.Interval.Start = this.Interval.Start;
            key.Interval.End = this.Interval.End;
            key.Interval.Gap = this.Interval.Gap;
            key.Measurable = class(this.Measurable);
        end 
    end    
    methods (Access = protected)
        % implement this for custom logic that is called when a new measurement is due
        % is called from inside update()
        function onUpdate(this, simulation)
        end
        % implement this for custom logic that is called after every iteration of the integrator
        function onTick(this, simulation)
        end
    end
    methods (Abstract)
        % returns the value of whatever the tracker tracks
        getValue(this);
    end
end

