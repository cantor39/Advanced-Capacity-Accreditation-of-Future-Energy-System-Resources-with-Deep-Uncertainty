clearvars -except Date_Dispatch hourly_irr hourly_offshore_wind hourly_onshore_wind hourly_temp Load_System_DAF_Dis
%clear all
clc
tic
addpath(genpath('Insert Project Folder'));


%% Initialize System Settings
Date_Dispatch = datetime(2030, 6, 1): datetime(2030, 6, 30);

num_weather_samples = 100;

num_hours=24*length(Date_Dispatch);


%% Sample Weather
hourly_temp=zeros(num_hours, num_weather_samples);
hourly_irr=zeros(num_hours, num_weather_samples);
hourly_onshore_wind=zeros(num_hours, num_weather_samples);
hourly_offshore_wind=zeros(num_hours, num_weather_samples);
Load_System_DAF_Dis=zeros(num_hours, num_weather_samples);
hourly_turbine_SD=zeros(num_hours, num_weather_samples);

parfor w=1:num_weather_samples

    [hourly_temp(:,w), hourly_irr(:,w), hourly_onshore_wind(:,w), hourly_offshore_wind(:,w), Load_System_DAF_Dis(:,w), hourly_turbine_SD(:,w), weather_year] = sample_weather_and_load(Date_Dispatch);

end
%% Base System


    disp('Running Base System');
    

    initial_LA=0;
    base_system_load_adjustment = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,0,0], [0,0,0], initial_LA);
    
    save('Save Progress')



    
%% Case 1 - Wind Only Case
    disp("Running Wind Only Case")
    case_text = '_wind_only_';
        
        %Portfolio Load Adjustment and Capacity Credit
        wind_only_portfolio_system_load_adjustment = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')

        %First-In Load Adjustments
        wind_only_first_in_system_load_adjustment(1) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,0,0], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress'))

        wind_only_first_in_system_load_adjustment(2) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,1,0], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        wind_only_first_in_system_load_adjustment(3) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,1], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')

        %Last-In Load Adjustments
        wind_only_last_in_system_load_adjustment(1) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,1,1], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')

        wind_only_last_in_system_load_adjustment(2) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,0,1], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')

        wind_only_last_in_system_load_adjustment(3) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,0], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
       
        %Calculate Individual Generator TRACED Capacity Credits
        for c = 1:3
        
            wind_only_first_in_ELCC(c) = wind_only_first_in_system_load_adjustment(c) - base_system_load_adjustment;
            wind_only_last_in_ELCC(c) = wind_only_portfolio_system_load_adjustment -  wind_only_last_in_system_load_adjustment(c);
            wind_only_individual_interactive_effect(c) = wind_only_first_in_ELCC(c) - wind_only_last_in_ELCC(c);

        end
        wind_only_portfolio_ELCC = wind_only_portfolio_system_load_adjustment - base_system_load_adjustment;
        wind_only_portfolio_interactive_effect =  wind_only_portfolio_ELCC - sum(wind_only_last_in_ELCC(:));
        wind_only_delta = wind_only_portfolio_interactive_effect / sum(wind_only_individual_interactive_effect(:));

        for c = 1:3

            wind_only_TRACED_ELCC(c) =  wind_only_last_in_ELCC(c) + wind_only_delta*wind_only_individual_interactive_effect(c);

        end
        save('Save Progress')


%% Case 2 - Solar Only Case
    disp("Running Solar Only Case")
       
        %Portfolio Load Adjustment and Capacity Credit
        solar_only_portfolio_system_load_adjustment = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,1,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        %First-In Load Adjustments
        solar_only_first_in_system_load_adjustment(1) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        solar_only_first_in_system_load_adjustment(2) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,1,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        solar_only_first_in_system_load_adjustment(3) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,0,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        %Last-In Load Adjustments
        solar_only_last_in_system_load_adjustment(1) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,1,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        solar_only_last_in_system_load_adjustment(2) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,0,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        solar_only_last_in_system_load_adjustment(3) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,1,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        

        %Calculate Individual Generator TRACED Capacity Credits
        for c = 1:3
        
            solar_only_first_in_ELCC(c) = solar_only_first_in_system_load_adjustment(c) - base_system_load_adjustment;
            solar_only_last_in_ELCC(c) = solar_only_portfolio_system_load_adjustment -  solar_only_last_in_system_load_adjustment(c);
            solar_only_individual_interactive_effect(c) = solar_only_first_in_ELCC(c) - solar_only_last_in_ELCC(c);

        end   
        solar_only_portfolio_ELCC = solar_only_portfolio_system_load_adjustment - base_system_load_adjustment;
        solar_only_portfolio_interactive_effect =  solar_only_portfolio_ELCC - sum(solar_only_last_in_ELCC(:));
        solar_only_delta = solar_only_portfolio_interactive_effect / sum(solar_only_individual_interactive_effect(:));

        for c = 1:3

            solar_only_Delta_ELCC(c) =  solar_only_last_in_ELCC(c) + solar_only_delta*solar_only_individual_interactive_effect(c);

        end
        save('Save Progress')




%% Case 3 - Wind+Solar Case
    disp("Running Wind+Solar Case")

        wind_and_solar_portfolio_system_load_adjustment = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,1,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        %First-In Load Adjustments
        %Reuses FI load adjustments from Cases 1 and 2
        wind_and_solar_first_in_system_load_adjustment(1) = wind_only_first_in_system_load_adjustment(1);
        wind_and_solar_first_in_system_load_adjustment(2) = wind_only_first_in_system_load_adjustment(2);
        wind_and_solar_first_in_system_load_adjustment(3) = wind_only_first_in_system_load_adjustment(3);
        wind_and_solar_first_in_system_load_adjustment(4) = solar_only_first_in_system_load_adjustment(1);
        wind_and_solar_first_in_system_load_adjustment(5) = solar_only_first_in_system_load_adjustment(2);       
        wind_and_solar_first_in_system_load_adjustment(6) = solar_only_first_in_system_load_adjustment(3);  

        %Last-In Load Adjustments
        wind_and_solar_last_in_system_load_adjustment(1) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,1,1], [1,1,1], [0,0,0], base_system_load_adjustment);
        ssave('Save Progress')

        wind_and_solar_last_in_system_load_adjustment(2) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,0,1], [1,1,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
       
        wind_and_solar_last_in_system_load_adjustment(3) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,0], [1,1,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        wind_and_solar_last_in_system_load_adjustment(4) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [0,1,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        wind_and_solar_last_in_system_load_adjustment(5) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,0,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
                
        wind_and_solar_last_in_system_load_adjustment(6) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,1,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')

        %Calculate Individual Generator TRACED Capacity Credits
        for c = 1:6
        
            wind_and_solar_first_in_ELCC(c) = wind_and_solar_first_in_system_load_adjustment(c) - base_system_load_adjustment;
            wind_and_solar_last_in_ELCC(c) = wind_and_solar_portfolio_system_load_adjustment - wind_and_solar_last_in_system_load_adjustment(c);
            wind_and_solar_individual_interactive_effect(c) = wind_and_solar_first_in_ELCC(c) - wind_and_solar_last_in_ELCC(c);
            
        end
        
        wind_and_solar_portfolio_ELCC = wind_and_solar_portfolio_system_load_adjustment - base_system_load_adjustment;
        wind_and_solar_portfolio_interactive_effect =  wind_and_solar_portfolio_ELCC - sum(wind_and_solar_last_in_ELCC(:));
        wind_and_solar_delta = wind_and_solar_portfolio_interactive_effect / sum(wind_and_solar_individual_interactive_effect(:));

        for c=1:6

            wind_and_solar_Delta_ELCC(c) =  wind_and_solar_last_in_ELCC(c) + wind_and_solar_delta*wind_and_solar_individual_interactive_effect(c);

        end
          save('Save Progress')


%% Case 4 - Solar+Battery Case
disp("Running Wind+Solar+Battery Case")

        solar_battery_portfolio_system_load_adjustment = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,1,1], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
        
        %First-In Load Adjustments

        %Reuse the FI load adjustments from Case 2
        solar_battery_first_in_system_load_adjustment(1) = solar_only_first_in_system_load_adjustment(1);
        solar_battery_first_in_system_load_adjustment(2) = solar_only_first_in_system_load_adjustment(2);       
        solar_battery_first_in_system_load_adjustment(3) = solar_only_first_in_system_load_adjustment(3);

        
        solar_battery_first_in_system_load_adjustment(4) = wind_solar_battery_first_in_system_load_adjustment(7);
        save('Save Progress')
            
        solar_battery_first_in_system_load_adjustment(5) = wind_solar_battery_first_in_system_load_adjustment(8);
        save('Save Progress')
        
        solar_battery_first_in_system_load_adjustment(6) = wind_solar_battery_first_in_system_load_adjustment(9);
        save('Save Progress')
        

        %Last-In Load Adjustments
        solar_battery_last_in_system_load_adjustment(1) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,1,1], [1,1,1], base_system_load_adjustment);
        ssave('Save Progress')
        
        solar_battery_last_in_system_load_adjustment(2) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,0,1], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
        
        solar_battery_last_in_system_load_adjustment(3) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,1,0], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
        
        solar_battery_last_in_system_load_adjustment(4) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,1,1], [0,1,1], base_system_load_adjustment);
        save('Save Progress')
        
        solar_battery_last_in_system_load_adjustment(5) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,1,1], [1,0,1], base_system_load_adjustment);
        save('Save Progress')
        
        solar_battery_last_in_system_load_adjustment(6) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,1,1], [1,1,0], base_system_load_adjustment);
        save('Save Progress')
        

        %Calculate Individual Generator TRACED Capacity Credits
        for c = 1:6
        
            solar_battery_first_in_ELCC(c) = solar_battery_first_in_system_load_adjustment(c) - base_system_load_adjustment;
            solar_battery_last_in_ELCC(c) = solar_battery_portfolio_system_load_adjustment - solar_battery_last_in_system_load_adjustment(c);
            solar_battery_individual_interactive_effect(c) = solar_battery_first_in_ELCC(c) - solar_battery_last_in_ELCC(c);
            
        end  

        solar_battery_portfolio_ELCC = solar_battery_portfolio_system_load_adjustment - base_system_load_adjustment;
        solar_battery_portfolio_interactive_effect =  solar_battery_portfolio_ELCC - sum(solar_battery_last_in_ELCC(:));
        solar_battery_delta = solar_battery_portfolio_interactive_effect / sum(solar_battery_individual_interactive_effect(:)); 


        for c =1:6

            solar_battery_Delta_ELCC(c) =  solar_battery_last_in_ELCC(c) + solar_battery_delta*solar_battery_individual_interactive_effect(c);
        
        end
           save('Save Progress')










%% Transmission Sensitivity Analysis (Wind+Solar+Battery Case)

    disp("Running Transmission Sensitivity Analysis")
    load("June 1-Month Results"); %Keeps weather conditions same as the June Results for Sensitivity Analysis    
    clearvars -except Date_Dispatch hourly_irr hourly_offshore_wind hourly_onshore_wind hourly_temp hourly_turbine_SD Load_System_DAF_Dis
        

        %Base System
        base_system_load_adjustment = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,0,0], [0,0,0], 0);
        save('Save Progress')
        
        %Portfolio System
        wind_solar_battery_portfolio_system_load_adjustment = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,1,1], [1,1,1], base_system_load_adjustment);
        save('Save Progress')

        %First-In Load Adjustments
        wind_solar_battery_first_in_system_load_adjustment(1) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,0,0], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        wind_solar_battery_first_in_system_load_adjustment(2) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,1,0], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        wind_solar_battery_first_in_system_load_adjustment(3) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,1], [0,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        wind_solar_battery_first_in_system_load_adjustment(4) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [1,0,0], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        wind_solar_battery_first_in_system_load_adjustment(5) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,1,0], [0,0,0], base_system_load_adjustment);      
        save('Save Progress')
        
        wind_solar_battery_first_in_system_load_adjustment(6) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,0,1], [0,0,0], base_system_load_adjustment);
        save('Save Progress')
        
        
        wind_solar_battery_first_in_system_load_adjustment(7) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,0,0], [1,0,0], base_system_load_adjustment);
        save('Save Progress')

        wind_solar_battery_first_in_system_load_adjustment(8) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,0,0], [0,1,0], base_system_load_adjustment);
        save('Save Progress')

        wind_solar_battery_first_in_system_load_adjustment(9) = adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,0,0], [0,0,0], [0,0,1], base_system_load_adjustment);
        save('Save Progress')
     
        %Last-in Load Adjustments
        wind_solar_battery_last_in_system_load_adjustment(1) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [0,1,1], [1,1,1], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
     
        wind_solar_battery_last_in_system_load_adjustment(2) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,0,1], [1,1,1], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
        
        wind_solar_battery_last_in_system_load_adjustment(3) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,0], [1,1,1], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
        
        wind_solar_battery_last_in_system_load_adjustment(4) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [0,1,1], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
       
        wind_solar_battery_last_in_system_load_adjustment(5) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,0,1], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
        
        wind_solar_battery_last_in_system_load_adjustment(6) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,1,0], [1,1,1], base_system_load_adjustment);
        save('Save Progress')
        
        
        wind_solar_battery_last_in_system_load_adjustment(7) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,1,1], [0,1,1], base_system_load_adjustment);
        save('Save Progress')
       
        wind_solar_battery_last_in_system_load_adjustment(8) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,1,1], [1,0,1], base_system_load_adjustment);
        save('Save Progress')
       
        wind_solar_battery_last_in_system_load_adjustment(9) =  adjust_load(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, [1,1,1], [1,1,1], [1,1,0], base_system_load_adjustment);
        save('Save Progress')
        

        %Calculate Individual Generator TRACED Capacity Credits
        for c = 1:9
        
            wind_solar_battery_first_in_ELCC(c) = wind_solar_battery_first_in_system_load_adjustment(c) - base_system_load_adjustment;
            wind_solar_battery_last_in_ELCC(c) = wind_solar_battery_portfolio_system_load_adjustment - wind_solar_battery_last_in_system_load_adjustment(c);
            wind_solar_battery_individual_interactive_effect(c) = wind_solar_battery_first_in_ELCC(c) - wind_solar_battery_last_in_ELCC(c);
            
        end  

        wind_solar_battery_portfolio_ELCC = wind_solar_battery_portfolio_system_load_adjustment - base_system_load_adjustment;
        wind_solar_battery_portfolio_interactive_effect =  wind_solar_battery_portfolio_ELCC - sum(wind_solar_battery_last_in_ELCC(:));
        wind_solar_battery_alpha = wind_solar_battery_portfolio_interactive_effect / sum(wind_solar_battery_individual_interactive_effect(:)); 


        for c =1:9

            wind_solar_battery_Delta_ELCC(c) =  wind_solar_battery_last_in_ELCC(c) + wind_solar_battery_alpha*wind_solar_battery_individual_interactive_effect(c);
        
        end
           save('Save Progress')





 
