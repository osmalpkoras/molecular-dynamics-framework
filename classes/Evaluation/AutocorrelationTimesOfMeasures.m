classdef AutocorrelationTimesOfMeasures < Evaluation
    properties
        NLags = 10000 % number of lags calculated for autocorrelation function
        START = 1 % start index of history
        SKIP = 1 % skip between history data
        LibraryDir = "cpu.PlanarCouetteFlow.history.mogonlib"
    end
    methods
        function this = AutocorrelationTimesOfMeasures()
            this.Defaults.AxesFontSize = 12;
            this.Defaults.TextFontSize = 12;
            this.Defaults.LineLineWidth = 1.5;
            this.Defaults.LineMarkerSize = 10;
            this.Defaults.AxesTickLength = [0.02 0.025];
            this.bMergeIndependentRuns = true;
            
            this.includeLibrary(Library(this.LibraryDir)) ...
                .parseLibraries() ...
                .parseData();
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            if model.Class == "PlanarCouetteFlow"
                b = Utility.Generic.matchesAny(integrator.Class, "BAOAB") ...
                    && dt == 0.01 ...
                    && model.Temperature == 1 ...
                    && model.ShearRate == 0 ...
                    && (thermostat.Class == "LangevinThermostat" && thermostat.FrictionConstant == 1) ...
                    && Utility.Generic.matchesAny(measurable, "Energy", "Temperature", "ConfigurationalTemperature", "ThermalStressTensor") ...
                    && isequal(tracker.Class, "History") ...
                    && step == Utility.Generic.selectClosestTo(500000,steps);
                return;
                b = Utility.Generic.matchesAny(integrator.Class, "VVASLLOD", "BAOAB", "ABOBA") ...
                    && dt == 0.01 ...
                    && model.Temperature == 1 ...
                    && model.ShearRate == 0 ...
                    && (thermostat.Class == "IsokineticThermostat" || thermostat.FrictionConstant == 1) ...
                    && Utility.Generic.matchesAny(measurable, "Energy", "Temperature", "ConfigurationalTemperature", "ThermalStressTensor") ...
                    && isequal(tracker.Class, "History") ...
                    && step == Utility.Generic.selectClosestTo(500000,steps);
                b = (Utility.Generic.matchesAny(integrator.Class, "VVASLLOD", "BAOAB", "ABOBA") ...
                    && dt == 0.01 ...
                    && model.Temperature == 1 ...
                    && model.ShearRate == 0.1 ...
                    && (thermostat.Class == "IsokineticThermostat" || thermostat.FrictionConstant == 1) ...
                    && Utility.Generic.matchesAny(measurable, "Energy", "Temperature", "ConfigurationalTemperature", "ThermalStressTensor") ...
                    && isequal(tracker.Class, "History") ...
                    && step == Utility.Generic.selectClosestTo(500000,steps));
                b = (Utility.Generic.matchesAny(integrator.Class, "VVASLLOD", "BAOAB", "ABOBA") ...
                    && dt == 0.01 ...
                    && model.Temperature == 1 ...
                    && model.ShearRate == 0.2 ...
                    && Utility.Generic.matchesAny(measurable, "Energy", "Temperature", "ConfigurationalTemperature", "ThermalStressTensor") ...
                    && isequal(tracker.Class, "History") ...
                    && step == Utility.Generic.selectClosestTo(500000,steps));
                return;
            elseif model.Class == "HarmonicOscillator"
                b = Utility.Generic.matchesAny(integrator.Class, "BAOAB", "ABOBA") ...
                    && dt == 0.1 ...
                    && model.Temperature == 1 ...
                    && thermostat.FrictionConstant == 1 ...
                    && Utility.Generic.matchesAny(measurable, "Energy", "Temperature", "ConfigurationalTemperature") ...
                    && isequal(tracker.Class, "History") ...
                    && step == Utility.Generic.selectClosestTo(500000,steps);
            end
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Parser(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);
            
            if isequal(measurable, "ThermalStressTensor")
                entries(1) = copy(elements);
                entries(1).set("Data", data(:,:,1,1));
                entries(1).set("Measurable", "tau11");
                
                entries(2) = copy(elements);
                entries(2).set("Data", data(:,:,2,2));
                entries(2).set("Measurable", "tau22");
                
                entries(3) = copy(elements);
                entries(3).set("Data", data(:,:,1,2));
                entries(3).set("Measurable", "tau12");   
                
                elements.set("Data", (-data(:,:,1,1) - data(:,:,2,2)) / 2);
                elements.set("Measurable", "ThermalPressure");
                elements = [elements entries];
            else
                elements.set("Data", data);
            end
                    
            for element = elements
                M = size(element.Data, 2);
                Data = element.Data(this.START:this.SKIP:end, :);
                
                element.set("M", M);
                element.set("N", model.N);
                element.set("Ns", size(Data, 1));
                element.set("Temperature", model.Temperature);
                element.set("Gap", max(dt, tracker.Interval.Gap));    
                if isfield(thermostat, "FrictionConstant")
                    element.set("FrictionConstant", thermostat.FrictionConstant);
                else
                    element.set("FrictionConstant", 1);
                end
                if isfield(model, "ShearRate")
                    element.set("ShearRate", model.ShearRate);
                else
                    element.set("ShearRate", 0);
                end
                
                if model.Class == "PlanarCouetteFlow"
                    foutdir = sprintf("autocorrelationfunctions/%s/%s/%s.%s/N_%s/Temperature_%s/ShearRate_%s/FrictionConstant_%s", ...
                        this.LibraryDir, model.Class, element.Integrator, element.Thermostat, num2str(element.N), num2str(element.Temperature), num2str(element.ShearRate), num2str(element.FrictionConstant));
                else
                    foutdir = sprintf("autocorrelationfunctions/%s/%s/%s.%s/N_%s/Temperature_%s/FrictionConstant_%s", ...
                        this.LibraryDir, model.Class, element.Integrator, element.Thermostat, num2str(element.N), num2str(element.Temperature), num2str(element.FrictionConstant));
                end
                fout = sprintf("%s/%s_M_%s_dt_%s_START_%s_SKIP_%s_Ns_%s.mat", foutdir, element.Measurable, num2str(element.M), num2str(dt), num2str(this.START), num2str(this.SKIP), num2str(element.Ns));

                %% calculate and save relevant variables or load from save file
                if ~isfile(fout)
                    error("Please generate the autocorrelation function first by using AutocorrelationFunctionsOfMeasures.");
                else
                    load(fout, "ACF");
                end
                element.set("ACF", ACF);
                element.set("Length", size(element.Data, 1));
                element.set("Means", mean(element.Data, 1));
                element.set("SkippedLength", size(Data, 1));
                element.set("SkippedMeans", mean(Data, 1));
                element.set("SkippedVariances", var(Data, 1));
                element.Data = [];
                element.set("tau_x", 0);
            end
        end
        
        function OnProccessingDataElements(this, elements)
            shearRates = elements.group(@(e) e.ShearRate);
            for shearRate = shearRates
                temperatures = shearRate.Elements.group(@(e) e.Temperature);
                for temperature = temperatures
                    frictionConstants = temperature.Elements.group(@(e) e.FrictionConstant);
                    for frictionConstant = frictionConstants
                        ns = frictionConstant.Elements.group(@(e) e.N);
                        for n = ns
                            fprintf("[N] %3s   [Scherrate] %3s    [Temperatur] %4s    [Reibungskonstante] %3s\n", num2str(n.Value), num2str(shearRate.Value), num2str(temperature.Value), num2str(frictionConstant.Value));

                            [measurables] = n.Elements.group(@(e) e.Measurable);
                            for measure = measurables
                                fprintf("\t[%s]\n",  measure.Value);
                                [integrators] = measure.Elements.group(@(e) e.Integrator);
                                for integrator = integrators
                                    [thermostats] = integrator.Elements.group(@(e) e.Thermostat);
                                    for thermostat = thermostats
                                        fprintf("\t\t%s [%s]\n",  integrator.Value, thermostat.Value);
                                        [dts] = thermostat.Elements.sort(@(e) e.dt).group(@(e) e.dt);
                                        for dt = dts(1:end)
                                            fprintf("\t\t\tdt: %s    (gemessen im Zeitabstand: %s)    [N_S] %9s    [M] %3s\n", Utility.Generic.num2str(dt.Value), Utility.Generic.num2str(dt.Elements.Gap),  Utility.Generic.num2str(dt.Elements.Ns(1)), Utility.Generic.num2str(dt.Elements.M));

                                            acf = mean(dt.Elements.ACF, 1);                                        
                                            variance = mean(dt.Elements.SkippedVariances);
                                            indices = 1:this.NLags;
                                            taus = dt.Elements.Gap * cumtrapz(acf(indices));
                                            tau = max(taus);
                                            s = tau / dt.Elements.Gap  * 2;
                                            dt.Elements.tau_x = tau;
                                            fprintf("\t\t\t\tAutokorrelationszeit:    %s\n", Utility.Generic.num2str(tau));
                                            fprintf("\t\t\t\tStatistische Ineffizienz:    %s\n", Utility.Generic.num2str(s));
                                            STD = sqrt(variance / dt.Elements.SkippedLength);
                                            correctedSTD = sqrt(variance * s / dt.Elements.SkippedLength);
                                            fprintf("\t\t\t\tStochastischer Fehler des Mittelwertes:    %s bzw. %s%%\n", Utility.Generic.num2str(STD), Utility.Generic.num2str(mean(STD./dt.Elements.SkippedMeans*100)));
                                            fprintf("\t\t\t\tBereinigter stochastischer Fehler des Mittelwertes:    %s bzw. %s%%\n", Utility.Generic.num2str(correctedSTD), Utility.Generic.num2str(mean(correctedSTD./dt.Elements.SkippedMeans*100)));
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            for integrator = elements.group(@(e) e.Integrator)
                for thermostat = integrator.Elements.group(@(e) e.Thermostat)
                    fprintf("%s %s", integrator.Value, thermostat.Value);
                    for frictionConstant = thermostat.Elements.sort(@(e) e.FrictionConstant).group(@(e) e.FrictionConstant)
                        fprintf(" & %s", Utility.Generic.num2str(frictionConstant.Value));
                        for measure = this.selectElementGroups(frictionConstant.Elements.group(@(e) e.Measurable), ["Temperature", "ConfigurationalTemperature", "Energy", "ThermalPressure", "tau11", "tau22", "tau12"])
                            fprintf(" & %s", Utility.Generic.num2str(round(measure.Elements.tau_x, 4)));
                        end
                    fprintf("\\\\\n");
                    end
                end
            end
        end
        
%         function filename = savePlot(this, plot)
%             filename = sprintf("../../../Ausarbeitung/figures/PlanarCouetteFlow/AutocorrelationFunctionsOfMeasures_%s", plot.ID);
%         end
    end
end

