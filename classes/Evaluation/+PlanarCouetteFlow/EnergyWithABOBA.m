classdef EnergyWithABOBA < Evaluation    
    methods
        function this = EnergyWithABOBA()
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
                && Utility.Generic.matchesAny(dt, 0.00625, 0.008, 0.005, 0.01) ...
                && integrator.Class == "ABOBA" ...
                && thermostat.FrictionConstant == 1 ...
                && tracker.Interval.Gap > 0 ...
                && measurable == "Energy" ...
                && Utility.Generic.matchesAny(round(step / ceil(tracker.Interval.Gap / dt), 0), 2.5*10^4, 5*10^4, 7.5 * 10^4, 10^5);
            b = b || ...
                (model.ShearRate == 0 ...
                && model.Temperature == 1 ...
                && dt == 0.001 ...
                && integrator.Class == "ABOBA" ...
                && thermostat.FrictionConstant == 1 ...
                && tracker.Interval.Gap > 0 ...
                && measurable == "Energy" ...
                && step == steps(end));
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Evaluation(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            
            elements.set("Gap", tracker.Interval.Gap);
            elements.set("M", size(data, 1));
            elements.set("N", model.N);
            elements.set("Ns", (step / ceil(tracker.Interval.Gap / dt) + 1));
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
            [measurables] = elements.group(@(e) e.Measurable);
            for measure = measurables                
                [integrators]= measure.Elements.group(@(e) e.Integrator);
                for integrator = integrators
                    [thermostats] = integrator.Elements.group(@(e) e.Thermostat);
                    for thermostat = thermostats
                        errorPlot = this.getPlot(sprintf("Error_%s", measure.Value));
                        errorPlot.AxisProperties.XScale = "log";
                        errorPlot.AxisProperties.YScale = "log";
                        errorPlot.AxisProperties.XLabel = "{\Delta}t";
                        
                        dts = thermostat.Elements.sort(@(e) e.dt).group(@(e) e.dt);
                        reference = mean(dts(1).Elements.Data);
                        ns = thermostat.Elements.filter(@(e) e.dt ~= 0.001).group(@(e) e.Ns)
                        for n = ns([2 4])
                            errorLine = Evaluation.Line();
                            errorLine.Properties.DisplayName = sprintf("%s", integrator.Value);
                            errorLine.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980]);
                            errorLine.Properties.Marker = Utility.Generic.select(integrator.Value, "VVA", "d", "BAOAB", "o", "ABOBA", "s");
                            
                            if Utility.Generic.selectClosestTo(n.Value, [5*10^4, 10^5]) ~= 10^5
                                errorLine.ShowInLegend = false;
                                errorLine.Properties.LineStyle = "--";
                            end
                            
                            for dt = n.Elements.sort(@(e) e.dt).group(@(e) e.dt)
                                errorLine.addPoint(dt.Value, mean(abs(reference - dt.Elements.Data)));
                            end
                            errorPlot.addLine(errorLine);
                        end
                        
                        errorPlot.addAnnotationToLegend("N_{{\delta}t} = 50000", "--", [0.5 0.5 0.5]);
                        errorPlot.addAnnotationToLegend("N_{{\delta}t} = 100000", "-", [0.5 0.5 0.5]);
                    end
                end
            end
        end
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/PlanarCouetteFlow/EnergyWithABOBA_%s", plot.ID);
        end
    end
end