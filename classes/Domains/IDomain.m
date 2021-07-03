% defines a simulation space
classdef IDomain  < Parametrized
    properties
        BoundaryConditions
    end    
    methods (Abstract)
        % instantiate the domain
        instantiate(this, simulation)
        % updates the distances on the model and state
        updateDistances(this, model, state);
    end
end

