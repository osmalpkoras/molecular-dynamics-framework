classdef IPotential < DeepCopyable  & Parametrized        
    methods
        function name = getName(this)
            name = replace(class(this), 'Potential', '');
        end
    end
    
    methods (Abstract)
        % updates the forces on the model and state
        updateForces(this, model, state)
        % returns the energy of the model according to the state
        E = getEnergy(this, model, state)
    end
end

