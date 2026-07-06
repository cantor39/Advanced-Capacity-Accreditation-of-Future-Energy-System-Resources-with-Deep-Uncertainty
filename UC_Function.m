function [Var_UC_I_LS, final_Var_UC_I, final_Var_UC_I_SU, final_Var_UC_I_SD, final_Var_UC_I_LS, final_Var_UC_I_Batt_Dis, final_Var_UC_I_Batt_Char, final_Var_UC_P, final_Var_UC_Batt_Char, final_Var_UC_Batt_Dis, final_Var_UC_Batt_SOC, final_Var_UC_LS] ... 
    = UC_Function(Date_Dispatch, overlap_days, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, hourly_turbine_SD, Scaler_Wind, Scaler_Solar, Scaler_Batt, load_adjustment, ... 
   init_Var_UC_I, init_Var_UC_I_SU, init_Var_UC_I_SD, init_Var_UC_I_LS, init_Var_UC_I_Batt_Dis, init_Var_UC_I_Batt_Char, init_Var_UC_P, init_Var_UC_Batt_SOC, init_Var_UC_Batt_Dis, init_Var_UC_Batt_Char, init_Var_UC_LS)

%Ensures all need folder paths are included
addpath(genpath('C:\Users\escan\OneDrive\Desktop\Grad Work\ELCC Work\UC\UC\Database'));
addpath(genpath('C:\Users\escan\OneDrive\Desktop\Grad Work\ELCC Work\UC\UC\Database\Monthly_Load_Weather_Data'));
addpath(genpath('C:\Users\escan\OneDrive\Desktop\Grad Work\ELCC Work\YALMIP-master\YALMIP-master'));
addpath(genpath('C:\Users\escan\OneDrive\Desktop\Grad Work\ELCC Work\UC\UC\Database\Yearly_Forcasted_PJM_Load_Data\combined_hourly_forecast'));



overlap_hours=overlap_days*24;


%
%% ------------------------------ Loading ------------------------------ %%
[Num_Gen,...
 Num_Branch,...
 Num_Bus,...
 Num_Bus_Load,...
 Num_Hour,...
 Num_Wind,...
 Num_Solar,...
 Num_Batt,...
 Num_Seg,...
 Gen_Capacity,...
 Gen_Price,...
 Branch,...
 hourly_Branch_AAR,...
 Load_System_DAF_Dis,...
 Load_Bus_DAF_Dis,...
 Load_Bus_Weight,...
 Wind_SUM_DAF_Dis,...
 Solar_SUM_DAF_Dis,...
 Wind_Farm_DAF_Dis,...
 Solar_Farm_DAF_Dis,...
 on_off_shore,... %1=offshore, 0=onshore
 batt_data,...
 PTDF_Gen,...
 PTDF_Load,...
 PTDF_Wind,...
 PTDF_Solar,...
 PTDF_Batt,...
 Unit_Quick,...
 Unit_Thermal,...
 Gen_Price_PWL_Intercept,...
 Gen_Price_PWL_Slope,...
 Seg_Range,...
 BK_Point_Gen,...
 BK_Point_Cost,...
 VOLL_Price,...
 For_Out_Rate] = UC_Database(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, Scaler_Wind, Scaler_Solar);
 
    
%% ------------------------------ Decision ----------------------------- %%

%Declare binary variables for on/off states
Var_UC_I    = binvar(Num_Gen, Num_Hour); %1=unit is ON, 0=unit is OFF
Var_UC_I_SU = binvar(Num_Gen, Num_Hour); %1=unit is Starting Up
Var_UC_I_SD = binvar(Num_Gen, Num_Hour); %1=unit is Shutting Down
Var_UC_I_LS = binvar(1, Num_Hour); %1=load shed occurs on a bus (Ethan added 3/13)
Var_UC_I_Batt_Dis = binvar(Num_Batt, Num_Hour); %1 if battery is discharging
Var_UC_I_Batt_Char = binvar(Num_Batt, Num_Hour); %1 if battery is charging

%Declare continuous variables
Var_UC_P      = sdpvar(Num_Gen, Num_Hour); %Generator power output
Var_UC_P_Cost = sdpvar(Num_Gen, Num_Hour); %Generator power generation costs
Var_UC_Wind   = sdpvar(Num_Hour, Num_Wind);  %Wind generator power output
Var_UC_Wind_Curtail = sdpvar(Num_Hour, Num_Wind); % Wind generator curtailment
Var_UC_Wind_Cost   = sdpvar(Num_Hour, Num_Wind); 
Var_UC_Wind_Curtail_Cost = sdpvar(Num_Hour, Num_Wind); %Cost of wind curtailment
Var_UC_Solar  = sdpvar(Num_Hour, Num_Solar); %Solar generator power output
Var_UC_Solar_Curtail = sdpvar(Num_Hour, Num_Solar); %Solar generator curtailment
Var_UC_Solar_Curtail_Cost = sdpvar(Num_Hour, Num_Solar); %Cost of solar curtailment
Var_UC_Solar_Cost  = sdpvar(Num_Hour, Num_Solar);
Var_UC_Batt_SOC = sdpvar(Num_Hour, Num_Batt); %Battery state of charge
Var_UC_Batt_Dis = sdpvar(Num_Hour, Num_Batt); %Battery quantity of discharge
Var_UC_Batt_Char = sdpvar(Num_Hour, Num_Batt); %Battery quantity of charge
Var_UC_Batt_Cost = sdpvar(Num_Hour, Num_Batt); %Battery Operational Cost
%Var_UC_R_H    = sdpvar(Num_Gen, Num_Hour); %Generator hot reserve available
%Var_UC_R_C    = sdpvar(Num_Gen, Num_Hour); %Generator cool reserve available
Var_UC_LS     = sdpvar(1, Num_Hour); %Quantity of load shed occuring at each load bus (Ethan added 3/13)
%Var_Load_Adjustment = sdpvar(1);
%Var_System_LOLE = sdpvar(1);
%
%% ----------------------------- System Costs and Objective ----------------------------- %%
Cost_UC_SU   = Gen_Price(:, 5)'*sum(Var_UC_I_SU, 2); %All unit start up cost
Cost_UC_P    = sum(Var_UC_P_Cost(:)); %All unit power generation costs
Cost_UC_Wind = sum(Var_UC_Wind_Cost);
Cost_UC_Wind_Curtail = sum(Var_UC_Wind_Curtail_Cost);
Cost_UC_Solar = sum(Var_UC_Solar_Cost);
Cost_UC_Solar_Curtail = sum(Var_UC_Solar_Curtail_Cost);
Cost_UC_Batt = sum(Var_UC_Batt_Cost(:));
Cost_UC_LS   = VOLL_Price*sum(Var_UC_LS(:)); % VOLL * Sum of all load shed across all hours (Ethan added 3/13)
Cost_SYS_EXP = Cost_UC_SU + Cost_UC_P  + Cost_UC_Batt + Cost_UC_Wind + Cost_UC_Wind_Curtail + Cost_UC_Solar + Cost_UC_Solar_Curtail + Cost_UC_LS;


%
%% ---------------------------- Constraint ----------------------------- %%
Con = [];

%% System and Nodal Load Adjustment

%Distributes system load adjustment to each bus based on bus weights
for t = 1:Num_Hour
    Adjusted_Load(t,:) = Load_Bus_DAF_Dis(t, :) + (load_adjustment * Load_Bus_Weight(:)');
    
end


%Makes sure that nodal loads are never negative after a load adjustment is
%applied
[row,col]=find(Adjusted_Load<0);

for i=1:length(row)

    Adjusted_Load(row(i), col(i))=0;

end


%% Loading Initial Conditions

if isempty(init_Var_UC_I)

    for c =1:Num_Batt
        Con = Con + [Var_UC_Batt_SOC(1,c)==0.5*batt_data(c,2)];%Initializes all batteries to 50% charge
    end
    overlap_hours=0;

else

    
    
    Con = Con + [Var_UC_I(:,1:overlap_hours) == init_Var_UC_I];
    
    Con = Con + [Var_UC_I_SU(:,1:overlap_hours) == init_Var_UC_I_SU];
    Con = Con + [Var_UC_I_SD(:,1:overlap_hours) == init_Var_UC_I_SD];
    Con = Con + [Var_UC_I_LS(:,1:overlap_hours) == init_Var_UC_I_LS];
    Con = Con + [Var_UC_P(:,1:overlap_hours) == init_Var_UC_P];
    Con = Con + [Var_UC_LS(:,1:overlap_hours) == init_Var_UC_LS];
    
    Con = Con + [Var_UC_I_Batt_Dis(:,1:overlap_hours) == init_Var_UC_I_Batt_Dis];
    Con = Con + [Var_UC_I_Batt_Char(:,1:overlap_hours) == init_Var_UC_I_Batt_Char];
   
    Con = Con + [Var_UC_Batt_SOC(1:overlap_hours,:) == init_Var_UC_Batt_SOC];
    Con = Con + [Var_UC_Batt_Dis(1:overlap_hours,:) == init_Var_UC_Batt_Dis];
    Con = Con + [Var_UC_Batt_Char(1:overlap_hours,:) == init_Var_UC_Batt_Char];
    
    
end

%% Thermal Generation Constraints 
disp("Loading Generation Limits")
for t = 1+overlap_hours:Num_Hour
    Con = Con + [Var_UC_P(:, t) >= Gen_Capacity(:, 4).* Var_UC_I(:, t) ]; %Minimum generator limit
    Con = Con + [Var_UC_P(:, t) <= (1-For_Out_Rate(t,:))'.*Gen_Capacity(:, 3).* Var_UC_I(:, t) ]; %Maximum generator limit (considering forced outages)

end


disp("Loading PWL Constraints")
%Linearizes Thermal Generator Costs
for i = 1:Num_Gen
    for t = 1:Num_Hour
        for k = 1:Num_Seg
            Con = Con...
                + [ Var_UC_P_Cost(i, t) >= Gen_Price_PWL_Intercept(i, k)*Var_UC_I(i, t)...
                                         + Gen_Price_PWL_Slope(i, k)*Var_UC_P(i, t)]; %Generator Revenue >= Operating Costs (?)
        end
    end
end

disp("Loading Logical Relationships")
%Ensures start up and shut down logic
for t = 1+overlap_hours:Num_Hour
    if t == 1
        Con = Con...
            + [ Var_UC_I_SU(:, t) - Var_UC_I_SD(:, t) == Var_UC_I(:, t) ]; %Start Up On/Off - Shut Down On/Off == Gen Operating On/Off (Ensures at t=1 that the generator start up/shut down matches its current operating condition)
    end
    if t >= 2
        Con = Con...
            + [ Var_UC_I_SU(:, t) - Var_UC_I_SD(:, t) == Var_UC_I(:, t) - Var_UC_I(:, t-1) ]; %Start Up On/Off - Shut Down On/Off == Current Time Gen On/Off - Previous Time Gen On/Off 
                                                                                              %(Ensures that when the generator switches from off to on, Start Up=1, and when the generator switches from
                                                                                              %on to off, Shut Down =1)
    end
end



disp("Loading Minimum On/Off Times")
%Ensures minimum on and off times
for i = 1:Num_Gen
    if overlap_hours == 0

        on_start_time=Gen_Capacity(i, 5);
        off_start_time=Gen_Capacity(i, 6);

    else

        on_start_time= overlap_hours+1;
        off_start_time= overlap_hours+1;

    end
    % ON
    
    for t = on_start_time:Num_Hour
   
        Con = Con + [ sum(Var_UC_I_SU(i, t-Gen_Capacity(i, 5)+1:t)) <= Var_UC_I(i, t) ]; %Ensures the Minimum On Time Criteria is Met
        
    end
    % OFF
    for t = off_start_time:Num_Hour
   
        Con = Con + [ sum(Var_UC_I_SD(i, t-Gen_Capacity(i, 6)+1:t)) <= 1 - Var_UC_I(i, t) ]; %Ensures the Minimum Off Time Criteria is Met
        
    end
end


%% Renewable Energy Source Constraints
disp("Loading Renewables")

% 0 <= Solar Power Output <= Solar Farm Power Production
% 0 <= Solar Curtailment <= Solar Farm Power Production
Con = Con + [0 <= Var_UC_Solar_Curtail,0 <= Var_UC_Solar, Solar_Farm_DAF_Dis - Var_UC_Solar == Var_UC_Solar_Curtail];

% 0 <= Wind Power Output <= Wind Farm Power Production*(1-binary turbine shutdown), 
% 0<= Wind Curtailment <= Wind Farm Power Production
Con = Con + [0 <= Var_UC_Wind_Curtail, 0 <= Var_UC_Wind, Wind_Farm_DAF_Dis.*(1-hourly_turbine_SD) - Var_UC_Wind == Var_UC_Wind_Curtail];



%RES Costs
%According to https://www.eia.gov/outlooks/aeo/electricity_generation/pdf/AEO2025_LCOE_report.pdf
offshore_cost = 88.16;
onshore_cost = 29.58;
solar_cost = 31.86;

curt_factor=10;


for c = 1:Num_Wind
    if on_off_shore(c)==1
        
        Con = Con + [Var_UC_Wind_Cost(:, c) == Var_UC_Wind(:,c)*offshore_cost];
        Con = Con + [Var_UC_Wind_Curtail_Cost(:,c)==Var_UC_Wind_Curtail(:,c)*offshore_cost*curt_factor];

    elseif on_off_shore(c)==0

        Con = Con + [Var_UC_Wind_Cost(:, c) == Var_UC_Wind(:,c)*onshore_cost];
        Con = Con + [Var_UC_Wind_Curtail_Cost(:,c)==Var_UC_Wind_Curtail(:,c)*onshore_cost*curt_factor];
    end
end

for c=1:Num_Solar

    Con = Con + [Var_UC_Solar_Cost(:,c) == Var_UC_Solar(:,c)*solar_cost];
    Con = Con + [Var_UC_Solar_Curtail_Cost(:,c) == Var_UC_Solar_Curtail(:,c)*solar_cost*curt_factor];

end



%% Battery Constraints
%disp("Loading Energy Storage")
for c = 1:Num_Batt

    for t = 1+overlap_hours:Num_Hour
        if t==1

        else
            Con = Con + [Var_UC_Batt_SOC(t,c) == Var_UC_Batt_SOC(t-1,c) + Var_UC_Batt_Char(t,c)*batt_data(c,6) - Var_UC_Batt_Dis(t,c)*(1/batt_data(c,6))]; %Updates state of charge
        end
               
        Con = Con + [batt_data(c,3)<=Var_UC_Batt_SOC(t,c), batt_data(c,2)>=Var_UC_Batt_SOC(t,c)]; %Minimum State of Charge <= Current State of Charge <= Maximum State of Charge
        Con = Con + [0 <= Var_UC_Batt_Char(t,c), Var_UC_Batt_Char(t,c)<= batt_data(c,4)*Var_UC_I_Batt_Char(c,t)* Scaler_Batt(c)]; %0<=Current Charge Rate <= Max Charge Rate * Charge on/off * Batt on/off
        Con = Con + [0 <= Var_UC_Batt_Dis(t,c), Var_UC_Batt_Dis(t,c)<= batt_data(c,5)*Var_UC_I_Batt_Dis(c,t) * Scaler_Batt(c)];  %0<=Current Discharge Rate <= Max Discharge Rate * Discharge on/off * Batt on/off
        Con = Con + [Var_UC_I_Batt_Char(c,t) + Var_UC_I_Batt_Dis(c,t) <=1]; % Charge on/off + Discharge on/off <=1
        
    end

    %Battery charging costs
    cost_of_charging=126.2; 
    Con = Con + [Var_UC_Batt_Cost(:,c)== Var_UC_Batt_Char(:,c)*cost_of_charging]; 

end

%% Power Balance Constraints 
disp("Loading Power Balance Constraints")
for t = 1+overlap_hours:Num_Hour
    %Thermal Generators Output + Wind Output + Solar Output + Battery Discharge - Battery Charge + Load Shed == Sum Of Loads
    Con = Con...
        + [  sum(Var_UC_P(:, t))...
            + sum(Var_UC_Wind(t, :))...
            + sum(Var_UC_Solar(t,:))...
            + sum(Var_UC_Batt_Dis(t,:))...
            - sum(Var_UC_Batt_Char(t,:))...
            + sum(Var_UC_LS(:,t))... 
           == sum(Adjusted_Load(t,:))]; 
end         

%% Transmission Constraints 
disp("Loading Transmission Constraints")
for t = 1+overlap_hours:Num_Hour

    Con = Con...
        + [ - Branch(:, 5)*hourly_Branch_AAR(t)... %Add the AAR to consider the impact of ambient temperature on max trans rating
           <= PTDF_Gen*Var_UC_P(:, t)...
            + PTDF_Wind*Var_UC_Wind(t, :)'...
            + PTDF_Solar*Var_UC_Solar(t, :)'...
            + PTDF_Batt*(Var_UC_Batt_Dis(t,:)-Var_UC_Batt_Char(t,:))'...
            - PTDF_Load*(Adjusted_Load(t,:)'-(Var_UC_LS(:,t).*Load_Bus_Weight(:)))...%Load Shed*Bus Weight to distribute to each bus
           <= Branch(:, 5)*hourly_Branch_AAR(t)]; 
end


%% Load Shed Constraints 
disp("Loading Load Shed Constraints")
for t = 1+overlap_hours:Num_Hour
    
        Con = Con...
            + [ Var_UC_LS(1, t) <= sum(Adjusted_Load(t,:))* Var_UC_I_LS(1,t)];%Limits load shed to no more than the system demand
        Con = Con...
            + [Var_UC_LS(1,t) >=1E-3*Var_UC_I_LS(1,t)]; %Ensures logical dependence between binary load shed indicator, and quantity of load shed
        
end

%% ------------------------------ Solver Settings ----------------------------- %%

ops = sdpsettings('solver', 'gurobi', 'verbose', 3);

ops.gurobi.MIPGap = 0.001;  % Set MIPGap
ops.gurobi.Heuristics = 0.05;
ops.gurobi.Cuts = 2;
ops.gurobi.Presolve = 2;
ops.gurobi.NodefileStart = inf;
ops.gurobi.TimeLimit = 120;

sol = optimize(Con, Cost_SYS_EXP, ops); %Performs the optimization


%This set of if else is only used for debugging
if sol.problem == 1
    disp('❌ Infeasible problem detected');
    save("Infeasible_UC")
    keyboard   
elseif sol.problem == 2
    disp('⚠️ Unbounded problem detected');
    save("Unbounded_UC")
    keyboard
elseif sol.problem == 3
    disp('Ran out of time')
    keyboard
elseif sol.problem==12
    disp('⚠️ Unbounded or Infeasible problem detected');
    save("Unbounded_or_Infeasible_UC")
    keyboard
end




%% ------------------------ Value and Round it ------------------------- %%

%Displays binary variable results
Var_UC_I            = round(value(Var_UC_I));
Var_UC_I_SU         = round(value(Var_UC_I_SU));
Var_UC_I_SD         = round(value(Var_UC_I_SD));
Var_UC_I_LS         = round(value(Var_UC_I_LS)); 
Var_UC_I_Batt_Dis   = round(value(Var_UC_I_Batt_Dis));
Var_UC_I_Batt_Char  = round(value(Var_UC_I_Batt_Char));

%Displays continuous variable results
Var_UC_P                    = round(value(Var_UC_P), 4);
Var_UC_P_Cost               = round(value(Var_UC_P_Cost), 4);
Var_UC_Wind                 = round(value(Var_UC_Wind), 4);
Var_UC_Wind_Curtail         = round(value(Var_UC_Wind_Curtail), 4);
Var_UC_Wind_Curtail_Cost    = round(value(Var_UC_Wind_Curtail_Cost), 4);
Var_UC_Solar                = round(value(Var_UC_Solar), 4);
Var_UC_Solar_Curtail        = round(value(Var_UC_Solar_Curtail), 4);
Var_UC_Solar_Curtail_Cost   = round(value(Var_UC_Solar_Curtail_Cost), 4);
Var_UC_Batt_Char            = round(value(Var_UC_Batt_Char));
Var_UC_Batt_Dis             = round(value(Var_UC_Batt_Dis));
Var_UC_Batt_SOC             = round(value(Var_UC_Batt_SOC));
Var_UC_Batt_Cost            = round(value(Var_UC_Batt_Cost));
Var_UC_LS                   = round(value(Var_UC_LS), 4); 

% Cost
Cost_UC_SU   = value(Cost_UC_SU);
Cost_UC_P    = value(Cost_UC_P);
Cost_UC_LS   = value(Cost_UC_LS); %(Ethan added 3/13)
Cost_UC_Batt = value(Cost_UC_Batt);
Cost_SYS_EXP = value(Cost_SYS_EXP);



%% --------------------------- Return Last Day of Variables for Next Solver Horizon--------------------------- %%
final_Var_UC_I = Var_UC_I(:, (Num_Hour-23):Num_Hour);
final_Var_UC_I_SU = Var_UC_I_SU(:, (Num_Hour-23):Num_Hour);
final_Var_UC_I_SD = Var_UC_I_SD(:, (Num_Hour-23):Num_Hour);
final_Var_UC_I_LS = Var_UC_I_LS(:, (Num_Hour-23):Num_Hour);
final_Var_UC_I_Batt_Dis = Var_UC_I_Batt_Dis(:, (Num_Hour-23):Num_Hour);
final_Var_UC_I_Batt_Char = Var_UC_I_Batt_Char(:, (Num_Hour-23):Num_Hour);
final_Var_UC_P = Var_UC_P(:, (Num_Hour-23):Num_Hour);
final_Var_UC_Batt_Char = Var_UC_Batt_Char((Num_Hour-23):Num_Hour,:);
final_Var_UC_Batt_Dis = Var_UC_Batt_Dis((Num_Hour-23):Num_Hour,:);
final_Var_UC_Batt_SOC = Var_UC_Batt_SOC((Num_Hour-23):Num_Hour,:);
final_Var_UC_LS = Var_UC_LS(:, (Num_Hour-23):Num_Hour);

%
%% --------------------------- Check Transmission line Usage --------------------------- %%
Trans_Power = zeros(Num_Branch, Num_Hour);
Trans_Rate  = zeros(Num_Branch, Num_Hour);
for t = 1:Num_Hour
    Trans_Power(:, t) = PTDF_Gen*Var_UC_P(:, t)...
            + PTDF_Wind*Var_UC_Wind(t, :)'...
            + PTDF_Solar*Var_UC_Solar(t, :)'...
            + PTDF_Batt*(Var_UC_Batt_Dis(t,:)-Var_UC_Batt_Char(t,:))'...
            - PTDF_Load*(Adjusted_Load(t,:)'-Var_UC_LS(:,t).*Load_Bus_Weight); %Transfered Power %Modifed by Ethan on 3/17, adding the Var_UC_LS term
end
for i = 1:Num_Branch
    for t = 1:Num_Hour
        Trans_Rate(i, t) = round(Trans_Power(i, t)/(Branch(i, 5)*hourly_Branch_AAR(t)), 2); %Transfer Rate (Transfered Power on each Branch / Max Power Transfer on each Branch)
    end   
end
Trans_Rate_max_avr = zeros(Num_Branch, 2);
for i = 1:Num_Branch
    Trans_Rate_max_avr(i, 1) = max(abs(Trans_Rate(i, :))); %Maximum Transfer Rate Throughout the Day on each Branch
    Trans_Rate_max_avr(i, 2) = sum(abs(Trans_Rate(i, :)))/Num_Hour;  %Average Transfer Rate Throughout the Day on each Branch 
end







