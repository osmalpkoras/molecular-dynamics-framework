classdef HO4Evaluation < Evaluation
    methods
        function this = HO4Evaluation()
            this.includeLibrary(Library("export/HarmonicOscillator.mogonlib")) ...
                .includeLibrary(Library("export/HarmonicOscillator.uncorrelated.mogonlib")) ...
                .parseLibraries() ...
                .parseData() ...
                .evaluate();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = Utility.Generic.matchesAny(tracker.Interval.Gap, 3.7, 0) ...
                && isequal(thermostat.Class, "LangevinThermostat") ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature") ...
                && Utility.Generic.matchesAny(integrator.Class, "BAOAB", "ABOBA");
            if tracker.Interval.Gap == 0
                b = b && step == 10^6;
            else
                b = b && ((step / ceil(tracker.Interval.Gap / dt) + 1) == 10^6);
            end
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Parser(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            elements.set("Data", data);
            elements.set("Gap", tracker.Interval.Gap);
            elements.set("SampleSize", (step / ceil(elements.Gap / elements.dt) + 1));
        end
        
        function OnProccessingDataElements(this, elements)            
            reference = 1;
            plot = this.getPlot(elements(1).Measurable);
            plot.AxisProperties.XScale = "log";
            plot.AxisProperties.YScale = "log";
            plot.AxisProperties.XLabel = "{\Delta}t";
            
            for integrator = elements.group(@(e) e.Integrator)
                for gap = integrator.Elements.group(@(e) e.Gap)
                    [steps] = gap.Elements.group(@(e) e.SampleSize);
                    for step = steps
                        line = Evaluation.Line();
                        line.Properties.DisplayName = sprintf("%s", integrator.Value);
                        line.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980], "SPV", [0.9290 0.6940 0.1250]);
                        line.Properties.Marker = Utility.Generic.select(integrator.Value, "BAOAB", "o", "ABOBA", "s", "ABOBAalternate", "v");
                        if integrator.Value == "BAOAB"
                            line.Properties.MarkerSize = 12;
                        end
                        line.Properties.LineStyle = "-";
                        if gap.Value == 3.7
                            line.Properties.LineStyle = "--";
                            line.ShowInLegend = false;
                        end

                        for dt = step.Elements.group(@(e) e.dt)
                            Utility.Generic.detectNan(dt.Elements.Data);
                            line.addPoint(dt.Value, nanmean(abs(dt.Elements.Data - reference)));
                        end
                        plot.addLine(line);
                    end
                end
            end
            
            plot.addAnnotationToLegend("korr.", "-", [0.5 0.5 0.5]);
            plot.addAnnotationToLegend("unkorr.", "--", [0.5 0.5 0.5]);
        end
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/HarmonicOscillator/%sWithUncorrelatedData", plot.ID);
        end
    end
end

