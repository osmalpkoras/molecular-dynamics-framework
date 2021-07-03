classdef ModelEntry < handle    
    properties 
        Key
        Directory
        StepEntries
    end
    
    methods
        function this = ModelEntry(key)
            this.Key = key;
        end
        
        function checkDirectoryForKey(this, libraryDir, key)
            dirPath =  sprintf("%s/%s", libraryDir, this.Directory);
            keyFilePath = sprintf("%s/Key.mat", dirPath);
            if isfile(keyFilePath)
                load(keyFilePath, "key");
                if ~Library.Key.isequal(this.Key, key)
                    error("Trying to save a simulation in a file with the wrong key. Please provide a directory naming convention with unique paths for all relevant keys");
                    return;
                end
            else
                if ~isfolder(dirPath); mkdir(dirPath); end
                save(keyFilePath, "key");
            end
        end
        
        function b = exists(this)
            b = true;
        end        
        
        function stepEntry = getStepEntryForStep(this, step)
            appendAt = 1;
            simStep = gather(step);
            while appendAt <= length(this.StepEntries)
                % as long as the new simulation has advanced further than
                % the ones we have saved, we increase the index, at which 
                % we will append the new simulation
                if this.StepEntries(appendAt).Step < simStep
                    appendAt = appendAt + 1;
                % if the next saved simulation was already further advanced
                % than the new simulation, we must create insert a new
                % element, where we can append the new simulation
                elseif simStep < this.StepEntries(appendAt).Step
                    break;
                % else we have found simulations that have advanced as much
                % as the new simulation, so we have found the index, at which 
                % we will append the new simulation
                else
                    break;
                end
            end
            
            if appendAt > length(this.StepEntries) || this.StepEntries(appendAt).Step ~= simStep
                stepEntry = Library.StepEntry(simStep);
                this.StepEntries = [this.StepEntries(1:(appendAt-1)); stepEntry; this.StepEntries(appendAt:end)];
            end
            stepEntry = this.StepEntries(appendAt);
        end
    end
    methods (Static)
        function this = loadobj(loadthis)
            this = loadthis;
        end
    end
end

