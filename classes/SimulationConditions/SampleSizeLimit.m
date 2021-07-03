classdef SampleSizeLimit < ISimulationCondition
    properties
        SampleSizes
        CurrentConditionIndex
    end
    methods
        function this = SampleSizeLimit(samplesizes)
            this.SampleSizes = samplesizes;
            this.CurrentConditionIndex = 1;
        end
        function b = isSatisfied(this, simulation)
            b = true;
            for tracker = simulation.Trackers
                if simulation.State.t < tracker{1}.Interval.End  ...
                        && (isa(tracker{1}, "Average") || isa(tracker{1}, "History")) ...
                        && tracker{1}.getSampleSize() < this.SampleSizes(this.CurrentConditionIndex)
                    b = false;
                    return;
                end
            end
        end
        function b = hasRemainingConditions(this)
            b = this.CurrentConditionIndex <= length(this.SampleSizes);
        end
        function advanceToNextCondition(this)
            this.CurrentConditionIndex = this.CurrentConditionIndex + 1;
        end
    end
    
end

