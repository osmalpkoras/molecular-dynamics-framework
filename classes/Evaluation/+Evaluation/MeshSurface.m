classdef MeshSurface < Evaluation.PlotData
    properties
        X
        Y
        Z
    end
    methods
        function setData(this, x, y, z)
            this.X = x;
            this.Y = y;
            this.Z = z;
        end
    end
end

