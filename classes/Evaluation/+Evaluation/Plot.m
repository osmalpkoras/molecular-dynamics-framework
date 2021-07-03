classdef Plot < handle
    properties
        Lines Evaluation.Line% GraphPlot, MeshPlot, LogLogPlot sollten ihre eigenen Felder haben
        ID
        AxisProperties = struct(); % properties that can be set for the axis
        Autofit = true; % true, if you want to automatically fit the view into the plot with paddings
    end
    
    methods
        
        function addLine(this, line)
            this.Lines(end+1) = line;
        end
        
        function export(this, filename)
            fig = figure("visible", "off");
            ax = axes('parent', fig);
            FontSize = 16;
            LineWidth = 2;
            MarkerSize = 18;
            TickLength = [0.03 0.03];
            
            set(fig, 'DefaultAxesFontSize', FontSize);
            set(fig, 'DefaultTextFontSize', FontSize);
            set(fig, 'DefaultLineLineWidth', LineWidth);
            set(fig, 'DefaultLineMarkerSize', MarkerSize);
            set(fig, 'DefaultAxesTickLength', TickLength);
                        
            this.plot(fig,ax);
            %supersizeme(f,1.75);
            
            lhandle = findobj(fig, 'Type', 'Legend');
            if ~isempty(lhandle)
                set(lhandle,'visible','off');
            end
            saveas(fig, filename, "epsc");
            %saveas(fig, filename, "jpeg");
            if ~isempty(lhandle)
                set(lhandle,'visible','on');
                this.saveLegendToImage(fig, ax, lhandle, filename);
            end
            close(fig);
        end

        function saveLegendToImage(this, fig, ax, lhandle, filename)
            %make all contents in figure invisible
            allLineHandles = findall(fig, 'type', 'line');
            for i = 1:length(allLineHandles)
                allLineHandles(i).XData = NaN; %ignore warnings
                allLineHandles(i).MarkerSize = 10;
                allLineHandles(i).LineWidth = 1.5;
            end
            set(ax, "visible", "off");
            
            %move legend to lower left corner of figure window
            lhandle.Units = 'pixels';
            boxLineWidth = lhandle.LineWidth;
            %save isn't accurate and would swallow part of the box without factors
            lhandle.Position = [6 * boxLineWidth, 6 * boxLineWidth, ...
                lhandle.Position(3), lhandle.Position(4)];
            legLocPixels = lhandle.Position;
            
            %make figure window fit legend
            fig.Units = 'pixels';
            fig.InnerPosition = [1, 1, legLocPixels(3) + 12 * boxLineWidth, ...
                legLocPixels(4) + 12 * boxLineWidth];
            
            %save legend
            saveas(fig, sprintf("%sLegend.eps", filename), "epsc");
        end
        
        function plot(this, fig, ax)
            if isa(this.Lines, "Evaluation.Line")                
                for line = this.Lines
                    if ~isempty(line.X)
                        params = cell.empty();
                        params(1) = {line.X};
                        params(2) = {line.Y};
                        if isa(line, "Evaluation.ErrorBarLine")
                            params(3) = {line.Err};
                        end
                        
                        params(end+1) = {"HandleVisibility"};
                        if line.ShowInLegend
                            params(end+1) = {"on"};
                        else
                            params(end+1) = {"off"};
                        end
                        
                        for property = fieldnames(line.Properties)'
                            params(end+1) = property;
                            params(end+1) = {line.Properties.(property{:})};
                        end
                        
                        if isa(line, "Evaluation.ErrorBarLine")
                            errorbar(ax, params{:});
                        else
                            plot(ax, params{:});
                        end
                    end
                    hold on;
                end
                hold off;
                legend("show");
            elseif isa(this.Lines, "Evaluation.MeshSurface")
                mesh(ax, this.Lines(1).X, this.Lines(1).Y, this.Lines(1).Z);
            end
            
            if this.Autofit
                this.AutofitPlot();
            end
            
            for property = fieldnames(this.AxisProperties)'
                if isprop(ax, property{:})
                    if isa(ax.(property{:}), "matlab.graphics.primitive.Text")
                        ax.(property{:}).String = this.AxisProperties.(property{:});
                    else
                        ax.(property{:}) = this.AxisProperties.(property{:});
                    end
                end
            end
        end
        
        function AutofitPlot(this)
            if ~isfield(this.AxisProperties, "XLim")
                minOfAllLines = inf;
                maxOfAllLines = -inf;
                for line = this.Lines
                    minOfAllLines = min(min(line.X), minOfAllLines);
                    maxOfAllLines = max(max(line.X), maxOfAllLines);
                end
                this.AxisProperties.XLim = [minOfAllLines maxOfAllLines];
            end
            if ~isfield(this.AxisProperties, "YLim")
                minOfAllLines = inf;
                maxOfAllLines = -inf;
                for line = this.Lines
                    minOfAllLines = min(min(line.Y), minOfAllLines);
                    maxOfAllLines = max(max(line.Y), maxOfAllLines);
                end
                this.AxisProperties.YLim = [minOfAllLines maxOfAllLines];
            end

            this.AxisProperties.XLim = this.getPaddedRange(this.AxisProperties.XLim, this.AxisProperties.XScale);
            this.AxisProperties.YLim = this.getPaddedRange(this.AxisProperties.YLim, this.AxisProperties.YScale);
        end
        function paddedRange = getPaddedRange(this, range, scale)
            paddedRange = [];
            if(scale == "linear")
                padding = 0.1 * abs(range(2) - range(1));
                paddedRange = [-padding padding] + range;
            elseif (scale == "log")
                padding = 0.05 * abs(log(range(2)) - log(range(1)));
                paddedRange = exp([-padding padding] + log(range));
            end
            paddedRange = gather(paddedRange);
        end
        
        function addAnnotationToLegend(this, name, style, color)
            line = Evaluation.Line();
            line.Properties.DisplayName = name;
            line.Properties.LineStyle = style;
            line.Properties.Color = color;
            line.addPoint(NaN, NaN);
            this.addLine(line);
        end
    end
end
