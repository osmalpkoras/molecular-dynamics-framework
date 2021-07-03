classdef HO2Evaluation < Evaluation
    methods
        function this = HO2Evaluation()
            this.Defaults.AxesFontSize = 12;
            this.Defaults.TextFontSize = 12;
            this.Defaults.LineLineWidth = 1.5;
            this.Defaults.LineMarkerSize = 10;
            this.Defaults.AxesTickLength = [0.02 0.025];
            this.includeLibrary(Library("export/HarmonicOscillator.mogonlib")) ...    
                .parseLibraries() ...
                .parseData() ...
                .evaluate();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = tracker.Interval.Gap == 0 ...
                && isequal(thermostat.Class, "LangevinThermostat") ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature") ...
                && Utility.Generic.matchesAny(integrator.Class, "BAOAB", "ABOBA");
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Parser(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            elements.set("Data", data);
        end
        
        function OnProccessingDataElements(this, elements)            
            reference = 1;
            plot = this.getPlot(elements(1).Measurable);
            plot.AxisProperties.XScale = "log";
            plot.AxisProperties.YScale = "log";
            plot.AxisProperties.XLabel = "{\Delta}t";
            
            [integrators] = elements.group(@(e) e.Integrator);
            for integrator = integrators
                [steps] = integrator.Elements.group(@(e) e.step);
                for step = steps
                    line = Evaluation.Line();
                    %line.Name = sprintf("%s %s %s", integrator.Value, extractBefore(thermostat.Value, "Thermostat"), num2str(step.Value));
                    line.Properties.DisplayName = sprintf("%s", integrator.Value);
                    line.ShowInLegend = step.Value == 10000000;
                    line.Properties.Marker = Utility.Generic.select(integrator.Value, "VVA", "d", "BAOAB", "o", "ABOBA", "s", "SPV", "x");
                    if integrator.Value == "BAOAB"
                        line.Properties.MarkerSize = 12;
                    end
                    line.Properties.LineStyle = Utility.Generic.select(step.Value, 10^6, "--", 10^7, "-", 10^8, ":");
                    line.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980], "SPV", [0.9290 0.6940 0.1250]);

                    [dts] = step.Elements.group(@(e) e.dt);
                    for dt = dts
                        line.addPoint(dt.Value, nanmean(abs(dt.Elements(1).Data - reference)));
                    end
                    plot.addLine(line);
                end
            end
            
            plot.addAnnotationToLegend("N_{{\Delta}t} = 10^7", "-", [0.5 0.5 0.5]);
            plot.addAnnotationToLegend("N_{{\Delta}t} = 10^6", "--", [0.5 0.5 0.5]);
            plot.addAnnotationToLegend("N_{{\Delta}t} = 10^8", ":", [0.5 0.5 0.5]);
        end
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/HarmonicOscillator/%sWithVaryingNM", plot.ID);
        end
    end
end

