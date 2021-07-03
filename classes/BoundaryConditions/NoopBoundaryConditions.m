% boundary conditions that do nothing
classdef NoopBoundaryConditions < IBoundaryConditions
    methods
        function apply(this, model)
        end
        function this = instantiate(this, simulation)
        end
    end
end

