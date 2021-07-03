classdef PlanarCouetteFlowState < NBodyState    
    properties
        BoxOffset % the current x-offset our simulated box has to the sheared and duplicated box on the above layer
    end
    properties (Transient)        
        fx % 
        fy
        dx % dx(i,j) = y-Entfernung des Koerpers i zum Koerper j
        dy % dy(i,j) = q(i,1) - q(
    end
    methods
        function this = PlanarCouetteFlowState()
            this.BoxOffset = Numeral(0);
        end
    end
end

