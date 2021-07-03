classdef ExtractAndCopyEvaluation < Parser

    methods
        function this = ExtractAndCopyEvaluation()            
            this.bMergeIndependentRuns = true;
            this.includeLibrary(Library("HarmonicOscillator.mogonlib")) ...
                .includeLibrary(Library("HarmonicOscillator.uncorrelated.mogonlib")) ...                
                .parseLibraries() ...
                .parseData();
        end
        
        
        function b = select(this, model, integrator, thermostat, tracker, measurable, dt, step, t, steps, times)
            b = Utility.Generic.matchesAny(tracker.Interval.Gap, 3.7) ...
                && isequal(thermostat.Class, "LangevinThermostat") ...
                && Utility.Generic.matchesAny(measurable, "ConfigurationalTemperature") ...
                && Utility.Generic.matchesAny(integrator.Class, "BAOAB", "ABOBA");
            if b && tracker.Interval.Gap > 0
                b = b && (((step / ceil(tracker.Interval.Gap / dt) + 1) == 10^6) ...
                    || ((step / ceil(tracker.Interval.Gap / dt) + 1) == 5*10^6));
            end
        end
        
        function elements = OnCreatingDataElements(this, data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms)
            elements = this.OnCreatingDataElements@Parser(data, model, integrator, thermostat, tracker, measurable, dt, step, runtimes, ms);            
            elements.set("Data", data);
            if tracker.Interval.Gap > 0
                elements.set("SampleSize", (step / ceil(tracker.Interval.Gap / dt) + 1));
            else
                elements.set("SampleSize", step);
            end
            elements.set("Gap", tracker.Interval.Gap);
%             if isequal(measurable, "ThermalStressTensor")
%                 data = (-data(:,:,1,1) - data(:,:,2,2)) / 2;
%                 measurable = "ThermalPressure";
%                 filename = this.getFileName(model.Class, model.N, measurable, integrator.Class, thermostat.Class, dt);
%                 dlmwrite(filename, data, '-append', 'delimiter', ' ', 'precision', 10);
%             else
%                 filename = this.getFileName(model.Class, model.N, measurable, integrator.Class, thermostat.Class, dt);
%                 dlmwrite(filename, data, '-append', 'delimiter', ' ', 'precision', 10);
%                 
%                 if isequal(measurable, "Energy")
%                     data = data ./ model.N;
%                     measurable = "EnergyPerParticle";
%                     filename = this.getFileName(model.Class, model.N, measurable, integrator.Class, thermostat.Class, dt);
%                     dlmwrite(filename, data, '-append', 'delimiter', ' ', 'precision', 10);                    
%                 end
%             end
        end
        
        function filename = getFileName(this, model, N, measurable, integrator, thermostat, dt)
            thermostat = extractBefore(thermostat, "Thermostat");
            filename = sprintf("%s_N%s_%s_%s_%s_dt%s.dat", model, num2str(N), measurable, integrator, thermostat, num2str(dt));
        end
        
        function OnProccessingDataElements(this, elements)
            for integrator = elements.group(@(e) e.Integrator)
                for gap = integrator.Elements.group(@(e) e.Gap)
                    for sampleSize = gap.Elements.group(@(e) e.SampleSize)
                        for dt = sampleSize.Elements.group(@(e) e.dt)
                            filename = sprintf("Leonid/%s_dt%s_Ns%s.dat", integrator.Value, num2str(dt.Value), num2str(dt.Elements.SampleSize));
                            dlmwrite(filename, dt.Elements.Data(1:20000), '-append', 'delimiter', ' ', 'precision', 10);
                        end
                    end
                end
            end
        end
    end
end