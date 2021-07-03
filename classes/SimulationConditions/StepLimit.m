classdef StepLimit < ISimulationCondition
    properties
        Steps
        CurrentConditionIndex
    end
    methods
        function this = StepLimit(steps)
            this.Steps = steps;
            this.CurrentConditionIndex = 1;
        end
        function b = isSatisfied(this, simulation)
            b = this.Steps(this.CurrentConditionIndex) <= simulation.ProductionStep;
        end
        function b = hasRemainingConditions(this)
            b = this.CurrentConditionIndex <= length(this.Steps);
        end
        function advanceToNextCondition(this)
            this.CurrentConditionIndex = this.CurrentConditionIndex + 1;
        end
    end
    
end

