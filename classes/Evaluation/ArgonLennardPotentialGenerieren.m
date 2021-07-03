
FontSize = 16;
LineWidth = 1.75;
MarkerSize = 10;
TickLength = [0.03 0.03];
            
lennard = @(epsi, sigma, r) (4*epsi * ( (sigma./r).^12 - (sigma./r).^6));
x = [2 2.2 2.4 2.6 2.8 3 3.2 3.4 3.5 3.6 3.65 3.7 3.75 3.8 3.85 3.9 4 4.2 4.4 4.6 4.8 5 5.3 5.6 6 6.5 7 8 10 12 14 16 20];
argon = [35718.05 17882.56 8619.02 3961.36 1694.56 633.868 163.942 -26.074 -67.661 -89.306 -95.001 -98.108 -99.291 -98.953 -97.454 -95.084 -88.726 -73.024 -57.836 -45.031 -34.847 -26.980 -18.538 -12.970 -8.281 -4.938 -3.0759 -1.3260 -0.3321 -0.10881 -0.04267 -0.01898 -0.00491];
fig = figure;
set(fig, 'DefaultAxesFontSize', FontSize);
set(fig, 'DefaultTextFontSize', FontSize);
set(fig, 'DefaultLineLineWidth', LineWidth);
set(fig, 'DefaultLineMarkerSize', MarkerSize);
set(fig, 'DefaultAxesTickLength', TickLength);
ax = axes('parent', fig);
plot(ax, x, argon, x, lennard(99, 3.35, x), "--"); 
ylim([-150 150]); 
xlim([3 8]);
legend("Argon", "Lennard-Jones");