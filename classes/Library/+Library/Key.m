classdef Key    
    methods (Static)        
        function b = match(this, other)
            b = Utility.Struct.match(this, other);
        end
        
        function b = isequal(this, other)
            b = Utility.Struct.isequal(this, other);
        end
        
        function str = replace(convention, key)
            fields = extractBetween(convention, "{", "}");
            fields = arrayfun(@(str) sprintf("num2str(key.%s)", str), fields);
            fields = join(fields, ", ");
            convention = eraseBetween(convention, "{", "}");
            convention = replace(convention, "{}", "%s");
            str = eval(sprintf("sprintf(convention, %s)", fields));
        end
        
        function key = from(obj)
            key = struct();
            if isa(obj, 'Parametrized')
                key.Class = class(obj);
                mco = metaclass(obj.Parameter);
                for property = mco.PropertyList'
                    if ~isempty(obj.Parameter.(property.Name))
                        key.(property.Name) = gather(obj.Parameter.(property.Name));
                    end
                end
                mco = metaclass(obj);
                for property = mco.PropertyList'
                    if isa(obj.(property.Name), 'Parametrized')
                        key.(property.Name) = Library.Key.from(obj.(property.Name));
                    end
                end
            elseif isa(obj, 'Simulation')
                key.Model = Library.Key.from(obj.Model);
                key.Integrator = Library.Key.from(obj.Integrator);
                key.Thermostat = Library.Key.from(obj.Thermostat);
                key.dt = gather(obj.dt);
                % we do not add the tracker to the keys here, as it does
                % not have an influence on the simulation itself.
            elseif isa(obj, 'Tracker')
                key.Class = class(obj);
                key.Interval.Start = gather(obj.Interval.Start);
                key.Interval.End = gather(obj.Interval.End);
                key.Interval.Gap = gather(obj.Interval.Gap);
                key.Measurable = class(obj.Measurable);
            else
                if isa(obj, "gpuArray")
                    key = gather(obj);
                else
                    key = obj;
                end
                %error("The library does not support keys of class %s.", class(obj));
            end
        end
    end
end

