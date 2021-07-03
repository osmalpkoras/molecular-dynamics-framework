classdef Options
    methods (Static)
        function b = usingGpuComputation(useG)
            persistent IS_USING_GPU;
            if nargin
                IS_USING_GPU = useG;
                if IS_USING_GPU
                    gpuDevice(1);
                end
            else
                b = IS_USING_GPU;
            end
        end
    end
end

