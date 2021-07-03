classdef HarmonicOscillatorEvaluation < Evaluation
    methods
        function this = HarmonicOscillatorEvaluation()
            this.Defaults.AxesFontSize = 12;
            this.Defaults.TextFontSize = 12;
            this.Defaults.LineLineWidth = 1.5;
            this.Defaults.LineMarkerSize = 10;
            this.Defaults.AxesTickLength = [0.02 0.025];
            this.includeLibrary(Library("export/HarmonicOscillator.new.mogonlib")) ...            
                .parseLibraries() ...
                .parseData() ...
                .evaluate();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = tracker.Interval.Gap == 0 ...
                && ~(isequal(thermostat.Class, "IsokineticThermostat")) ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature", "Temperature", "Energy") ...
                && step == 10^7;
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Parser(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            elements.set("Data", data);
        end
        
        function OnProccessingDataElements(this, elements)            
            [measurables] = elements.group(@(e) e.Measurable);
            for measure = measurables
                plot = this.getPlot(measure.Value);
                plot.AxisProperties.XScale = "log";
                plot.AxisProperties.YScale = "log";
                plot.AxisProperties.XLabel = "{\Delta}t";
                
                [integrators] = measure.Elements.group(@(e) e.Integrator);
                for integrator = integrators
                    [thermostats] = integrator.Elements.group(@(e) e.Thermostat);
                    for thermostat = thermostats
                        line = Evaluation.Line();
                        line.Properties.DisplayName = Utility.Generic.select(integrator.Value, "VVA", "VVA [L]", integrator.Value, integrator.Value);
                        line.Properties.Marker = Utility.Generic.select(integrator.Value, "VVA", "d", "BAOAB", "o", "ABOBA", "s", "SPV", "x");
                        if Utility.Generic.matchesAny(integrator.Value, "BAOAB", "VVA")
                            line.Properties.MarkerSize = 12;
                        end
                        line.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980], "SPV", [0.9290 0.6940 0.1250]);
                            
                        [dts] = thermostat.Elements.sort(@(e) e.dt).group(@(e) e.dt);
                        reference = 1;
                        if measure.Value == "Energy"
                            reference = mean(dts(1).Elements.Data);
                        end    
                        for dt = dts(2:end)
                            line.addPoint(dt.Value, mean((abs(dt.Elements(1).Data - reference))));
                        end
                        plot.addLine(line);
                    end
                end
            end
        end
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/HarmonicOscillator/%s", plot.ID);
        end
    end
end

