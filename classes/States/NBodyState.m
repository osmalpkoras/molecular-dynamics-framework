classdef NBodyState < IConfiguration
    properties
        q
        p
        t
        step
    end
    properties (Transient)
        f
    end
    
    methods(Static)
        function this = loadobj(loadthis)
            if isstruct(loadthis)
                this = NBodyState;
                this.loadfrom(loadthis);
            else
                this = loadthis;
            end
        end
    end
end

