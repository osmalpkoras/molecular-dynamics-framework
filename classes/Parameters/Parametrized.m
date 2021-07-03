classdef Parametrized < handle    
    properties
        Parameter Parameters
    end
    
    methods
        function c = isequal(a, b)
            c = isequal(class(a), class(b)) && isequal(a.Parameter, b.Parameter);
        end        
        
        function this = set(this, varargin)
            Parser = Utility.InputParser() ...
                .CaseSensitive(false) ...
                .KeepUnmatched(false);
            mco = metaclass(this.Parameter);
            for property = mco.PropertyList'
                if ~isempty(this.Parameter.(property.Name))
                    Parser.addNumeral(property.Name, this.Parameter.(property.Name));
                else
                    Parser.addNumeral(property.Name);
                end
            end
            
            inputs = Parser.parse(varargin{:});
            for field = fieldnames(inputs)'
                this.Parameter.(field{1}) = inputs.(field{1});
            end
        end        
    end
    
    methods (Abstract)
        this = instantiate(this, simulation, varargin)
    end
end

