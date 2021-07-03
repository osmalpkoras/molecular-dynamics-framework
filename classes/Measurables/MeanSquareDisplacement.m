% calculates the mean square displacement using unfolded positions
classdef MeanSquareDisplacement < Measurable
    properties
        TravelTimes
    end
    properties (Hidden)
        position
        Data
        TTIndexOffsets
    end
    methods        
        function this = MeanSquareDisplacement(travelTimes)
            this.TravelTimes = sort(travelTimes);
        end
        
        function this = initialize(this, tracker, simulation)
            this.initialize@Measurable(tracker, simulation);
            this.position = Position;
            this.position.unfold();
            this.position.initialize(tracker, simulation);
            tracker.from(max(this.TravelTimes(end), tracker.Interval.Start));
            this.TTIndexOffsets = unique(round(this.TravelTimes / simulation.dt)  - 1);
            this.Data.Position.Length = ceil(this.TravelTimes(end) / simulation.dt + 1);
            this.Data.Position.History = Numeral(zeros([this.Data.Position.Length size(this.position.measure(simulation))]));
            this.Data.Position.Index = 1;
        end
        
        function data = measure(this, simulation)
            ind = mod(this.Data.Position.Index + this.TTIndexOffsets, this.Data.Position.Length) + 1;
            data = this.Data.Position.History(ind, :, :, :) - this.Data.Position.History(this.Data.Position.Index, :, :, :);
            data = mean(mean(data(:,1,:,:).^2 + data(:,2,:,:).^2, 2), 3);
        end
        
        function data = format(this, data)
            if 2 == this.Dimension
            data = permute(data, [4 1 2 3]);
            end
        end
        
        function onTick(this, simulation)
            this.Data.Position.History(this.Data.Position.Index,:,:,:) = this.position.measure(simulation);
            this.Data.Position.Index = mod(this.Data.Position.Index, this.Data.Position.Length) + 1;
        end
        
        function plt = createPlotter(this, simulation, varargin)
            plt = ValuePlotter(this, 'log', this.TravelTimes, varargin{:});
        end
    end
end

