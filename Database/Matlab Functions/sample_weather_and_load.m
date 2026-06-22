%This function is used to sample temperature from historical data based on
%the provided dispatch dates.


function [hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, hourly_load, hourly_turbine_SD, weather_year] = sample_weather_and_load(Date_Dispatch)
addpath(genpath('/home/ifrost/cantor39/ELCC Work/YALMIP-master/YALMIP-master'));
addpath(genpath('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Yearly_Forcasted_PJM_Load_Data/combined_hourly_forecast'));

Num_Hour = 24*length(Date_Dispatch);
operating_year = year(Date_Dispatch(1)); %This assumes that every day within Date_Dispatch is in the same year. 
operating_month = month(Date_Dispatch(1));
start_date = day(Date_Dispatch(1));

%These lines are used to randomly select forecasted load from the PJM data
operating_year_text = num2str(operating_year);
all_PJM_forecasted_load_data = readmatrix(strcat('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Yearly_Forcasted_PJM_Load_Data/combined_hourly_forecast/Combined_Hourly_Forecast_', operating_year_text, '.csv'));
weather_year_column = randi([1,403])+6; %+6 to adjust for the first 6 columns of non-data
weather_year = mod((weather_year_column-7), 31) + 1993; %Historical data starts in 1993
sampled_forceasted_load_data = zeros(Num_Hour, 1);

month_match = all_PJM_forecasted_load_data(:,3) == operating_month;
day_match = all_PJM_forecasted_load_data(:,4) == start_date;
hour_match = all_PJM_forecasted_load_data(:,5) == 0;
start_row = find(month_match & day_match & hour_match);

for t = 1:Num_Hour
    sampled_forceasted_load_data(t) = all_PJM_forecasted_load_data(start_row + t-1, weather_year_column);
end

%These lines are used to extract the weather data only for the hours of
%interest

%Wind data from https://wrdb.nrel.gov/data-viewer
all_historic_weather_data = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Combined_Weather_Data.csv');
monthly_temp_adj = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Temp_Yearly_Change.csv');

hourly_temp=zeros(Num_Hour, 1);
hourly_irr=zeros(Num_Hour, 1);
hourly_onshore_wind=zeros(Num_Hour, 1);
hourly_offshore_wind=zeros(Num_Hour, 1);

year_match = all_historic_weather_data(:,2) == weather_year;
month_match = all_historic_weather_data(:,3) == operating_month;
day_match = all_historic_weather_data(:,4) == start_date;
hour_match = all_historic_weather_data(:,5) == 0;
start_row = find(year_match & month_match & day_match & hour_match);

for t = 1:Num_Hour
    hourly_temp(t) = all_historic_weather_data(start_row + t-1, 6) + (operating_year-weather_year)*monthly_temp_adj(operating_month,2); %Historic temperature + year difference*yearly temperature change
    hourly_irr(t) = all_historic_weather_data(start_row + t-1, 7);
    hourly_onshore_wind(t) = all_historic_weather_data(start_row + t-1, 8); %Wind speed at 10m
    hourly_offshore_wind(t) = all_historic_weather_data(start_row + t-1, 9); %Wind speed at 10m
end



%Calculate hourly hurricane impacts on turbines

%Column #1     #2          #3            #4            
%Data   Month  Hurr Count  Avg Hurr Dur  STD of Hurr Dur
%Duration
hurricane_data = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/NJ_Hurricane_Data.csv'); %From https://coast.noaa.gov/hurricanes/

hourly_hurricane=zeros(Num_Hour,1);
hourly_turbine_SD=zeros(Num_Hour,1);

monthly_hour_count = [1,744; 2,672; 3, 744; 4,720; 5,744; 6, 720; 7, 744; 8, 744; 9, 720; 10, 744; 11, 720; 12, 744];


hourly_prob_of_hurricane = (hurricane_data(operating_month, 2) + (operating_year - 2021)*hurricane_data(operating_month,5))/(monthly_hour_count(operating_month,2)*(2021-1992)); %Adjusts the probability of a hurricane occuring into the future %slope of yearly hurricane count graph = 0.0108
 %Duration of hurricane impacting NJ + 24hrs for pre and post event safety.

for t=1:Num_Hour

    if (rand < hourly_prob_of_hurricane)
    
        hourly_hurricane(t,1) = 1;
        turbine_outage_duration = round(normrnd(hurricane_data(operating_month-5,3), hurricane_data(operating_month-5,4)) + 24);

        before_event_outage_duration = round(turbine_outage_duration/2);
        after_event_outage_duration = round(turbine_outage_duration/2);

        if t<before_event_outage_duration

            before_event_outage_duration=t-1;

        end

        if t+after_event_outage_duration>Num_Hour

            after_event_outage_duration = Num_Hour-t;

        end

        for c = t-before_event_outage_duration: t+after_event_outage_duration

            hourly_turbine_SD(c,1) = 1;

        end

    end

end


%Perform the load adjustment based on temperature adjustment
%Load vs Temperature Function: f(t) = 13.863t^2 -230.51t + 8119.7
hourly_load=zeros(Num_Hour,1);

for t=1:Num_Hour

    prev_temp = hourly_temp(t);
    new_temp = prev_temp + (operating_year-weather_year)*monthly_temp_adj(operating_month,2);
    
    load_adjustment = ((13.863*new_temp^2) -230.51*new_temp +8119.7) - ((13.863*prev_temp^2) -230.51*prev_temp +8119.7);

    hourly_load(t) = sampled_forceasted_load_data(t) + load_adjustment; 

end












