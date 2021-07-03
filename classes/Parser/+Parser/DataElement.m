classdef DataElement < dynamicprops & matlab.mixin.Copyable
    methods
        function set(this, PropertyName, Value)
            if ~isprop(this, PropertyName)
                property = this.addprop(PropertyName);
                property.NonCopyable = false;
            end
            this.(PropertyName) = Value;
        end
        % returns all data elements for which the predicate (function) is true
        function [newgroup] = filter(this, predicate)
            newgroup = Parser.DataElement.empty();
            for element = this
                if predicate(element)
                    newgroup(end+1) = element;
                end
            end
        end
        
        % sorts all data elements by the value returned by the predicate
        % (function)
        function newelements = sort(this, predicate, varargin)
            for i = length(this):(-1):1
                values(i) = predicate(this(i));
            end
            [sortedValues, indices] = sort(values, varargin{:});
            newelements = this(indices);
        end
        
        % groups all data elements for which the predicate returns the same
        % value
        function [newelementgroups, n] = group(this, predicate)
            newelementgroups = struct("Elements", {}, "Value", {});
            
            for element = this
                doesNewDataGroupExist = false;
                for i = 1:length(newelementgroups)
                    if isequal(predicate(newelementgroups(i).Elements(1)), predicate(element))
                        doesNewDataGroupExist = true;
                        newelementgroups(i).Elements(end+1) = element;
                    end
                end
                
                if ~doesNewDataGroupExist
                    newelementgroups(end+1) = struct("Elements", element, "Value", predicate(element));
                end
            end
            n = length(newelementgroups);
        end
        
        function setKeyValuePair(this, key, value)
            i = this.getKeyIndex(key);
            if i > 0
                this.Values{i} = value;
            else
                this.Keys(end+1) = {key};
                this.Values(end+1) = {value};
            end
        end
        
        function value = getValueByKey(this, key)
            value = [];
            i = this.getKeyIndex(key);
            if i > 0
                value = this.Values{i};
            end
        end
        
        function b = matches(this, other, key)
            b = false;
            ithis = this.getKeyIndex(key);
            iother = other.getKeyIndex(key);
            if ithis > 0 && iother > 0
                b = isequal(this.Values{ithis}, other.Values{iother});
            end
        end
        
        function b = hasKeyValuePair(this, key, value)
            i = this.getKeyIndex(key);
            if i > 0
                b = isequal(this.Values{i}, value);
                return;
            end
            b = false;
        end
        
        function i = getKeyIndex(this, key)
            for i = 1:length(this.Keys)
                if isequal(this.Keys{i}, key)
                    return;
                end
            end
            i = 0;
        end
    end
end

