classdef Value < Tracker
    properties (Hidden)
        Data
    end
    methods        
        function v = getValue(this)
            v = this.Measurable.format(this.Data);
        end
    end
    
    methods (Access = protected)
        function onUpdate(this, simulation)
            this.Data = this.Measurable.measure(simulation);
        end
    end
end

