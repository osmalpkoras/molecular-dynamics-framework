classdef History < Tracker
    properties
        File
        Buffer
        BufferLength = 1000
        HistoryLength
        BufferIndex = 1 % index of
    end
    properties (Transient)
        Directory
        Matfile
    end
    methods
        function this = History(measurable)
            this@Tracker(measurable);
            this.Directory = 'Histories';
            this.HistoryLength = 0;
        end
        
        function initialize(this, simulation)
            this.initialize@Tracker(simulation);
            datasize = size(this.Measurable.format(this.Measurable.measure(simulation)));
            
            this.Buffer = Numeral(zeros([this.BufferLength datasize]));
            Data = zeros([1 datasize]);
            
            Key = Library.Key.from(simulation);
            Key.Tracker = Library.Key.from(this);
            
            if ~isfolder(this.Directory); mkdir(this.Directory); end
            this.File.Name = History.getUniqueFileNameInDir(this.Directory);
            save(this.filepath, "Data", "Key","-v7.3");
            
            this.Matfile = matfile(this.filepath, 'Writable', true);
            this.File.SubIndices = join(repmat(",:", 1, length(size(Data))-1), '');
            this.File.Index = 1;
        end
        
        % sets the directory from where to read the history file
        function this = dir(this, directory)
            this.Directory = directory;
            if isfile(this.filepath)
                this.Matfile = matfile(this.filepath, 'Writable', true);
            end
        end
        
        % sets the size if the buffer. writes to history file happen when buffer is full.
        function this = buffersize(this, size)
            this.BufferLength = size;
        end
        
        function size = getSampleSize(this)
            size = this.TotalLength(); 
        end
        
        function l = TotalLength(this)
            l = this.HistoryLength + this.BufferIndex - 1;
        end
        
        function v = getValue(this)
            load(this.filepath, "Data");
            v = eval(sprintf("cat(1, Data(1:this.HistoryLength%s), gather(this.Buffer(1:%d%s)));", this.File.SubIndices, this.BufferIndex-1, this.File.SubIndices));
        end
        
        function v = at(this, index)
            v = [];
            if 1 <= index && index <= this.HistoryLength
                v = eval(sprintf("this.Matfile.Data(index%s);", this.File.SubIndices));
            elseif index <= this.HistoryLength + this.BufferIndex - 1
                v = eval(sprintf("this.Buffer(index-this.HistoryLength%s);", this.File.SubIndices));
            end
        end
        
        function v = getEndValue(this)
            if this.BufferIndex == 1
                v = eval(sprintf("this.Matfile.Data(end,:%s);", this.File.SubIndices));
            else
                v = eval(sprintf("this.Buffer(this.BufferIndex,:%s);", this.File.SubIndices));
            end
        end
        
        function fp = filepath(this)
            fp = "";
            if ~isempty(this.File)
                if isempty(this.Directory)
                    fp = sprintf("%s.mat", this.File.Name);
                else
                    fp = sprintf("%s/%s.mat", this.Directory, this.File.Name);
                end
            end
        end
    end
    
    methods (Access = protected)
        function onUpdate(this, simulation)
            this.set(this.File.Index, this.Measurable.format(this.Measurable.measure(simulation)));
            this.File.Index = this.File.Index + 1;
        end
        
        function set(this, index, value)
            this.Buffer(this.BufferIndex, :) = value(:);
            this.BufferIndex = this.BufferIndex + 1;
            if this.BufferIndex > this.BufferLength
                eval(sprintf("this.Matfile.Data(%d:%d%s) = gather(this.Buffer);", index-this.BufferLength+1, index, this.File.SubIndices));
                this.HistoryLength = this.HistoryLength + this.BufferLength;
                this.BufferIndex = 1;
            end
        end
    end
    
    methods (Static)
        function name = getUniqueFileNameInDir(dir)
            name = java.util.UUID.randomUUID;
            prefix = "";
            if ~isempty(dir)
                prefix = sprintf("%s/", dir);
            end
            while isfile(sprintf("%s%s.mat", prefix, name))
                name = java.util.UUID.randomUUID;
            end
        end
        
        function this = loadobj(loadthis)
            this = loadthis;
            if isempty(loadthis.HistoryLength)
                this.HistoryLength = this.File.Index - 1;
                Globals.log("HistoryLength is empty. What to do?");
            end
        end
    end
end

