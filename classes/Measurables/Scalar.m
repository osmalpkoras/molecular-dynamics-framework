% defines a measurable that is a scalar
classdef Scalar < Measurable
    methods
        function plotter = createPlotter(this, simulation)
            plotter = ScalarPlotter();
        end
    end
end

