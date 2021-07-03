classdef IThermostat < DeepCopyable & Parametrized
    methods
        function name = getName(this)
            name = replace(class(this), 'Thermostat', '');
        end
        function name = getShortName(this)
            name = this.getName();
            name = name(1);
        end
        function name = getDisplayName(this)
            name = this.getName();
        end
    end
    methods (Abstract)
        % instantiates the intregrator and possible parameters
        instantiate(this, simulation)
        % regulates the temperature of a state of a system 
        regulate(this, state)
    end
end

