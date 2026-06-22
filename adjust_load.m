%This function is used to increase or decrease the system load until the
%desired LOLH is achieved. 


function [load_adjustment] = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, Scaler_Wind, Scaler_Solar, Scaler_Batt, load_adjustment)

current_LOLH = 100; %Initial value to ensure the while loop is entered.
LOLH_tolerance = 0.005; %As a percentage/100
standard_LOLH=0.2; %(2.4hrs/yr) * (1year/12months) = 0.2hrs/month
largest_load_adj_with_LOLH_less_than_standard_LOLH = -1E10;
smallest_load_adj_with_LOLH_greater_than_standard_LOLH = 1E10;

measured_an_LOLH_less_than_standard_LOLH = 0; %This is used as a bianry variable to indicate whether an LOLH less than the standard LOLH was measured
measured_an_LOLH_greater_than_standard_LOLH = 0; %This is used as a bianry variable to indicate whether an LOLH greater than the standard LOLH was measured

max_adj_diff_before_stopping = 2; %This is the maximum range of MW for which the LOLH could be located within
stay_in_loop = 1; %If the max number of increments is exceded, this is used to exit the while loop

  
num_weather_samples=size(hourly_temp, 2);

num_par_weather = 50;
series_weather = num_weather_samples/num_par_weather;
   

    while ((current_LOLH>standard_LOLH*(1+LOLH_tolerance) || current_LOLH<standard_LOLH*(1-LOLH_tolerance)) & (stay_in_loop==1))
        
       for n=1:series_weather
            parfor w=((num_par_weather*(n-1))+1):(n*num_par_weather)
   
            
                %disp(["On weather year", w])
                weather_sample_LOLH(w) = rolling_horizon(Date_Dispatch, hourly_temp(:,w), hourly_irr(:,w), hourly_onshore_wind(:,w), hourly_offshore_wind(:,w), Load_System_DAF_Dis(:,w), hourly_turbine_SD(:,w), Scaler_Wind, Scaler_Solar, Scaler_Batt, load_adjustment);
                
    
            end
            save('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/adjusted__load_Results')
       end
       
        %weather_sample_LOLH
        current_LOLH = mean(weather_sample_LOLH)
    
        if (measured_an_LOLH_less_than_standard_LOLH == 0 || measured_an_LOLH_greater_than_standard_LOLH == 0)   
            disp("Searching for Bounds")
            if (current_LOLH>standard_LOLH*(1+LOLH_tolerance))
    
                smallest_load_adj_with_LOLH_greater_than_standard_LOLH = load_adjustment;
                load_adjustment = load_adjustment - 1000;
                measured_an_LOLH_greater_than_standard_LOLH = 1;
    
            end
            if (current_LOLH<standard_LOLH*(1-LOLH_tolerance))
    
                largest_load_adj_with_LOLH_less_than_standard_LOLH = load_adjustment;
                load_adjustment = load_adjustment + 1000;
                measured_an_LOLH_less_than_standard_LOLH = 1;
    
            end
    
    
        else
            disp("Refining Bounds")
    
            if (current_LOLH>standard_LOLH*(1+LOLH_tolerance))
                if (load_adjustment<smallest_load_adj_with_LOLH_greater_than_standard_LOLH)
    
                    smallest_load_adj_with_LOLH_greater_than_standard_LOLH=load_adjustment;
    
                end
    
            end
            if (current_LOLH<standard_LOLH*(1-LOLH_tolerance))
                if (load_adjustment>largest_load_adj_with_LOLH_less_than_standard_LOLH)
            
                    largest_load_adj_with_LOLH_less_than_standard_LOLH = load_adjustment;
                
                end
    
            end
            if (abs(largest_load_adj_with_LOLH_less_than_standard_LOLH - smallest_load_adj_with_LOLH_greater_than_standard_LOLH) < max_adj_diff_before_stopping)
                
                disp("exiting loop")
                stay_in_loop = 0;
    
            end
            
            disp("Averaging load adjustment")
            load_adjustment = (smallest_load_adj_with_LOLH_greater_than_standard_LOLH + largest_load_adj_with_LOLH_less_than_standard_LOLH)/2;
    
        end
    
        measured_an_LOLH_less_than_standard_LOLH
        measured_an_LOLH_greater_than_standard_LOLH
        largest_load_adj_with_LOLH_less_than_standard_LOLH
        smallest_load_adj_with_LOLH_greater_than_standard_LOLH

    
    end

