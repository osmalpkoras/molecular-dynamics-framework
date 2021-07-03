classdef SystemsOfDifferentSizeComparison < Evaluation    
    methods
        function this = SystemsOfDifferentSizeComparison()
            this.bLoadAdvancedInfo = true;
            this.Defaults.AxesFontSize = 16;
            this.Defaults.TextFontSize = 16;
            this.Defaults.LineLineWidth = 1.75;
            this.Defaults.LineMarkerSize = 10;
            this.Defaults.AxesTickLength = [0.03 0.03];
            
            this.includeLibrary(Library("export/PlanarCouetteFlow.local")) ...     
                .includeLibrary(Library("export/cpu.PlanarCouetteFlow.mogonlib")) ...     
                .parseLibraries() ...
                .parseData();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = model.Temperature == 1 ...
                && Utility.Generic.matchesAny(integrator.Class,  "BAOAB", "VVASLLOD") ...
                && ~(integrator.Class == "BAOAB" && thermostat.Class == "IsokineticThermostat") ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature", "ThermalStressTensor", "Energy", "Temperature") ...
                && Utility.Generic.matchesAny(dt, 0.001, 0.0025, 0.005, 0.01) ...
                && model.ShearRate == 0 ...
                && (step / ceil(tracker.Interval.Gap / dt) + 1) == 10^4; ... this expression evaluate to the sample size
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Evaluation(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            
            elements.set("Gap", max(dt, tracker.Interval.Gap));
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
            elseif isequal(measurable, "Energy")
                energyperparticle = copy(elements);
                energyperparticle.set("Data",  data / model.N);
                energyperparticle.set("Measurable", "EnergyPerParticle");
                
                elements.set("Data",  data);                
                elements = [elements energyperparticle];
            else
                elements.set("Data", data);
            end
        end
        
        function OnProccessingDataElements(this, elements)
            
            this.Defaults.AxesFontSize = 16;
            this.Defaults.TextFontSize = 16;
            this.Defaults.LineLineWidth = 1.75;
            this.Defaults.LineMarkerSize = 10;
            this.Defaults.AxesTickLength = [0.03 0.03];
            
            [measurables] = elements.group(@(e) e.Measurable);
            for measure = measurables
                plot = this.getPlot(measure.Value);
                [integrators]= measure.Elements.group(@(e) e.Integrator);
                for integrator = integrators
                    [thermostats] = integrator.Elements.group(@(e) e.Thermostat);
                    for thermostat = thermostats
                        plot.AxisProperties.XScale = "linear";
                        plot.AxisProperties.YScale = "linear";
                        plot.AxisProperties.XLabel = "{\Delta}t";
                        
                        ns = thermostat.Elements.group(@(e) e.N);
                        for n = ns
                            line = Evaluation.Line();
                            line.Properties.DisplayName = sprintf("%s", integrator.Value);
                            line.ShowInLegend = n.Value == 100;
                            line.Properties.LineStyle = Utility.Generic.select(n.Value, 400, "--", 100, "-");
                            line.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980]);
                            line.Properties.Marker = Utility.Generic.select(integrator.Value, "VVA", "d", "BAOAB", "o", "ABOBA", "s");
                            
                            dts = n.Elements.sort(@(e) e.dt).group(@(e) e.dt);
                            for dt = dts(1:end)
                                fprintf("[%-26s] %-10s N %s [N_S] %-10s [M] %-7s [dt] %-7s [Gap] %-7s [Temperature] %-7s [ShearRate] %-7s [FrictionConstant] %-7s\n" , ...
                                    measure.Value, integrator.Value, num2str(n.Value), num2str(dt.Elements.Ns), num2str(dt.Elements.M), num2str(dt.Value), num2str(dt.Elements.Gap), num2str(1), num2str(0), num2str(1));
                                maxs = min(10^4, size(dt.Elements.Data, 1));
                                line.addPoint(dt.Value, mean(dt.Elements.Data(1:maxs, :, :)));
                            end
                            plot.addLine(line);
                        end
                    end
                end                
                plot.addAnnotationToLegend("N = 100", "-", [0.5 0.5 0.5]);
                plot.addAnnotationToLegend("N = 400", "--", [0.5 0.5 0.5]);
            end
        end
        
        function filename = savePlot(this, plot)
            filename = sprintf("figures/PlanarCouetteFlow/SystemsOfDifferentSizeComparison_%s", plot.ID);
        end
    end
end