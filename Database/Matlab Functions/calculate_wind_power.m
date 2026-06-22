%Column   #1            #2              #3                  #4              #5
%Data     Farm Number   Turbine Model   Turbine Capacity    Farm Capacity   Turbine Height
%Column   #6                  #7                 #8
%Data     cut-in speed (m/s)  rated speed (m/s)  cut-out speed (m/s)
%Column   #9               #10              #11              #12
%Data     x^3 coefficient  x^2 coefficient  x^1 coefficient  x^0 coefficient

function [wind_power_output, on_off_shore] = calculate_wind_power(hourly_onshore_wind, hourly_offshore_wind, Scaler_RESs)

turbine_data = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/wind_turbine_parameters.csv');
on_off_shore = turbine_data(:,13);

alpha_all = [0.2,0.1]; %From https://csl.noaa.gov/projects/lamar/windshearformula.html
farm_efficiency = 0.9; %Assumes a 90% farm efficiency compared to individual turbines

adjusted_wind_speed=zeros(length(hourly_onshore_wind), size(turbine_data, 1));
wind_power_output=zeros(length(hourly_onshore_wind), size(turbine_data, 1));


for c=1:size(turbine_data, 1)

    if turbine_data(c,13)==1
        
        wind_data=hourly_offshore_wind;
        alpha=alpha_all(2);

    elseif turbine_data(c,13)==0
        
        wind_data=hourly_onshore_wind;
        alpha=alpha_all(1);

    end

    
    for t=1:length(wind_data)
        
        adjusted_wind_speed(t,c) = wind_data(t) * ((turbine_data(c, 5)/10)^alpha); %Adjusts the wind speed from 10m to the rotor height of the turbine.

        %This if statement is for individual turbine power output
        if adjusted_wind_speed(t,c) < turbine_data(c, 6) %if less than cut-in speed

            wind_power_output(t,c)=0;

        elseif adjusted_wind_speed(t,c) < turbine_data(c,7) %if less than rated speed but greater than cut-in speed

            wind_power_output(t,c) = turbine_data(c,9)*(adjusted_wind_speed(t,c)^3) + turbine_data(c,10)*(adjusted_wind_speed(t,c)^2) + turbine_data(c,11)*(adjusted_wind_speed(t,c)^1) + turbine_data(c,12)*(adjusted_wind_speed(t,c)^0);

        elseif adjusted_wind_speed(t,c) < turbine_data(c, 8) %if less than cut-out speed but greater than rated speed

            wind_power_output(t,c) = turbine_data(c,3);

        else %if greater than rated speed
            
            wind_power_output(t,c) = 0;

        end


        wind_power_output(t,c)=wind_power_output(t,c) * (turbine_data(c,4)/turbine_data(c,3)) * farm_efficiency*Scaler_RESs(c)/1000; %Turbine Output * (Farm Capacity/Turbine Capacity) * Farm Efficiency * User Input Scaling Factor / 1000
        %/1000 to convert from kW (as in the input file) to MW

    end

end