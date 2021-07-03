classdef Evaluation < Parser
    properties
        Plots Evaluation.Plot
        Defaults = struct();
    end
    methods
        function filename = savePlot(this, plot); filename = []; end
        
        function this = evaluate(this, varargin)
            this.Plots = Evaluation.Plot.empty();
            this.processData();
            
            for plot = this.Plots
                for line = plot.Lines
                    line.OnPostProcessingData(); 
                end
            end
            
            for i = 1:length(this.Plots)
                f = figure(i);
                clf(f, 'reset');
                ax = axes('parent', f);
                for defaultValue = fieldnames(this.Defaults)'
                    set(f, sprintf("Default%s", defaultValue{:}), this.Defaults.(defaultValue{:}));
                end
                this.Plots(i).plot(f, ax);
                this.savePlotToFile(this.Plots(i));
            end
        end
        
        function savePlotToFile(this, plot)
            filename = this.savePlot(plot);
            if ~isempty(filename)
                filedir = fileparts(filename);
                if ~isfolder(filedir); mkdir(filedir); end
                
                plot.export(filename);
            end
        end
        
        function plot = getPlot(this, id)
            plot = [];
            for i = 1:length(this.Plots)
                if isequal(this.Plots(i).ID, id)
                    plot = this.Plots(i);
                end
            end
            if isempty(plot)
                plot = Evaluation.Plot;
                plot.ID = id;
                this.Plots(end+1) = plot;
            end
        end
                
        function selection = selectElementGroups(this, groups, selectors)
            for selector = selectors
                for option = groups
                    if isequal(option.Value, selector)
                        if ~exist("selection", "var")
                            selection = option;
                        else
                            selection(end+1) = option;
                        end
                    end
                end
            end
        end
    end
end
