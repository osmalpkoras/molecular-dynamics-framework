classdef WindowedAverage < Tracker
    properties
        Data
        WindowLength
    end
    methods
        function initialize(this, simulation)
            this.initialize@Tracker(simulation);
            this.Data.WindowSize = gather(ceil(this.WindowLength / simulation.dt));
            datasize = size(this.Measurable.format(this.Measurable.measure(simulation)));
            this.Data.Window = Numeral(NaN([datasize this.Data.WindowSize]));
            this.Data.WindowIndex = 1;
        end
        
        function v = getValue(this)
            v = nanmean(this.Data.Window, length(size(this.Data.Window)));
        end        
        
        function this = window(this, duration)
            this.WindowLength = duration;
        end
    end
    
    methods (Access = protected)
        function onUpdate(this, simulation)
            this.Data.Window(:, this.Data.WindowIndex) = this.Measurable.format(this.Measurable.measure(simulation));
            this.Data.WindowIndex = this.Data.WindowIndex + 1;
            if this.Data.WindowIndex > this.Data.WindowSize
                this.Data.WindowIndex = 1;
            end
        end
    end
end

