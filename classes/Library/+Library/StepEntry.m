classdef StepEntry < handle
    properties
        Step
        Directory
        Simulations = string.empty(); % list of simulation names  = filenames of simulations
    end
    
    methods
        function this = StepEntry(simStep)
            this.Step = simStep;
            this.Directory = Library.StepEntry.getStepDirectoryName(simStep);
        end
        
        function appendSimulation(this, simulationName)
            if ~this.hasSimulation(simulationName)
                this.Simulations = [this.Simulations simulationName];
            end
        end
        
        function save(this, library, modelEntry, simulation)
            filepath = sprintf("%s/%s/%s/%s.mat", library.Directory, modelEntry.Directory, this.Directory, simulation.Name);
            step = this.Step;
            key = Library.Key.from(simulation);
            trackers = struct.empty();
            for i = 1:length(simulation.Trackers)
                trackers = [trackers Library.Key.from(simulation.Trackers{i})];
                if isa(simulation.Trackers{i}, "History")
                    oldfilepath = simulation.Trackers{i}.filepath;
                    newdir = sprintf("%s/%s/Histories", library.Directory, modelEntry.Directory);
                    if ~isfolder(newdir); mkdir(newdir); end
                    simulation.Trackers{i}.dir(newdir);
                    newfilepath = simulation.Trackers{i}.filepath;
                    if ~isequal(oldfilepath, newfilepath)
                        if isfile(newfilepath)
                            simulation.Trackers{i}.File.Name = History.getUniqueFileNameInDir(newdir);
                        end
                        copyfile(oldfilepath, simulation.Trackers{i}.filepath);
                        simulation.Trackers{i}.dir(newdir); % we set the directory to set the matfile
                    end
                end
            end
            dir = fileparts(filepath);
            if ~isfolder(dir); mkdir(dir); end
            timestamp = struct();
            timestamp.local = datetime();  
            timestamp.utc = datetime();
            timestamp.local.TimeZone = "local";
            timestamp.utc.TimeZone = "UTC";
            save(filepath, "simulation", "key", "step", "trackers", "timestamp", "-v7.3");
            this.appendSimulation(simulation.Name);
        end
        
        function b = hasSimulation(this, name)
            b = ismember(name, this.Simulations);
        end
        
        function simulation = load(this, library, modelEntry, name)
            simulation = Simulation.empty();
            if this.hasSimulation(name)
                simulation = Library.loadSimulationFromFile(library.Directory, modelEntry.Directory, this.Directory, name);
            end
        end
    end
    methods (Static)
        function dir = getStepDirectoryName(step)
            dir = sprintf("step_%s", num2str(step));
        end
    end
    methods (Static)
        function this = loadobj(loadthis)
            this = loadthis;
        end
    end
end

