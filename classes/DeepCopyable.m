% Do not use this class, if you have circular dependencies of copyable
% handles, since it will create an infinite recursion.
classdef DeepCopyable < matlab.mixin.Copyable    
    methods(Access = protected)
        function copiedthis = copyElement(this)
            % first: get builtin shallow copy
            copiedthis = copyElement@matlab.mixin.Copyable(this);
            % next: copy all copyable properties that are not flagged as
            % NonCopyable
            mco = metaclass(this);
            for property = mco.PropertyList'
                if ~property.NonCopyable && isa(this.(property.Name), "matlab.mixin.Copyable")
                    copiedthis.(property.Name) = copy(this.(property.Name));
                end
            end
        end
    end
    
end

