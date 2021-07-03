classdef Parameters    
    methods
        function this = Parameters()
        end
        
        function value = get(this, name)
            value = this.(name);
        end
        
        function nams = names(this)
            mco = metaclass(this);
            nams = string({mco.PropertyList.Name});
        end
        
        function c = subsasgn(a,s, b)
            c = builtin('subsasgn', a, s, Numeral(b));
        end
    end
end

