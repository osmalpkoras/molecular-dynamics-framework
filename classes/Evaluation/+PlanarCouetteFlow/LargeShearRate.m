classdef LargeShearRate < Evaluation
    methods
        function this = LargeShearRate()
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
            b = model.ShearRate == 2 ...
                && model.Temperature == 1 ...
                && Utility.Generic.matchesAny(integrator.Class,  "BAOAB", "VVASLLOD", "ABOBA") ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature", "ThermalStressTensor", "Energy", "Temperature") ...
                && step == Utility.Generic.selectClosestTo(500000,steps);
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Evaluation(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            
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
            for measurable = elements.group(@(e) e.Measurable)
                fprintf("%s\n", measurable.Value);
                for shearRate = measurable.Elements.group(@(e) e.ShearRate)
                    for integrator = shearRate.Elements.group(@(e) e.Integrator)
                        fprintf("%s", integrator.Value);
                        for frictionConstant = integrator.Elements.sort(@(e) e.FrictionConstant).group(@(e) e.FrictionConstant)
                            stableCount = sum(abs(frictionConstant.Elements.Data) < 10^5);
                            fprintf(" & %s", Utility.Generic.num2str(stableCount));
                        end
                        fprintf("\n");
                    end
                end
            end
        end
    end
end