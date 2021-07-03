% makes a class persistent, handling numerals in a way, that allows loading
% and saving of an object for GPU and CPU
classdef Persistent < handle    
    methods (Static)
        function this = loadobj(loadthis)
            this = loadthis;
            mco = metaclass(this);
            for property = mco.PropertyList'
                if isnumeric(this.(property.Name)) || islogical(this.(property.Name))
                    this.(property.Name) = Numeral(this.(property.Name));
                end
            end
        end
    end
    
    methods
        function savethis = saveobj(this)
            savethis = this;
            mco = metaclass(savethis);
            for property = mco.PropertyList'
                if isnumeric(savethis.(property.Name)) || islogical(savethis.(property.Name))
                    savethis.(property.Name) = gather(savethis.(property.Name));
                end
            end
        end
    end
end

