% helper class to parse varargin input parameters
classdef InputParser < handle
    properties
        Parameters = cell(0);
        isMatchingCaseSensitive = false;
        isKeepingUnmatched = false;
    end
    
    methods
        
        function this = CaseSensitive(this, value)
            this.isMatchingCaseSensitive = Utility.InputParser.parseLogical([], value);
        end
        
        function this = KeepUnmatched(this, value)
            this.isKeepingUnmatched = Utility.InputParser.parseLogical([], value);
        end
        
        function this = addObject(this, name, type, default)
            if exist('default', 'var'); this.addParameter(name, type, @Utility.InputParser.parseObject, default);
            else; this.addParameter(name, type, @Utility.InputParser.parseObject); end
        end
        
        function this = addString(this, name, default)
            if exist('default', 'var'); this.addParameter(name, "string", @Utility.InputParser.parseString, default);
            else; this.addParameter(name, "string", @Utility.InputParser.parseString); end
        end
        
        function this = addNumeral(this, name, default)
            if exist('default', 'var'); this.addParameter(name, "numeral", @Utility.InputParser.parseNumeral, default);
            else; this.addParameter(name, "numeral", @Utility.InputParser.parseNumeral); end
        end
        
        function this = addFloat(this, name, default)
            if exist('default', 'var'); this.addParameter(name, "float", @Utility.InputParser.parseFloat, default);
            else; this.addParameter(name, "float", @Utility.InputParser.parseFloat); end
        end
        
        function this = addInteger(this, name, default)
            if exist('default', 'var'); this.addParameter(name, "integer", @Utility.InputParser.parseInteger, int64(default));
            else; this.addParameter(name, "integer", @Utility.InputParser.parseInteger); end
        end
        
        function this = addLogical(this, name, default)
            if exist('default', 'var'); this.addParameter(name, "logical", @Utility.InputParser.parseLogical, default);
            else; this.addParameter(name, "logical", @Utility.InputParser.parseLogical); end
        end
        
        
        function inputs = parse(this, varargin)
            inputs = struct();
            if this.isMatchingCaseSensitive
                cmp = @strcmp;
            else
                cmp = @strcmpi;
            end
            
            len = length(varargin);
            i = 1;
            while i < len
                matched = false;
                for k = 1:length(this.Parameters)
                    if cmp(this.Parameters{k}.Name, varargin{i})
                        if isfield(inputs, this.Parameters{k}.Name)
                            error("Ambigious input parameter names for parameter: %s", this.Parameters{k}.Name);
                        end
                        eval(sprintf("inputs.%s = this.Parameters{k}.Parser(this.Parameters{k}, varargin{i+1});", this.Parameters{k}.Name));
                        matched = true;
                        break;
                    end
                end
                if ~matched && this.isKeepingUnmatched
                    eval(sprintf("inputs.%s = varargin{i+1};", varargin{i}));
                end
                i = i + 2;
            end
            
            for k = 1:length(this.Parameters)
                if ~isfield(inputs, this.Parameters{k}.Name)
                    if ~isfield(this.Parameters{k}, "Default")
                        error("Missing required input parameter: %s", this.Parameters{k}.Name);
                    else
                        eval(sprintf("inputs.%s = this.Parameters{k}.Default;", this.Parameters{k}.Name ));
                    end
                end
            end
        end
    end
    
    methods (Access = private)
        function addParameter(this, name, type, parser, default)
            param.Name = name;
            if exist('default', 'var'); param.Default = default; end
            param.Type = type;
            param.Parser = parser;
            this.Parameters{length(this.Parameters)+1} = param;
        end
    end
    
    methods (Static)
        function input = parseObject(param, value)
            value = convertCharsToStrings(value);
            if isstring(value)
                try 
                    eval(sprintf("value = %s;", value));
                catch exception
                    error("Could not construct object from string >>%s<< for parameter: %s\n%s", value, param.Name, exception.message);
                end
            end
            if ~isa(value, param.Type); error("Could not parse object parameter: %s", param.Name); end
            input = value;
        end
        
        function input = parseString(param, value)
            input = convertCharsToStrings(value);
            if ~isstring(input); error("Could not parse string parameter: %s", param.Name); end
        end
        
        function input = parseFloat(param, value)
            input = value;
            if ~isnumeric(value); input = str2num(value); end
            if isnan(input); error("Could not parse float parameter: %s", param.Name); end
        end
        
        function input = parseNumeral(param, value)
            input = value;
            if ~isnumeric(value); input = str2num(value); end
            if isnan(input); error("Could not parse float parameter: %s", param.Name); end
            input = Numeral(input);
        end
        
        function input = parseInteger(param, value)
            input = value;
            if ~isnumeric(value); input = str2num(value); end
            if isnan(input) || ~isequal(input, round(input)); error("Could not parse integer parameter: %s", param.Name); end
            input = int64(input);
        end
        
        function input = parseLogical(param, value)
            input = value;
            if ~islogical(value); input = strcmpi(value, 'true'); end
        end
    end
end

