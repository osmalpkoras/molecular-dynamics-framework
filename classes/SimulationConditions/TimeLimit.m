classdef TimeLimit < ISimulationCondition
    properties
        Times
        CurrentConditionIndex
    end
    methods
        function this = TimeLimit(times)
            this.Times = times;
            this.CurrentConditionIndex = 1;
        end
        function b = isSatisfied(this, simulation)
            b = this.Times(this.CurrentConditionIndex) <= simulation.ProductionTime;
        end
        function b = hasRemainingConditions(this)
            b = this.CurrentConditionIndex <= length(this.Times);
        end
        function advanceToNextCondition(this)
            this.CurrentConditionIndex = this.CurrentConditionIndex + 1;
        end
    end
    
end

