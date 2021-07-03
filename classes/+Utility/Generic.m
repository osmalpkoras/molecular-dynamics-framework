% very generic helper functions
classdef Generic
    methods (Static)
        function n = num2str(varargin)
            n = strrep(num2str(varargin{:}), ".", ",");
        end
        function b = matchesAny(value, varargin)
            for i = 1:length(varargin)
                b = isequal(value, varargin{i});
                if b; return; end
            end
        end
        
        function b = containsAny(array, varargin)
            b = false;
            for i = 1:length(array)
                for j = 1:length(varargin)
                    b = isequal(array(i), varargin{j});
                    if b
                        return;
                    end
                end
            end
        end
        
        function value = select(value, varargin)
            keys = varargin(1:2:end);
            values = varargin(2:2:end);
            for i = 1:length(keys)
                if isequal(value, keys{i})
                    value = values{i};
                    return;
                end
            end
        end
        
        function detectNan(value, varargin)
            if any(isnan(value))
                fprintf("NAN Values detected.\n");
                if ~isempty(varargin)
                    fprintf(varargin{:});
                    fprintf("\n");
                end
            end
        end
        
        function v = selectClosestTo(value, values)
            distances = abs(values - value);
            [M, I] = min(distances(:));
            v = values(I);
        end
    end
end

