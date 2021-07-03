classdef PlotData < handle & matlab.mixin.Heterogeneous 
    properties
        ShowInLegend = true
        Data
        Properties = struct();
    end
    methods        
        function this = OnPostProcessingData(this)
        end
    end
end



