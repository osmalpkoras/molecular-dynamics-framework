classdef Debug < handle
    methods (Static)
        function log(varargin)
            if Globals.VerbosityLevel >= 2
                t = clock;
                varargin{1} = sprintf('[%02d:%02d] %s\n', t(end-2), t(end-1), varargin{1});
                fprintf(varargin{:});
            end
        end
        
        function plotParticles(q, figname)
            if ~exist('figname', 'var'); figname = ''; end
            persistent FIGURES;
            persistent AXES;
            persistent PLOTS;
            if isempty(FIGURES)
                FIGURES = containers.Map;
                AXES = containers.Map;
                PLOTS = containers.Map;
            end
            if ~isKey(FIGURES, figname) || ~ishandle(FIGURES(figname))
                FIGURES(figname) = figure("Name", figname);                
                AXES(figname) = axes('parent', FIGURES(figname));
                PLOTS(figname) = scatter(AXES(figname), q(1,:,:), q(2,:,:), 'filled');
            end
            phandle = PLOTS(figname);
            phandle.XData = q(1,:,:);
            phandle.YData = q(2,:,:);
            drawnow;
        end
    end
end

