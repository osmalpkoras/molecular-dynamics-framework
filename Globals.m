classdef Globals   
    methods (Static)        
        function b = geq(A, B, precision)
            b = A > B || abs(A-B) < precision;
        end
        
        function log(varargin)
            if Globals.VerbosityLevel >= 1
                t = clock;
                varargin{1} = sprintf('[%02d:%02d] %s\n', t(end-2), t(end-1), varargin{1});
                fprintf(varargin{:});
            end
        end
                
        function level = VerbosityLevel(level)
            persistent VERBOSITY_LEVEL;
            if nargin
                switch level
                    case 'log'
                        level = 1;
                    case 'debug'
                        level = 2;
                    otherwise
                        level = 0;
                end
                VERBOSITY_LEVEL = level;
            else
                level = VERBOSITY_LEVEL;
            end
        end
        
        function Arr = GpuArrayFunctionWrapper(func, varargin)
            if Options.usingGpuComputation
                Arr = func(varargin{:}, 'gpuArray');
            else
                for i = 1:length(varargin)
                    if isnumeric(varargin{i})
                        varargin{i} = gather(varargin{i});
                    end
                end
                Arr = func(varargin{:});
            end
        end
        
        function timestamp = getTimeStamp()
            t = clock;
            timestamp = sprintf('%4d.%02d.%02d_%02d.%02d', t(1:end-1));
        end
        
        function includeSubfolders()
            % Determine where your m-file's folder is.
            folder = fileparts(which(mfilename));
            % Add that folder plus all subfolders to the path.
            addpath(genpath(folder));
        end
                
        function v = logspace(varargin)
            s = varargin{1};
            e = varargin{2};
            varargin = varargin(3:end);
            v = logspace(log10(s), log10(e), varargin{:});
        end
    end
end

