% a managed library of simulation results
classdef Library < handle
    properties
        Entries Library.ModelEntry
        FilesList
    end
    properties (Transient)
        Directory = "library"
        SimulationLockPath
        savefile
    end
    
    methods        
        function this = Library(dir)
            if nargin > 0; this.Directory = dir; end
            
            this.savefile = sprintf("%s/library.mat", this.Directory);
        end
        
        % loads all previously discovered simulations inside this.Directory
        function this = load(this)
            library = this;
            if isfile(this.savefile)
                load(this.savefile, "library");
            end
                
            files = dir(sprintf("%s/**/*.mat", this.Directory));
            filesList = string.empty();
            for file = files'
                filesList(end+1) = sprintf("%s\\%s", extractAfter(file.folder, this.Directory), file.name);
            end
            if ~isequal(library.FilesList, filesList)
                this.FilesList = filesList;
                this.rediscover();
            else
                this.FilesList = library.FilesList;
                this.Entries = library.Entries;
            end
        end
        
        % rediscovers all simulations stored in this.Directory
        function this = rediscover(this)
            simulations = this.scan(this.Directory);
            this.Entries = Library.ModelEntry.empty();
            
            for simulationFilePath = simulations
                load(simulationFilePath, "key", "step");
                entry = [];
                for i = length(this.Entries):(-1):1
                    if Library.Key.match(this.Entries(i).Key, key)
                        entry = this.Entries(i);
                        break;
                    end
                end
                if isempty(entry)
                    entry = Library.ModelEntry(key);
                    this.Entries(end+1) = entry;
                    dirs = extractAfter(simulationFilePath, sprintf("%s/", this.Directory));
                    dirs = split(dirs, "/");
                    entry.Directory = strjoin(dirs(1:end-2), "/");
                end
                
                stepEntry = entry.getStepEntryForStep(step);
                [~, simName] = fileparts(simulationFilePath);
                stepEntry.appendSimulation(simName);
            end
            
            library = this;
            save(this.savefile, "library", "-v7.3"); 
        end
        
        % used in this.rediscover() to recursively find all simulation files
        function simulations = scan(this, directory, convention)
            contents = dir(directory)';
            simulations = string.empty();
            for content = contents
                if ~isequal(content.name, ".") && ~isequal(content.name, "..")
                    if content.isdir
                        if nargin > 2
                            simulations = [simulations this.scan(sprintf("%s/%s", directory, content.name), convention)];
                        else
                            simulations = [simulations this.scan(sprintf("%s/%s", directory, content.name))];
                        end
                    else
                        if endsWith(content.name, ".mat")
                            filepath = sprintf("%s/%s", directory, content.name);
                            fileInfo = whos('-file', filepath);
                            isSimulationFile = sum(ismember(["simulation", "key", "trackers", "step"], {fileInfo.name})) == 4;
                            if isSimulationFile
                                simulations = [simulations filepath];
                            end
                        end
                    end
                end
            end
        end
        
        % saves a simulation at the path specified by the convention
        function saveSimulation(this, simulation, convention)
            if ~this.hasLockedSimulation(simulation, convention); return; end
            
            key = Library.Key.from(simulation);
            entry = Library.ModelEntry(key);
            entry.Directory = Library.Key.replace(convention, entry.Key);
            entry.checkDirectoryForKey(this.Directory, key);
            
            stepEntry = entry.getStepEntryForStep(simulation.ProductionStep);
            stepEntry.save(this, entry, simulation); % adds or updates, depending on whether it has already been added
            this.Entries(end+1) = entry;
        end
        
        % returns true if simulation exists inside the library at the path
        % specified by the convention
        function [b, subdir, steps] = hasSimulation(this, simulation, convention)
            if isa(simulation, "Simulation")
                simulationName = simulation.Name;
                simulationKey = Library.Key.from(simulation);
            else % otherwise expect cell array with name and key
                simulationName = simulation{1};
                simulationKey = simulation{2};
            end
            subdir = Library.Key.replace(convention, simulationKey);
            directory = sprintf("%s/%s", this.Directory, subdir);
            
            contents = dir(directory)';
            steps = [];
            for content = contents
                if ~isequal(content.name, ".") && ~isequal(content.name, "..") ...
                        && content.isdir ...
                        && startsWith(content.name, "step_") ...
                        && isfile(sprintf("%s/%s/%s.mat", directory, content.name, simulationName))
                    steps(end+1) = str2double(extractAfter(content.name, "step_"));                    
                end
            end
            b = ~isempty(steps);
        end
        
        % loads the most advanced saved simulation matching the
        % InSimulation found at the path specified by the convention
        function simulation = loadSimulation(this, InSimulation, convention)
            simulation = Simulation.empty();
            [hasSimulations, subdir, steps] = this.hasSimulation(InSimulation, convention);
            if hasSimulations
                steps = sort(steps);
                simulation = Library.loadSimulationFromFile(this.Directory, subdir, sprintf("step_%s", num2str(steps(end))), InSimulation.Name);
            end
        end
        
        % locks a simulation at the path specified by the convention, only
        % one simulation can be locked simultaneously
        function tryLockSimulation(this, simulation, convention)
            if ~isempty(this.SimulationLockPath); error("Library cannot lock two simulations at the same time"); end
            dir = Library.Key.replace(convention, Library.Key.from(simulation));
            lockpath = sprintf("%s/%s/Locks/%s.lock", this.Directory, dir, simulation.Name);
            if ~isfolder(lockpath)
                mkdir(lockpath);
                this.SimulationLockPath = lockpath;
            end
        end
        
        % returns true if the simulation has been locked
        function success = hasLockedSimulation(this, simulation, convention)
            dir = Library.Key.replace(convention, Library.Key.from(simulation));
            lockpath = sprintf("%s/%s/Locks/%s.lock", this.Directory, dir, simulation.Name);
            success = ~isempty(this.SimulationLockPath) ...
                && isequal(lockpath, this.SimulationLockPath) ...
                && isfolder(this.SimulationLockPath);
        end
        
        % releases the simulation, which the library is locking currently
        function releaseSimulation(this)
            if isempty(this.SimulationLockPath); error("Library is not holding a lock for any simulation"); end
            try
                rmdir(this.SimulationLockPath);
            catch e
                Global.log("Unexpected behaviour occured: locked directory '%s' did not exist", this.SimulationLockPath);
            end
            this.SimulationLockPath = string.empty();
        end
                
        function entries = filter(this, key)
            entries = Library.Entry.empty;
            for entry = this.Entries
                if Library.Key.match(key, entry.Key)
                    entries = [entries entry];
                end
            end
        end
        
        function entry = findEntryByKey(this, key)
            for entry = this.Entries
                if Library.Key.match(key, entry.Key)
                    return; 
                end
            end
            entry =  [];
        end
        
        function delete(this)
            if ~isempty(this.SimulationLockPath) && isfolder(this.SimulationLockPath)
                rmdir(this.SimulationLockPath);
            end
        end
    end
    methods (Static)
        function simulation = loadSimulationFromFile(libDiretory, subdir, stepdir, name)
            filepath = sprintf("%s/%s/%s/%s.mat", libDiretory, subdir, stepdir, name);
            load(filepath, "simulation");
            for i = 1:length(simulation.Trackers)
                if isa(simulation.Trackers{i}, "History")
                    simulation.Trackers{i}.dir(sprintf("%s/%s/Histories", libDiretory, subdir));
                end
            end
        end
    end
end

