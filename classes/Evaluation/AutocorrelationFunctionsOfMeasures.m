classdef AutocorrelationFunctionsOfMeasures < Evaluation
    properties
        NLags = 10000 % number of lags calculated for autocorrelation function
        START = 1 % start index of history
        SKIP = 1 % skip between history data
        LibraryDir = "PlanarCouetteFlow.history.mogonlib.N400.old"
    end
    methods
        function this = AutocorrelationFunctionsOfMeasures()
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
                b = step ==  Utility.Generic.selectClosestTo(500000,steps) ...
                    && dt == 0.01 ...
                    && tracker.Class == "History" ...
                    && model.Temperature == 1 ...
                    && model.ShearRate == 0 ...
                    && (thermostat.Class == "IsokineticThermostat" || (thermostat.Class == "LangevinThermostat" && thermostat.FrictionConstant == 1));
                return;
                b = Utility.Generic.matchesAny(integrator.Class, "VVASLLOD", "BAOAB", "ABOBA") ...
                    && dt == 0.01 ...
                    && model.Temperature == 1 ...
                    && model.ShearRate == 0 ...
                    && (thermostat.Class == "IsokineticThermostat" || thermostat.FrictionConstant == 1) ...
                    && Utility.Generic.matchesAny(measurable, "Energy", "Temperature", "ConfigurationalTemperature", "ThermalStressTensor") ...
                    && isequal(tracker.Class, "History") ...
                    && step == Utility.Generic.selectClosestTo(500000,steps);
                b = b || (Utility.Generic.matchesAny(integrator.Class, "VVASLLOD", "BAOAB", "ABOBA") ...
                    && dt == 0.01 ...
                    && model.Temperature == 1 ...
                    && model.ShearRate == 0.1 ...
                    && (thermostat.Class == "IsokineticThermostat" || thermostat.FrictionConstant == 1) ...
                    && Utility.Generic.matchesAny(measurable, "Energy", "Temperature", "ConfigurationalTemperature", "ThermalStressTensor") ...
                    && isequal(tracker.Class, "History") ...
                    && step == Utility.Generic.selectClosestTo(500000,steps));
                b = b || (Utility.Generic.matchesAny(integrator.Class, "VVASLLOD", "BAOAB", "ABOBA") ...
                    && dt == 0.01 ...
                    && model.Temperature == 1 ...
                    && model.ShearRate == 0.2 ...
                    && Utility.Generic.matchesAny(measurable, "Energy", "Temperature", "ConfigurationalTemperature", "ThermalStressTensor") ...
                    && isequal(tracker.Class, "History") ...
                    && step == Utility.Generic.selectClosestTo(500000,steps));
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
            if isempty(data); return; end
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
                elements = [entries];
            else
                elements.set("Data", data);
            end
                    
            for element = elements
                M = size(element.Data, 2);
                Data = gather(element.Data(this.START:this.SKIP:end, :));
                
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
                    nlags = 10000; % this is the nlags used to save the ACF, this.NLags is used for plotting
                    ACF=zeros(M,nlags+1);
                    bounds=zeros(M,2);
                    for k = 1:M
                        [ACF(k,:),LAGS,bounds(k,:)]=autocorr(Data(:,k),'NumLags',nlags,'NumSTD',1);
                    end
                    if ~isfolder(foutdir); mkdir(foutdir); end
                    save(fout, "ACF", "LAGS", "model", "integrator", "thermostat", "tracker", "measurable", "dt", "step", "runtimes", "ms", "-v7.3");
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
                            [measurables] = n.Elements.group(@(e) e.Measurable);
                            for measure = measurables
                                plot = this.getPlot(measure.Value);
                                plot.AxisProperties.XScale = "log";
                                plot.AxisProperties.YScale = "linear";
                                plot.AxisProperties.XLabel = "\delta t \cdot \tau";
                                plot.AxisProperties.Title = measure.Value;
                                
                                [integrators] = measure.Elements.group(@(e) e.Integrator);
                                for integrator = integrators
                                    [thermostats] = integrator.Elements.group(@(e) e.Thermostat);
                                    for thermostat = thermostats
                                        [dts] = thermostat.Elements.sort(@(e) e.dt).group(@(e) e.dt);
                                        for dt = dts(1:end)
                                            line = Evaluation.Line();
                                            line.Properties.DisplayName = sprintf("%s", integrator.Value);
                                            line.Properties.Color = Utility.Generic.select(integrator.Value, "VVA", [0.4940 0.1840 0.5560], "BAOAB", [0 0.4470 0.7410], "ABOBA", [0.8500 0.3250 0.0980], "BAIAB", [0.9290 0.6940 0.1250]);
                                            line.Properties.Marker = Utility.Generic.select(integrator.Value, "VVA", "d", "BAOAB", "o", "BAIAB", "x", "ABOBA", "s");
                                            line.Properties.MarkerSize = Utility.Generic.select(integrator.Value, "VVA", 8, "BAOAB", 5, "BAIAB", 10, "ABOBA", 10);
                                            %line.Properties.MarkerFaceColor = line.Properties.Color;
                                            x = [unique(round(logspace(0, 2, 15)))];
                                            line.addPoint(dt.Elements.Gap*x, mean(dt.Elements.ACF(:, x)));
                                            plot.addLine(line);
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        
        function value = accessMergedField(this, elements, field)
            value = elements(1).(field);
            for element = elements(2:end)
                value = cat(1, value, element.(field));
            end
        end
%         function filename = savePlot(this, plot)
%             filename = sprintf("../../../Ausarbeitung/figures/PlanarCouetteFlow/AutocorrelationFunctionsOfMeasures_%s", plot.ID);
%         end
    end
end

