classdef IntegratorWithPostProcessing < IIntegrator    
    properties (Transient)
        f
        fx
        fy
        dx
        dy
    end
    methods
        function StatePostProcessingForMeasurement(this, model, state, thermostat, dt)
            if isa(model, "PlanarCouetteFlow")
                this.f = state.f;  
                this.fx = state.fx;  
                this.fy = state.fy;  
                this.dx = state.dx;  
                this.dy = state.dy;  
                model.Domain.updateDistances(model, state);
                model.Potential.updateForces(model, state);
            end
        end
        
        function UndoStatePostProcessingForMeasurement(this, model, state, thermostat, dt)
            if isa(model, "PlanarCouetteFlow")
                state.f = this.f;  
                state.fx = this.fx;  
                state.fy = this.fy;  
                state.dx = this.dx;  
                state.dy = this.dy;  
            end
        end
    end
end

