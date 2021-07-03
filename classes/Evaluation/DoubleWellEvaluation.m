classdef DoubleWellEvaluation < Evaluation
    methods
        function this = DoubleWellEvaluation()
            this.includeLibrary(Library("export/DoubleWell.mogonlib")) ...     
                .parseLibraries() ...
                .parseData() ...
                .evaluate();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = tracker.Interval.Gap == 0 ...
                && ~(isequal(measurable, "Temperature") && isequal(integrator.Class, "VVASLLOD") && isequal(thermostat.Class, "IsokineticThermostat")) ...
                && step == 10^9;
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Evaluation(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
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
                        line.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980], "SPV", [0.9290 0.6940 0.1250]);
                       
                        [dts] = thermostat.Elements.sort(@(e) e.dt).group(@(e) e.dt);
                        reference = 1;
                        if measure.Value == "Energy"
                            reference = mean(dts(1).Elements.Data);
                        end     
                        for dt = dts(2:end)               
                            isnanCount = sum(isnan(dt.Elements.Data));
                            if  isnanCount > size(dt.Elements.Data, 1) * 0.00
                                continue;
                            end
                            line.addPoint(dt.Value, nanmean(abs(dt.Elements.Data - reference)));
                        end
                        plot.addLine(line);
                    end
                end
            end
            
            for measure = elements.group(@(e) e.Measurable)
                fprintf("%s\n", measure.Value);
                for integrator = measure.Elements.group(@(e) e.Integrator)
                    sortedDt = integrator.Elements.sort(@(e) e.dt);
                    reference = 1;
                    if measure.Value == "Energy"
                        reference = mean(sortedDt(1).Data);
                    end   
                    errorValue = @(data) mean(abs(data - reference));
                    convergenceOrder = [];
                    for i = 3:length(sortedDt)
                        if(sum(isnan(sortedDt(i).Data)) == 0)
                            convergenceOrder(end+1) = (log(errorValue(sortedDt(i).Data)) - log(errorValue(sortedDt(i-1).Data))) / (log(sortedDt(i).dt) - log(sortedDt(i-1).dt));
                        end
                    end
                    
                    fprintf("%s [%s]", integrator.Value, Utility.Generic.num2str(round(mean(convergenceOrder), 2)));
                    for dt = integrator.Elements.sort(@(e) e.dt).group(@(e) e.dt)
                        isnanCount = sum(isnan(dt.Elements.Data));
                        fprintf(" & %s", Utility.Generic.num2str(100 - isnanCount / length(dt.Elements.Data) * 100))
                    end
                    fprintf("\n");
                end
            end
        end
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/DoubleWell/%s", plot.ID);
        end
    end
end

