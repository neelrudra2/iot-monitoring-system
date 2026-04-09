%% Solar IoT Monitoring System Simulation
%% Simulates 24-hour operation of a solar + battery + load system

clear; clc;

%% System Parameters
panel_kWp = 1.0;          % 1 kWp solar panel
battery_capacity_Ah = 100; % 100 Ah battery
battery_voltage = 48;      % 48V system
battery_capacity_Wh = battery_capacity_Ah * battery_voltage; % 4800 Wh
initial_SOC = 0.50;        % Start at 50% charged

%% Time vector: 1440 minutes in a day (1 sample per minute)
t = 0:1439;  % minutes from midnight
hours = t / 60;

%% Simulate Solar Generation Profile (bell curve, peaks at noon)
% Panel output follows irradiance pattern
irradiance = zeros(1, 1440);
for i = 1:1440
    h = i/60;
    if h >= 6 && h <= 18  % Sunlight from 6am to 6pm
        irradiance(i) = 1000 * sin(pi * (h - 6) / 12);
    end
end
% Add cloud noise
noise = 50 * randn(1, 1440);
irradiance = max(irradiance + noise, 0);

% Panel power output
panel_power_W = panel_kWp * 1000 * (irradiance / 1000) * 0.80; % PR = 0.80

%% Simulate Load Profile
load_power_W = zeros(1, 1440);
for i = 1:1440
    h = i/60;
    if h >= 8 && h <= 18   % Working hours: 500W load
        load_power_W(i) = 500;
    elseif h >= 18 && h <= 22  % Evening: 200W (lights only)
        load_power_W(i) = 200;
    else                        % Night: 50W (minimal)
        load_power_W(i) = 50;
    end
end

%% Battery SOC Simulation using Coulomb Counting
SOC = zeros(1, 1440);
SOC(1) = initial_SOC;
dt_hours = 1/60;  % Each timestep = 1 minute = 1/60 hour

for i = 2:1440
    net_power_W = panel_power_W(i) - load_power_W(i);
    delta_Wh = net_power_W * dt_hours;
    delta_SOC = delta_Wh / battery_capacity_Wh;
    SOC(i) = SOC(i-1) + delta_SOC;
    SOC(i) = min(max(SOC(i), 0.0), 1.0);  % Clamp between 0 and 100%
end

%% Energy Calculations
total_generation_kWh = sum(panel_power_W) * dt_hours / 1000;
total_consumption_kWh = sum(load_power_W) * dt_hours / 1000;
net_energy_kWh = total_generation_kWh - total_consumption_kWh;
min_SOC = min(SOC) * 100;
max_SOC = max(SOC) * 100;

fprintf('--- DAILY ENERGY REPORT ---\n');
fprintf('Total Solar Generation : %.2f kWh\n', total_generation_kWh);
fprintf('Total Load Consumption : %.2f kWh\n', total_consumption_kWh);
fprintf('Net Energy Balance     : %.2f kWh\n', net_energy_kWh);
fprintf('Battery SOC Range      : %.1f%% to %.1f%%\n', min_SOC, max_SOC);

%% Plotting Dashboard
figure('Name', 'Solar IoT Monitoring Dashboard', 'Position', [100 100 1000 700]);

subplot(3,1,1);
plot(hours, panel_power_W, 'y', 'LineWidth', 1.5); hold on;
plot(hours, load_power_W, 'r', 'LineWidth', 1.5);
xlabel('Time of Day (hours)');
ylabel('Power (W)');
title('Solar Generation vs Load Consumption – 24 Hour Profile');
legend('Solar Generation', 'Load Demand');
xlim([0 24]); grid on;

subplot(3,1,2);
area(hours, panel_power_W, 'FaceColor', [1 0.8 0], 'FaceAlpha', 0.5); hold on;
area(hours, load_power_W, 'FaceColor', [1 0.3 0.3], 'FaceAlpha', 0.5);
xlabel('Time of Day (hours)');
ylabel('Power (W)');
title('Energy Area Plot – Generation (Yellow) vs Consumption (Red)');
xlim([0 24]); grid on;

subplot(3,1,3);
plot(hours, SOC * 100, 'b', 'LineWidth', 2);
yline(20, 'r--', 'Low SOC Warning (20%)');
yline(90, 'g--', 'Full Charge (90%)');
xlabel('Time of Day (hours)');
ylabel('State of Charge (%)');
title('Battery SOC Variation Throughout the Day');
xlim([0 24]); ylim([0 100]); grid on;