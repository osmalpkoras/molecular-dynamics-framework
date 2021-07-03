classdef IModel < Parametrized & Persistent & DeepCopyable
    properties
        Domain
        Potential
        D % dimension in space
        M % number of parallel simulations
    end
    methods
        function this = IModel(d, m)
            this.D = Numeral(max(1, d));
            this.M = Numeral(max(1, m));
        end
        % instantiates the whole model and simulation state
        instantiate(this, simulation)
        % right hand side of motion of equation for positions
        q = dq(this, q, p, f);
        % right hand side of motion of equation for impulses
        p = dp(this, q, p, f);
        % takes the state and impulses p and returns thermal momentum of p
        p = toThermalMomentum(this, state, p)
        % takes the state and impulses p and returns total momentum of p
        p = toTotalMomentum(this, state, p);        
        % logic to be executed before every iteration with the integrator
        updatePreIteration(this, state);
        % logic to be executed after every iteration with the integrator
        updatePostIteration(this, state);
    end
end

