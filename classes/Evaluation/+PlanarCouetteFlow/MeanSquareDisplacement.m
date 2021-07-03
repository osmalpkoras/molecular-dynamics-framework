classdef MeanSquareDisplacement < Evaluation
    methods
        function this = MeanSquareDisplacement()
            this.bLoadAdvancedInfo = true;
            this.Defaults.AxesFontSize = 12;
            this.Defaults.TextFontSize = 12;
            this.Defaults.LineLineWidth = 1.5;
            this.Defaults.LineMarkerSize = 10;
            this.Defaults.AxesTickLength = [0.02 0.025];
            
            this.includeLibrary(Library("export/cpu.MeanSquareDisplacement.mogonlib")) ...     
                .parseLibraries() ...
                .parseData();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = tracker.Interval.Start == 1000 || tracker.Interval.Start == 5000;
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Evaluation(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            
            elements.set("Start", tracker.Interval.Start);
            elements.set("End", tracker.Interval.End);
            elements.set("Data", data);
        end
        
        function OnProccessingDataElements(this, elements)
            for integrator = elements.group(@(e) e.Integrator)
                for thermostat = integrator.Elements.group(@(e) e.Thermostat)
                    plot = this.getPlot(sprintf("%s_%s", integrator.Value, thermostat.Value));
                    plot.AxisProperties.XScale = "log";
                    plot.AxisProperties.YScale = "log";
                    plot.AxisProperties.XLabel = "{\delta}t";
                    plot.Autofit = false;
                    
                    for starts = thermostat.Elements.sort(@(e) e.Start).group(@(e) e.Start)
                        line = Evaluation.Line();
                        x = unique(round(logspace(-2, 1, 30), 2));
                        indices = [1 2:3:length(x)];
                        line.addPoint(x(indices), mean(starts.Elements.Data(:, indices)));
                        line.Properties.Marker = Utility.Generic.select(starts.Value, 1000, "o", 5000, "x");
                        line.Properties.LineStyle = Utility.Generic.select(starts.Value, 5000, "--", 1000, ":");
                        line.Properties.Color = Utility.Generic.select(starts.Value, 1000, [0 0.4470 0.7410], 5000, [0.8500 0.3250 0.0980]);
                        line.ShowInLegend = false;
                        plot.addAnnotationToLegend(sprintf("t_j \\in [%s;%s]", Utility.Generic.num2str(starts.Value), Utility.Generic.num2str(starts.Value+200)), line.Properties.LineStyle, [0.5 0.5 0.5]);
                        plot.addLine(line);
                    end
                    
                end                    
            end
        end
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/PlanarCouetteFlow/MSD_%s", plot.ID);
        end
    end
end