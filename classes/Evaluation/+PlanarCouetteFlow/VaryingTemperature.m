classdef VaryingTemperature < Evaluation
    methods
        function this = VaryingTemperature()
            this.Defaults.AxesFontSize = 12;
            this.Defaults.TextFontSize = 12;
            this.Defaults.LineLineWidth = 1.5;
            this.Defaults.LineMarkerSize = 10;
            this.Defaults.AxesTickLength = [0.02 0.025];
            
            this.includeLibrary(Library("export/cpu.PlanarCouetteFlow.history.mogonlib")) ...     
                .parseLibraries() ...
                .parseData();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = model.ShearRate == 0 ...
                && dt == 0.01 ...
                && tracker.Interval.Gap == 0 ...
                && (thermostat.Class == "IsokineticThermostat" || thermostat.FrictionConstant == 1) ...
                && Utility.Generic.matchesAny(integrator.Class, "BAOAB", "ABOBA", "VVASLLOD") ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature", "ThermalStressTensor", "Energy", "Temperature") ...
                && step == Utility.Generic.selectClosestTo(500000,steps);
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Evaluation(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            data = data(1:100,:,:);
            elements.set("Gap", max(dt, tracker.Interval.Gap));
            elements.set("M", size(data, 1));
            elements.set("N", model.N);
            elements.set("Ns", step);
            elements.set("Temperature", model.Temperature);
            if isfield(thermostat, "FrictionConstant")
                elements.set("FrictionConstant", thermostat.FrictionConstant);
            else
                elements.set("FrictionConstant", 1);
            end
            elements.set("ShearRate", model.ShearRate);
            
            
            if isequal(measurable, "ThermalStressTensor")
                entries(1) = copy(elements);
                entries(1).set("Data", data(:,1,1));
                entries(1).set("Measurable", "tau11");
                
                entries(2) = copy(elements);
                entries(2).set("Data", data(:,2,2));
                entries(2).set("Measurable", "tau22");
                
                entries(3) = copy(elements);
                entries(3).set("Data", data(:,1,2));
                entries(3).set("Measurable", "tau12");   
                
                elements.set("Data", (-data(:,1,1) - data(:,2,2)) / 2);
                elements.set("Measurable", "ThermalPressure");
                elements = [elements entries];
            else
                elements.set("Data", data);
            end
        end
        
        function OnProccessingDataElements(this, elements)
            for measure = elements.group(@(e) e.Measurable)
                plot = this.getPlot(measure.Value);
                plot.AxisProperties.XScale = "linear";
                plot.AxisProperties.YScale = "linear";
                plot.AxisProperties.XLabel = "k_B T_0";
                plot.AxisProperties.Title = measure.Value;
                
                for integrator = measure.Elements.group(@(e) e.Integrator)
                    for thermostat = integrator.Elements.group(@(e) e.Thermostat)
                        line = Evaluation.Line();
                        line.Properties.DisplayName = sprintf("%s", integrator.Value);
                        line.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980]);
                        line.Properties.Marker = Utility.Generic.select(integrator.Value, "VVA", "d", "BAOAB", "o", "ABOBA", "s");

                        for temperature = thermostat.Elements.sort(@(e) e.dt).group(@(e) e.Temperature)
                            fprintf("%10s    N %10s    N_S %10s    M %10s    Dt %10s    dt %10s\n", temperature.Elements.Integrator, num2str(temperature.Elements.N), num2str(temperature.Elements.Ns), num2str(temperature.Elements.M), num2str(temperature.Value), num2str(temperature.Elements.Gap));
                            line.addPoint(temperature.Value, mean(temperature.Elements.Data));
                        end

                        plot.addLine(line);
                    end
                end
            end
            
            
            for integrator = this.selectElementGroups(elements.group(@(e) e.Integrator), ["VVA", "ABOBA", "BAOAB"])
                for thermostat = integrator.Elements.group(@(e) e.Thermostat)
                    fprintf("\\midrule\n");
                    fprintf("%-5s %s", integrator.Value, thermostat.Value);
                    for temperature = thermostat.Elements.sort(@(e) e.Temperature).group(@(e) e.Temperature)
                        measurables = this.selectElementGroups(temperature.Elements.group(@(e) e.Measurable), ["Temperature", "ConfigurationalTemperature", "Energy", "ThermalPressure", "tau11", "tau22", "tau12"]);
                        fprintf(" & %s", Utility.Generic.num2str(temperature.Value));
                        for measure = measurables
                            fprintf(" & %s", Utility.Generic.num2str(round(mean(measure.Elements.Data), 4)));
                        end
                        fprintf(" \\\\\n");
                    end
                end
            end
            fprintf("\\bottomrule\n");
        end
    end
end