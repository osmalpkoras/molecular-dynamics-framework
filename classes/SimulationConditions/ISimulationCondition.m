classdef ISimulationCondition < DeepCopyable
    methods (Abstract)
        % determines whether the condition is met. A simulation should
        % stop, when all conditions are met.
        b = isSatisfied(this, simulation)
        % determines whether there are more conditions, that need to be
        % satisfied
        b = hasRemainingConditions(this)
        % advances to the next condition, but only if there is any
        b = advanceToNextCondition(this);
    end
end

