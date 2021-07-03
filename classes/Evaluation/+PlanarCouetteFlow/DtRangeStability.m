classdef DtRangeStability < Evaluation
    methods
        function this = DtRangeStability()
            this.bLoadAdvancedInfo = true;
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
                && model.Temperature == 1 ...
                && (thermostat.Class == "IsokineticThermostat" || thermostat.FrictionConstant == 1) ...
                && Utility.Generic.matchesAny(integrator.Class,  "BAOAB", "VVASLLOD", "ABOBA") ...
                && tracker.Interval.Gap > 0 ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature", "ThermalStressTensor", "Energy", "Temperature") ...
                && step == steps(end) ...
                && dt > 0.01 && dt < 0.03;
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
            for integrator = this.selectElementGroups(elements.group(@(e) e.Integrator), ["VVA", "ABOBA", "BAOAB", "BAIAB"])
                fprintf("\\midrule\n");
                fprintf("%-5s", integrator.Value);
                for dt = integrator.Elements.group(@(e) e.dt)
                    measurables = this.selectElementGroups(dt.Elements.group(@(e) e.Measurable), ["Temperature", "ConfigurationalTemperature", "Energy", "ThermalPressure", "tau11", "tau22", "tau12"]);
                    fprintf(" & %s", Utility.Generic.num2str(dt.Value));
                    for measure = measurables
                        stableIndices = abs(measure.Elements.Data) < 10^3;
                        fprintf(" & %s", Utility.Generic.num2str(round(mean(measure.Elements.Data(stableIndices)), 4)));
                    end
                    fprintf(" \\\\\n");
                end
            end
            fprintf("\\bottomrule\n");
            
            for dt = elements.sort(@(e) e.dt).group(@(e) e.dt)
                fprintf(" & %s", Utility.Generic.num2str(dt.Value));
            end
            fprintf("\\\\\n\\midrule\n");            
            for integrator = this.selectElementGroups(elements.group(@(e) e.Integrator), ["VVA", "ABOBA", "BAOAB", "BAIAB"])
                fprintf("%-5s", integrator.Value);
                for dt = integrator.Elements.sort(@(e) e.dt).group(@(e) e.dt)
                    measure = this.selectElementGroups(dt.Elements.group(@(e) e.Measurable), ["ThermalPressure"]);
                    stableCount = sum(abs(measure.Elements.Data) < 10^2);
                    fprintf(" & %s", Utility.Generic.num2str(stableCount));
                end
                fprintf(" \\\\\n");
            end
            fprintf("\\bottomrule\n");
        end
    end
end