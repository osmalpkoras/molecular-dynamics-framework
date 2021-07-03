classdef NBody < IModel
    properties
        ATS = 1 % atomic time scale
        PTS = 10^(-12) % physical time scale (ps)
    end
    methods
        function this = NBody(d, m)
            this@IModel(d,m);
            this.Parameter = NBodyParameters;
            this.ATS = Numeral(1);
            this.PTS = Numeral(10^(-12));
        end
        function dq = dq(this, q, p, f) 
            dq = p;
        end        
        function dp = dp(this, q, p, f)
            dp = f;
        end
        function updatePreIteration(this, state) end
        function updatePostIteration(this, state) end        
        function p = toThermalMomentum(this, state, p) end
        function p = toTotalMomentum(this, state, p) end
        function name = getName(this)
            name = replace(class(this), 'Model', '');
        end
        function name = getDisplayName(this)
            if this.M > 1
                name = [this.getName() ' (' num2str(this.M) ' runs in parallel)'];
            else
                name = this.getName();
            end
        end
    end
end

