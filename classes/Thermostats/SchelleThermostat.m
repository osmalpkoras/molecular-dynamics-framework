classdef SchelleThermostat < Thermostat
    properties
        History
        THLength
        HIndex % history index
        RParam % relaxation paramter
    end
    methods
        function this = instantiate(this, simulation)
            this.History = Globals.GpuArrayFunctionWrapper(@zeros, 1, thlength);
            this.RParam = Numeral(lambda);
            this.HIndex = Numeral(0);
            this.THLength = Numeral(0);
        end
        function p = regulate(this, state, p)
            nPart = size(p,2);
            % Isokinetic thermostat for the fluctuating part of the velocity
            
            % Current temperature
            temp = 0.5 * sum(sum(p.^2))/nPart;
            
            % position index in the T-history array
            if this.THLength < length(this.History)
                this.THLength = this.THLength + 1;
                this.HIndex = this.THLength;
            else
                this.HIndex = mod(this.HIndex, this.THLength)+1;
            end
            
            this.History(this.HIndex) = temp;
            
            % Velocity scaling factor with a relaxation param lambda and T-history
            alpha = this.RParam*(1-sqrt(this.Model.Temperature/(sum(this.History)/this.THLength)));
            
            p = p - alpha*p;
        end
    end
end

