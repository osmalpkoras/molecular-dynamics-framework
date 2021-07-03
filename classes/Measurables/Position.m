% measures the position, optionally, it can unfold the positions needed for MSD
classdef Position < Measurable
    properties
        unfoldPositions = false
        
        shearVelocity
        xBoxOffsets
        LastTravelledInstant
        
        qxBoxOffset
        qyBoxOffset
        BoxTravel
        currentBoxTravel
        LastLayerChangedTimes
    end    
    methods        
        function this = initialize(this, tracker, simulation)
            this.initialize@Measurable(tracker, simulation);
            if this.unfoldPositions
                % setup anything needed to unfold positions
                simulation.Model.Domain.BoundaryConditions.onBoundaryConditionsApplied(@this.onBoundaryConditionsApplied);
                this.shearVelocity = simulation.Model.Parameter.ShearRate * simulation.Model.Domain.Parameter.Length;
                
                this.xBoxOffsets = simulation.State.q;
                this.xBoxOffsets(:) = 0;
                this.LastTravelledInstant = 0;
                
                this.qxBoxOffset = simulation.State.q(1,:,:);
                this.qxBoxOffset(:) = 0;
                this.qyBoxOffset = this.qxBoxOffset;
                this.BoxTravel = this.qxBoxOffset;
                this.currentBoxTravel = this.qxBoxOffset;
                this.LastLayerChangedTimes = this.qxBoxOffset;
            end
        end
        
        function value = measure(this, simulation)
            s = simulation.State;
            % unfold the positions using the changes we tracked
            if this.unfoldPositions
                value = s.q + [this.qxBoxOffset; this.qyBoxOffset] * simulation.Model.Domain.Parameter.Length + this.xBoxOffsets;
                value(1,:,:) = value(1,:,:) + this.BoxTravel + this.currentBoxTravel;
            else
                value = s.q;
            end
        end
        
        function data = format(this, data)
            data = permute(data, [this.Dimension+1 1:this.Dimension]);
        end
        function data = unformat(this, data)
            data = permute(data, [2:(this.Dimension+1) 1]);
        end
        
        function plotter = createPlotter(this, simulation)
            if 1 == simulation.Model.D
                plotter = ParticlePlotter1D();
            elseif 2 == simulation.Model.D
                plotter = ParticlePlotter();
            else
                plotter = NooPlotter();
            end
        end
        % when boundary conditions are applied, we need to track the changes, so we can calculate the (unfolded) global positions
        function onBoundaryConditionsApplied(this, state, xoffsets, yoffsets)
            layerChanged = yoffsets ~= 0;
            this.BoxTravel(layerChanged) = this.BoxTravel(layerChanged) + this.shearVelocity * (state.t - this.LastLayerChangedTimes(layerChanged)) .* this.qyBoxOffset(layerChanged);
            this.currentBoxTravel =  this.currentBoxTravel + this.shearVelocity * (state.t - this.LastTravelledInstant) * this.qyBoxOffset;
            this.currentBoxTravel(layerChanged) = 0;
            this.LastTravelledInstant = state.t;
            this.LastLayerChangedTimes(layerChanged) = state.t;
            this.xBoxOffsets(1,:,:) = this.xBoxOffsets(1,:,:) + state.BoxOffset * yoffsets;
            this.qxBoxOffset = this.qxBoxOffset + xoffsets;
            this.qyBoxOffset = this.qyBoxOffset + yoffsets;
        end
        
        function this = unfold(this)
            this.unfoldPositions = true;
        end
    end
end

