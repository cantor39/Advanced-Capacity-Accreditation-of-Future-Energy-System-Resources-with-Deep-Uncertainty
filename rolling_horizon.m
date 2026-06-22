function [LOLE_sum] = rolling_horizon(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, Scaler_Wind, Scaler_Solar, Scaler_Batt, load_adjustment)


window_length = 7; %7 days
overlap_length = 1; %1 day 
num_days = length(Date_Dispatch);

num_windows = ceil(num_days/window_length);

LOLE_sum=0;


for i=1:num_windows


    if i==1 %The initial conditions are not necessary for the first solve window

        start_day = 1;
        end_day = window_length;

        init_Var_UC_I=[];
        init_Var_UC_I_SU=[];
        init_Var_UC_I_SD=[];
        init_Var_UC_I_LS=[];
        init_Var_UC_I_Batt_Dis=[];
        init_Var_UC_I_Batt_Char=[];
        init_Var_UC_P=[];
        init_Var_UC_Batt_SOC=[];
        init_Var_UC_Batt_Dis=[];
        init_Var_UC_Batt_Char=[];
        init_Var_UC_LS=[];

    
    else

        start_day = window_length*(i-1) + 1 - overlap_length;
        end_day = window_length*i; 

        init_Var_UC_I=final_Var_UC_I;
        init_Var_UC_I_SU=final_Var_UC_I_SU;
        init_Var_UC_I_SD=final_Var_UC_I_SD;
        init_Var_UC_I_LS=final_Var_UC_I_LS;
        init_Var_UC_I_Batt_Dis=final_Var_UC_I_Batt_Dis;
        init_Var_UC_I_Batt_Char=final_Var_UC_I_Batt_Char;
        init_Var_UC_P=final_Var_UC_P;
        init_Var_UC_Batt_SOC=final_Var_UC_Batt_Char;
        init_Var_UC_Batt_Dis=final_Var_UC_Batt_Dis;
        init_Var_UC_Batt_Char=final_Var_UC_Batt_SOC;
        init_Var_UC_LS=final_Var_UC_LS;





    end

   if start_day>num_days

        start_day=num_days-overlap_length;

   end

   if end_day>num_days

       end_day=num_days;

   end

   rolling_dispatch_window = Date_Dispatch(start_day):Date_Dispatch(end_day);

   start_hour = ((start_day-1)*24)+1;
   end_hour = end_day*24;
   window_hourly_temp=hourly_temp(start_hour:end_hour,:);
   window_hourly_irr=hourly_irr(start_hour:end_hour,:);
   window_hourly_onshore_wind=hourly_onshore_wind(start_hour:end_hour,:);
   window_hourly_offshore_wind=hourly_offshore_wind(start_hour:end_hour,:);
   window_Load_System_DAF_Dis=Load_System_DAF_Dis(start_hour:end_hour,:);
   window_hourly_turbine_SD=hourly_turbine_SD(start_hour:end_hour,:);


   [Var_UC_I_LS, final_Var_UC_I, final_Var_UC_I_SU, final_Var_UC_I_SD, final_Var_UC_I_LS, final_Var_UC_I_Batt_Dis, final_Var_UC_I_Batt_Char, final_Var_UC_P, final_Var_UC_Batt_Char, final_Var_UC_Batt_Dis, final_Var_UC_Batt_SOC, final_Var_UC_LS] =  ...
   UC_Function(rolling_dispatch_window, overlap_length, window_hourly_temp, window_hourly_irr, window_hourly_onshore_wind, window_hourly_offshore_wind, window_Load_System_DAF_Dis, window_hourly_turbine_SD, Scaler_Wind, Scaler_Solar, Scaler_Batt, load_adjustment, ... 
   init_Var_UC_I, init_Var_UC_I_SU, init_Var_UC_I_SD, init_Var_UC_I_LS, init_Var_UC_I_Batt_Dis, init_Var_UC_I_Batt_Char, init_Var_UC_P, init_Var_UC_Batt_SOC, init_Var_UC_Batt_Dis, init_Var_UC_Batt_Char, init_Var_UC_LS);
        
   
   if i==1

       LOLE_sum = LOLE_sum + sum(Var_UC_I_LS(:)); %Sums across the first horizon

   else

       LOLE_sum = LOLE_sum + sum(Var_UC_I_LS(:)) - sum(init_Var_UC_I_LS(:)); %Sums across the horizon, minus the first initial day, so as to not double count. 

   end



end



