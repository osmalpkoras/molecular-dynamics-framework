classdef BulkSystemWithIsokineticSplitting < Evaluation
    methods
        function this = BulkSystemWithIsokineticSplitting()
            this.bLoadAdvancedInfo = true;
            this.Defaults.AxesFontSize = 12;
            this.Defaults.TextFontSize = 12;
            this.Defaults.LineLineWidth = 1.5;
            this.Defaults.LineMarkerSize = 10;
            this.Defaults.AxesTickLength = [0.02 0.025];
            
            this.includeLibrary(Library("export/cpu.PlanarCouetteFlow.mogonlib")) ...
                .parseLibraries() ...
                .parseData();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = model.ShearRate == 0 ...
                && model.Temperature == 1 ...
                && (thermostat.Class == "IsokineticThermostat" || thermostat.FrictionConstant == 1) ...
                && Utility.Generic.matchesAny(integrator.Class,  "BAOAB", "VVASLLOD", "ABOBA") ...
                && tracker.Interval.Gap > 0 ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature", "ThermalStressTensor", "Energy", "Temperature") ...
                && (dt == 0.001 || (dt <= 0.01 && dt >= 0.005)) ...
                && (dt ~= 0.0063 && dt ~= 0.0079) ...
                && step == steps(end);
%             if thermostat.Class == "LangevinThermostat"
%                 if measurable == "ConfigurationalTemperature"
%                     b = b && step == steps(end);
%                 else
%                     b = b && (step / ceil(tracker.Interval.Gap / dt) + 1) == 2*10^5;
%                 end
%             else
%                 b = b && (step / ceil(tracker.Interval.Gap / dt) + 1) == 10^5;
%             end
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Evaluation(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            
            if contains(elements.Thermostat, "Isokinetic")
                if elements.Integrator == "BAOAB"
                    elements.Integrator = "BAIAB";
                elseif elements.Integrator == "ABOBA"
                    elements.Integrator = "ABIBA";
                end
            end
            
            elements.set("Gap", tracker.Interval.Gap);
            elements.set("M", size(data, 1));
            elements.set("N", model.N);
            elements.set("Ns", (step / ceil(tracker.Interval.Gap / dt) + 1));
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
            
%             for element = elements
%                 if contains(element.Thermostat, "Langevin")
%                     element.Data = element.Data(2:2:end, :);
%                     element.Length = element.Length / 2;
%                     element.Ns = element.Length;
%                     element.Gap = element.Gap * 2;
%                 end
%                 element.Data = mean(element.Data);
%             end
        end
        
        function OnProccessingDataElements(this, elements)
            [measurables] = elements.group(@(e) e.Measurable);
            for measure = measurables                
                [integrators]= measure.Elements.group(@(e) e.Integrator);
                for integrator = integrators
                    [thermostats] = integrator.Elements.group(@(e) e.Thermostat);
                    for thermostat = thermostats
                        plot = this.getPlot(measure.Value);
                        plot.AxisProperties.XScale = "linear";
                        plot.AxisProperties.YScale = "linear";
                        plot.AxisProperties.XLabel = "{\Delta}t";
                        %plot.AxisProperties.Title = measure.Value;                        
                        
                        errorPlot = this.getPlot(sprintf("Error_%s", measure.Value));
                        errorPlot.AxisProperties.XScale = "log";
                        errorPlot.AxisProperties.YScale = "log";
                        errorPlot.AxisProperties.XLabel = "{\Delta}t";
                        
                        ns = thermostat.Elements.group(@(e) e.N);
                        for n = ns
                            line = Evaluation.Line();
                            line.Properties.DisplayName = sprintf("%s", integrator.Value);
                            line.ShowInLegend = n.Value == 100;
                            line.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980], "BAIAB", [0.9290 0.6940 0.1250]);
                            line.Properties.Marker = Utility.Generic.select(integrator.Value, "VVA", "d", "BAOAB", "o", "BAIAB", "x", "ABOBA", "s");
                            
                            errorLine = Evaluation.Line();
                            errorLine.Properties.DisplayName = line.Properties.DisplayName;
                            errorLine.Properties.Color = line.Properties.Color;
                            errorLine.Properties.Marker = line.Properties.Marker;
                            
                            dts = n.Elements.sort(@(e) e.dt).group(@(e) e.dt);
                            reference = mean(dts(1).Elements.Data);
                            line.addPoint(dts(1).Value, reference);
                            fprintf("[%-26s] %-10s [N_S] %-10s [M] %-7s [dt] %-7s [Gap] %-7s [Temperature] %-7s [ShearRate] %-7s [FrictionConstant] %-7s\n" , ...
                                    measure.Value, integrator.Value, num2str(dts(1).Elements.Ns), num2str(dts(1).Elements.M), num2str(dts(1).Value), num2str(dts(1).Elements.Gap), num2str(dts(1).Elements.Temperature), num2str(dts(1).Elements.ShearRate), num2str(dts(1).Elements.FrictionConstant));
                            for dt = dts(2:end)
                                dtgreat = dt.Elements.sort(@(e) e.Ns);
                                dt.Elements = dtgreat(end);
                                fprintf("[%-26s] %-10s [N_S] %-10s [M] %-7s [dt] %-7s [Gap] %-7s [Temperature] %-7s [ShearRate] %-7s [FrictionConstant] %-7s\n" , ...
                                    measure.Value, integrator.Value, num2str(dt.Elements.Ns), num2str(dt.Elements.M), num2str(dt.Value), num2str(dt.Elements.Gap), num2str(dt.Elements.Temperature), num2str(dt.Elements.ShearRate), num2str(dt.Elements.FrictionConstant));
                                line.addPoint(dt.Value, mean(dt.Elements.Data));
                                errorLine.addPoint(dt.Value, mean(abs(reference - dt.Elements.Data)));
                            end
                            
                            plot.addLine(line);
                            errorPlot.addLine(errorLine);
                        end
                    end
                end
            end
            
            
            
            
            for integrator = this.selectElementGroups(elements.group(@(e) e.Integrator), ["VVA", "ABOBA", "BAOAB", "BAIAB"])
                fprintf("\\midrule\n");
                fprintf("%-5s", integrator.Value);
                for dt = integrator.Elements.group(@(e) e.dt)
                    measurables = this.selectElementGroups(dt.Elements.group(@(e) e.Measurable), ["Temperature", "ConfigurationalTemperature", "Energy", "ThermalPressure", "tau11", "tau22", "tau12"]);
                    fprintf(" & %s", Utility.Generic.num2str(dt.Value));
                    for measure = measurables
                        ns = measure.Elements.group(@(e) e.Ns);
                        measure.Elements = ns(end).Elements;
                        fprintf(" & %s", Utility.Generic.num2str(round(mean(measure.Elements.Data), 4)));
                    end
                    fprintf(" \\\\\n");
                end
            end
            fprintf("\\bottomrule\n");
        end
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/PlanarCouetteFlow/BulkSystemWithIsokineticSplitting_%s", plot.ID);
        end
    end
end