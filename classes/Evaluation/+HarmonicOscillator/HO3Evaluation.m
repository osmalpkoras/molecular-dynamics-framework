classdef HO3Evaluation < Evaluation
    methods
        function this = HO3Evaluation()
            this.includeLibrary(Library("export/HarmonicOscillator.mogonlib")) ...    
                .parseLibraries() ...
                .parseData() ...
                .evaluate();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = tracker.Interval.Gap == 0 ...
                && isequal(thermostat.Class, "LangevinThermostat") ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature") ...
                && isequal(integrator.Class, "BAOAB");
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
            
            [steps] = elements.group(@(e) e.step);
            for step = steps
                step.Value
                line = Evaluation.Line();
                line.Properties.DisplayName = sprintf("%s", step.Elements(1).Integrator);
                line.Properties.Marker = "o";
                line.Properties.MarkerSize = 12;
                line.Properties.LineStyle = Utility.Generic.select(step.Value, 10^6, "--", 10^7, "-", 10^8, ":");
                line.Properties.Color = [0 0.4470 0.7410];
                
                [dts] = step.Elements.group(@(e) e.dt);
                %line.Properties.MarkerIndices = 1:2:length(dts);
                for dt = dts
                    line.addPoint(dt.Value, mean(abs(dt.Elements(1).Data - reference))*sqrt(step.Value));
                end
                plot.addLine(line);
            end
        end
        
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/HarmonicOscillator/%sWithVaryingNM_BAOABScaled", plot.ID);
        end
    end
end

