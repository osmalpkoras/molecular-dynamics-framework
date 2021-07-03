classdef Line < Evaluation.PlotData
    properties
        X
        Y
    end
    
    methods
        function addPoint(this, x, y)
            this.X = [this.X x];
            this.Y = [this.Y y];
        end
        function addData(this,x, values)
            for i = 1:size(this.Data,2)
                if this.Data{1,i} == x
                    this.Data{2,i} = [this.Data{2,i}; values];
                    return;
                end
            end
            newSize = size(this.Data,2)+1;
            this.Data{1, newSize} = x;
            this.Data{2, newSize} = values;
        end
        function OnPostProcessingData(this)
            [x, ind] = sort(this.X);
            this.X = x;
            this.Y = this.Y(ind);
        end
    end
end

