classdef PlanarCouetteFlow < NBody
    properties
        vL
        gradU
    end    
    methods
        function this = PlanarCouetteFlow(m)
            this@NBody(2, m);
            this.Parameter = PlanarCouetteFlowParameters;
            this.Domain = PeriodicBox;
        end
        
        function this = instantiate(this, simulation)
            this.Domain.Parameter.Length = sqrt(this.Parameter.N/this.Parameter.Density);
            this.Domain.instantiate(simulation);
            this.Potential.instantiate(simulation);
            simulation.State = PlanarCouetteFlowState;
            s = simulation.State;
            
            side = ceil(sqrt(this.Parameter.N)); % side of perfect square >= N
            h = this.Domain.Parameter.Length/side; % distance between particles   
            [X,Y] = meshgrid(linspace(h/2, this.Domain.Parameter.Length-h/2,side));

            % Assign particle positions
            s.q = [Y(:),X(:)]'; 
            s.q = repmat(s.q(:,1:this.Parameter.N), 1, 1, this.M);
            % Assign velocities
            s.p = Globals.GpuArrayFunctionWrapper(@rand, 2, this.Parameter.N, this.M);
            
            % Set initial momentum to zero
            totV = sum(s.p,2)/this.Parameter.N; % Center of mass pocity
            s.p = s.p - totV; % Fix any center-of-mass drift
            
            % isokinetic thermostat for initial scaling (for faster equillibration)
            t = 0.5 * sum(sum(s.p.^2, 1), 2)/this.Parameter.N;
            pScale = sqrt(this.Parameter.Temperature./t); % pocity scaling factor
            s.p = s.p .* pScale;
            
            this.Domain.updateDistances(this, s);            
            this.Potential.updateForces(this, s);
            
            % switch to total momenta
            s.p = this.toTotalMomentum(s, s.p);
        end
        
        function dq = dq(this, q, p, f)
            dq = p;
            dq(1,:,:) = dq(1,:,:) + this.Parameter.ShearRate * (q(2,:,:) - this.Domain.Parameter.Length/2);
        end
        
        function dp = dp(this, q, p, f)
            dp = f;
            dp(1,:,:) = dp(1,:,:) - this.Parameter.ShearRate * p(2,:,:);
        end
        
        function p = toThermalMomentum(this, state, p)
            % scherprofil abziehen um lokale/thermale Geschwindigkeiten zu erhalten
            p(1,:,:) = p(1,:,:) - this.Parameter.ShearRate * (state.q(2,:,:) - this.Domain.Parameter.Length/2);
        end
        
        function p = toTotalMomentum(this, state, p)
            % scherprofil hinzufuegen um globale Geschwindigkeiten zu erhalten
            p(1,:,:) = p(1,:,:) + this.Parameter.ShearRate * (state.q(2,:,:) - this.Domain.Parameter.Length/2);
        end
        
        function updatePreIteration(this, state)
            this.updatePreIteration@NBody(state);
            state.BoxOffset = mod(state.t * this.Parameter.ShearRate * this.Domain.Parameter.Length, this.Domain.Parameter.Length); % am anfang oder am ende der schleife? vergleich mit originalcode!
        end
        
        function updatePostIteration(this, state)
            this.updatePostIteration@NBody(state);
        end
    end
end

