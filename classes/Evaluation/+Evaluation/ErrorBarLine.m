classdef ErrorBarLine < Evaluation.Line 
    properties
        Err
    end
    methods
        function addPoint(this, x, y, err)
            this.X = [this.X x];
            this.Y = [this.Y y];
            this.Err = [this.Err err];
        end
        function OnPostProcessingData(this)
            [x, ind] = sort(this.X);
            this.X = x;
            this.Y = this.Y(ind);
            this.Err = this.Err(ind);
        end
    end
end

