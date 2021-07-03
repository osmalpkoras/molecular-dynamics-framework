% helper class to handle struct
classdef Struct    
    methods (Static)        
        function b = isequal(s, t)
            flds = fields(s);
            b = length(flds) == length(fields(t)) && length(intersect(flds, fields(t))) == length(flds);
            if ~b
                return;
            end
            
            for i = 1:length(flds)
                if isstruct(s.(flds{i})) && isstruct(t.(flds{i}))
                    b = Utility.Struct.isequal(s.(flds{i}), t.(flds{i}));
                    if ~b
                        return; 
                    end
                else
                    b = isequal(s.(flds{i}), t.(flds{i}));
                    if ~b
                        return; 
                    end
                end
            end
        end
        
        % true if s is partially contained in t
        function b = match(s, t)
            flds = fields(s);
            b = length(intersect(flds, fields(t))) == length(flds); % what to do with empty fields?
            if ~b
                return;
            end
            
            for i = 1:length(flds)
                % if the property is empty, it might as well not exist, so
                % we skip its equality
                if isa(s.(flds{i}), "gpuArray")
                    disp("as");
                end
                if isempty(s.(flds{i})); continue; end
                
                if isstruct(s.(flds{i})) && isstruct(t.(flds{i}))
                    b = Utility.Struct.match(s.(flds{i}), t.(flds{i}));
                    if ~b
                        return; 
                    end
                else
                    b = isequal(s.(flds{i}), t.(flds{i}));
                    if ~b
                        return;
                    end
                end
            end
        end
    end
end

