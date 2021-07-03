classdef Average < Tracker
    properties
        Data
    end
    methods
        function initialize(this, simulation)
            this.initialize@Tracker(simulation);
            this.Data.Sum = zeros(size(this.Measurable.measure(simulation)));
            this.Data.Count = 0;
        end
        function v = getValue(this)
            v = this.Measurable.format(this.Data.Sum) / this.Data.Count;
        end
        function size = getSampleSize(this)
            size = 0;
            if isstruct(this.Data) && isfield(this.Data, "Count")
                size = this.Data.Count;
            end
        end
    end
    methods (Access = protected)
        function onUpdate(this, simulation)
            this.Data.Sum = this.Data.Sum + this.Measurable.measure(simulation);
            this.Data.Count = this.Data.Count + 1;
        end
    end
end

