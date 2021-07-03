classdef Parser < handle
    properties
        Data Parser.DataElement
        bMergeIndependentRuns = true; % whether data from indepentend runs should be merged to a single dataset
        bLoadAdvancedInfo = false; % whether additional info of a simulation should be loaded, like runtime info or how the number of independent runs M
        Libraries Library = Library.empty();
        DataGroups = struct("entry", {}, "stepEntry", {}, "tracker", {});
    end
    methods        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times); b = logical(step); end
        
        function this = includeLibrary(this, library)
            for lib = this.Libraries
                if lib.Directory == library.Directory; return; end
            end
            this.Libraries(end+1) = library;
        end
        
        function this = parseLibraries(this)
            this.Data = Parser.DataElement.empty();
            this.DataGroups = struct("entry", {}, "stepEntry", {}, "tracker", {});
            
            for library = this.Libraries
                library.load();
                for entry = library.Entries
                    for stepEntry = entry.StepEntries'
                        % skip, if step == 0, because this data has only been
                        % equillibrated and its data is of no interest
                        if stepEntry.Step == 0; continue; end

                        simulationsPerTracker = struct("Key", {}, "loadData", {}, "Runtimes", {}, "Ms", {});
                        for simulationName = stepEntry.Simulations
                            filepath = sprintf("%s/%s/%s/%s.mat", library.Directory, entry.Directory, stepEntry.Directory, simulationName);

                            totalRuntime = -1;
                            m = -1;
                            if this.bLoadAdvancedInfo
                                load(filepath, "simulation", "trackers");
                                totalRuntime = simulation.TotalRuntime;
                                m = simulation.Model.M;
                            else
                                load(filepath, "trackers"); 
                            end

                            for i = 1:length(trackers)
                                pendingTrackerKey = trackers(i);
                                isNewTracker = true;
                                if this.bMergeIndependentRuns
                                    for j = 1:length(simulationsPerTracker)
                                        if Library.Key.isequal(pendingTrackerKey, simulationsPerTracker(j).Key)
                                            simulationsPerTracker(j).loadData(end+1) = {@() this.getDataFromTracker(library, entry, stepEntry, simulationName, i)};
                                            simulationsPerTracker(j).Runtimes(end+1) = totalRuntime;
                                            simulationsPerTracker(j).Ms(end+1) = m;                                        
                                            isNewTracker = false;
                                            break;
                                        end
                                    end
                                end

                                if isNewTracker
                                    newTracker = struct();
                                    newTracker.Key = pendingTrackerKey;
                                    newTracker.loadData = {@() this.getDataFromTracker(library, entry, stepEntry, simulationName, i)};
                                    newTracker.Runtimes = totalRuntime;
                                    newTracker.Ms = m;
                                    simulationsPerTracker(end+1) = newTracker;
                                end
                            end
                        end

                        newdatagroupentry = struct();
                        newdatagroupentry.entry = entry;
                        newdatagroupentry.stepEntry = stepEntry;
                        for tracker = simulationsPerTracker
                            if this.select(entry.Key.Model, entry.Key.Integrator, entry.Key.Thermostat, tracker.Key, tracker.Key.Measurable, entry.Key.dt, stepEntry.Step, entry.Key.dt * stepEntry.Step, [entry.StepEntries.Step], entry.Key.dt * [entry.StepEntries.Step])
                                newdatagroupentry.tracker = tracker;
                                this.DataGroups(end+1) = newdatagroupentry;
                            end
                        end
                    end
                end
            end
            
        end
        
        function this = parseData(this)
            for elem = this.DataGroups
                entry = elem.entry;
                stepEntry = elem.stepEntry;
                tracker = elem.tracker;
                
                elements = this.OnCreatingDataElements(this.loadDataForTracker(tracker), entry.Key.Model, entry.Key.Integrator, entry.Key.Thermostat, tracker.Key, tracker.Key.Measurable, entry.Key.dt, stepEntry.Step, tracker.Runtimes, tracker.Ms);
                this.Data = [this.Data elements];
            end
            
        end
        
        function this = processData(this)
            this.OnProccessingDataElements(this.Data);
        end
        
        % default implementation of creating data elements
        % use this to create data elements in child classes, then set key
        % value pairs as needed
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = Parser.DataElement();            
            elements.set("Model", model.Class);
            elements.set("Integrator", integrator.Class);
            if elements.Integrator == "VVASLLOD"; elements.Integrator = "VVA"; end
            elements.set("Thermostat", extractBefore(thermostat.Class, "Thermostat"));
            elements.set("Tracker", tracker.Class);
            elements.set("Measurable", measurable);
            elements.set("dt", dt);
            elements.set("step", step);
            if this.bLoadAdvancedInfo
                elements.set("Runtimes", runtimes);
                elements.set("M", ms);
            end
        end
        
        function data = loadDataForTracker(this, tracker)
            data = [];
            for i = 1:length(tracker.loadData)
                concatDim = 1;
                if tracker.Key.Class == "History"
                    concatDim = 2;
                end
                try
                    tmp = tracker.loadData{i}();
                    if ~isempty(tmp)
                        % if we load history data and histories have
                        % different lengths, we pad the missing fields with
                        % the mean value
                        if tracker.Key.Class == "History"
                            sizeTmp = size(tmp, 1);
                            sizeData = size(data, 1);
                            if sizeTmp < sizeData
                                tmp((sizeTmp+1):sizeData, :, :, :, :, :) = repmat(mean(tmp), sizeData - sizeTmp, 1);
                                fprintf("sucks    tmp=%s    data=%s\n", num2str(sizeTmp), num2str(sizeData));
                            elseif sizeData > 0 && sizeTmp > sizeData
                                data((sizeData+1):sizeTmp, :, :, :, :, :) = repmat(mean(data), sizeTmp - sizeData, 1);
                                fprintf("sucks the other way around    tmp=%s    data=%s\n", num2str(sizeTmp), num2str(sizeData));
                            end
                        end
                        data = cat(concatDim, data, tmp);
                    end
                catch e
                    disp(e);
                end
            end
        end
        
        function data = getDataFromTracker(this, library, entry, stepEntry, simulationName, index)
            data = [];
            s = stepEntry.load(library, entry, simulationName);
            try
                data = s.Trackers{index}.getValue();
                %fprintf("[%s] %s at dt = %s with %s loaded:    %s\n", class(s.Trackers{index}.Measurable), simulationName, num2str(entry.Key.dt), entry.Key.Integrator.Class, num2str(size(data,1)));
            catch e
                fprintf("ERROR [%s %s] %s at dt = %s with %s\n", num2str(entry.Key.Model.N), class(s.Trackers{index}.Measurable), simulationName, num2str(entry.Key.dt), entry.Key.Integrator.Class);
            end
        end
    end
    
    methods (Abstract)
        OnProccessingDataElements(this, groups);
    end
end

