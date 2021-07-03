classdef GenerateDataFromTrajectories < Parser
    properties
        qTrackers
        pTrackers
    end
    methods
        function this = GenerateDataFromTrajectories()
            this.parse(Library("PlanarCouetteFlow.trajectory.mogonlib"));
        end
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = model.Temperature == 1 ...
                && Utility.Generic.matchesAny(integrator.Class, "BAOAB") ...
                && Utility.Generic.matchesAny(measurable, "Position", "Impulse") ...
                && steps(end) == step;
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step)
            elements = this.OnCreatingDataElements@Parser(data, model, integrator, thermostat, tracker, measurable, dt, step);
            elements.set("Data", data);
            elements.set("Gap", tracker.Interval.Gap);
        end
        
        function OnProccessingDataElements(this, elements)
            [integrators] = elements.group(@(e) e.Integrator);
            for integrator = integrators
                [thermostats] = integrator.Elements.group(@(e) e.Thermostat);
                for thermostat = thermostats
                    [dts] = thermostat.Elements.group(@(e) e.dt);
                    for dt = dts
                        this.qTrackers = [dt.Elements.filter(@(e) e.Measurable == "Position").Data.Tracker];
                        this.pTrackers = [dt.Elements.filter(@(e) e.Measurable == "Impulse").Data.Tracker];
                        
                        s = min([this.qTrackers.TotalLength]);
                        
                        Options.usingGpuComputation(true);
                        
                        simulation = CachedSimulation((1:s)* dt.Elements(1).Gap, @(i) this.getQ(i), @(i) this.getP(i));
                        model = PlanarCouetteFlow(sum([dt.Elements(1).Data.M])).set("N", 400, "Density", 0.8, "Temperature", 1, "ShearRate", 0);
                        model.Potential = WCAPotential().set('CutOffRadius', 2^(1/6));
                        thermostat = LangevinThermostat();
                        thermostat.Parameter.FrictionConstant = 1;
                        simulation.setup(model, BAOAB, thermostat, dt.Value);
                            
                        NAMINGCONVENTION = "{Model.Class}/{Integrator.Class}.{Thermostat.Class}/Temperature_{Model.Temperature}/ShearRate_{Model.ShearRate}/dt_{dt}";
                        SAVEDIR = "PlanarCouetteFlow.local.mogonlib";
                        TRACKERS = { ...
                            History(Temperature).skip(dt.Elements(1).Gap) ...
                            Average(Temperature).skip(dt.Elements(1).Gap) ...
                            History(ConfigurationalTemperature).skip(dt.Elements(1).Gap) ...
                            Average(ConfigurationalTemperature).skip(dt.Elements(1).Gap) ...
                            History(ThermalPressure).skip(dt.Elements(1).Gap) ...
                            Average(ThermalPressure).skip(dt.Elements(1).Gap) ...
                            History(ThermalStressTensor).skip(dt.Elements(1).Gap) ...
                            Average(ThermalStressTensor).skip(dt.Elements(1).Gap) ...
                            History(Energy).skip(dt.Elements(1).Gap)...
                            Average(Energy).skip(dt.Elements(1).Gap)...
                            };
                        for i = 1:length(TRACKERS)
                            if isa(TRACKERS{i}, "History")
                                TRACKERS{i}.dir(sprintf("%s/Histories", SAVEDIR));
%                             else
%                                 TRACKERS{i}.plot;
                            end
                            simulation.track(TRACKERS{i});
                        end
                        
                        simulation.until(TimeLimit(Inf)) ...
                            .run();
                        
                        library = Library("PlanarCouetteFlow.local.2.mogonlib");
                        library.open();
                        library.add(simulation.toSimulation("simul_1"), NAMINGCONVENTION);
                        library.close();
                    end
                end
            end
        end
        
        function data = getDataFromTracker(this, library, entry, stepEntry, simulationName, index)
            s = stepEntry.load(library, entry, simulationName);
            data = struct();
            data.Tracker = struct();
            data.Tracker.Matfile = matfile(s.Trackers{index}.filepath, "Writable", false);
            data.Tracker.Buffer = gather(s.Trackers{index}.Buffer);
            data.Tracker.SubIndices = s.Trackers{index}.File.SubIndices;
            data.Tracker.HistoryLength = gather(s.Trackers{index}.HistoryLength);
            data.Tracker.TotalLength = gather(s.Trackers{index}.TotalLength);
            data.Tracker.BufferIndex = gather(s.Trackers{index}.BufferIndex);
            data.M = gather(s.Model.M);
        end
        
        function data = loadDataForTracker(this, tracker)
            data = struct("Tracker", {}, "M", {});
            for i = 1:length(tracker.loadData)
                data(end+1) = tracker.loadData{i}();
            end
        end
        
        function q = getQ(this, index)
            q = double.empty();
            for tracker = this.qTrackers
                q = cat(2, q, GenerateDataFromTrajectories.getTrackerDataAt(tracker, index));
            end
        end
        function p = getP(this, index)
            p = double.empty();
            for tracker = this.pTrackers
                p = cat(2, p, GenerateDataFromTrajectories.getTrackerDataAt(tracker, index));
            end
        end
    end
    
    methods (Static)
        function v = getTrackerDataAt(tracker, index)
            v = [];
            if 1 <= index && index <= tracker.HistoryLength
                v = eval(sprintf("tracker.Matfile.Data(index%s);", tracker.SubIndices));
            elseif index <= tracker.HistoryLength + tracker.BufferIndex - 1
                v = eval(sprintf("tracker.Buffer(index-tracker.HistoryLength%s);", tracker.SubIndices));
            end
        end
    end
end