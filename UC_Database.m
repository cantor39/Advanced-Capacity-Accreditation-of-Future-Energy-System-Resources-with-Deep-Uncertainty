%% ---------------------------- RES_Farm_DAF --------------------------- %%
%  Column  #1         ... #5
%  Data    RES_01_DAF ... RES_05_DAF
%
%% ----------------------------- Load_Bus ----------------------------- %%
%  Column  #1                        ... #91
%  Data    Load_Bus_01 (24-1 Vector) ... Load_Bus_91 (24-1 Vector)
%
%% --------------------------- Gen_Capacity ---------------------------- %%
%  Column  #1           #2            #3          #4          #5        
%  Data    Number       Location_Bus  Max_Output  Min_Output  Minimal_On
%  Column  #6           #7            #8          #9          #10
%  Data    Minimal_Off  Ramp_Up       Ramp_Down   SU_Rampup   SD_Rampdown  
%  Column  #11          #12           
%  Data    R_H_max      R_C_max  
%
%% ----------------------------- Gen_Price ----------------------------- %%
%  Column  #1        #2        #3         #4         #5        #6
%  Data    Number    c0        c1         c2         SU_price  SD_price   
%
%% ------------------------------- Branch ------------------------------ %%
%  Column  #1    #2    #3         #4          
%  Data    Fbus  Tbus  Reactance  Capacity
%
%% --------------------------- Battery Storage --------------------------- %%
%  Column  #1           #2                  #3                          
%  Data    Number       Max Capacity (MWh)  Min Capacity (MWh)  
%  Column  #4                    #5                     #6          
%  Data    Max Charge Rate (MW)  Max Discharge Rate (MW)   Charge/Discharge Efficiency  
%% --------------------------- Start function -------------------------- %%

function...
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
 on_off_shore,...
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
 For_Out_Rate] = UC_Database(Date_Dispatch, hourly_temp, hourly_irr, hourly_onshore_wind, hourly_offshore_wind, Load_System_DAF_Dis, Scaler_Wind, Scaler_Solar)

addpath('/opt/gurobi1203/linux64/matlab')
setenv('GRB_LICENSE_FILE', '/home/ifrost/gurobi.lic');
addpath(genpath('/home/ifrost/cantor39/ELCC Work/YALMIP-master'))



% Check for installed solvers
if exist('sdpvar', 'file') ~= 2
    error('YALMIP is not installed. Please install YALMIP to continue.');
end
%
if exist('gurobi', 'file') ~= 3
    error('Gurobi is not installed. Please install Gurobi to continue.');
end
%
%% ------------------------------ Loading ------------------------------ %%
disp('Loading...'); %Only works for Microsoft or Apple computers
if ispc == 1 %Checks if computer is Microsoft OS
    Link = '\';
elseif ismac == 1 %Checks if computer is Apple OS
    Link = '/';
end
%
Ini_Path = which('UC_Database.m'); %Displays full file location of Database_UC_Test.m
Ini_Size = size('UC_Database.m', 2); %Returns the number of characters in the file name
Path_Data = Ini_Path(1:end - Ini_Size - 1); %Returns the location of one folder level above Database_UC_Test.m (ie Folder Database) 



Gen_Capacity     = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Gen_Capacity.csv');
Gen_Price        = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Gen_Price.csv');
Branch           = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Branch.csv');
Load_Bus_Index   = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Load_Bus_Index.csv');
Load_Bus_Weight  = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/Load_Bus_Weight.csv');
batt_data        = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/battery_parameters.csv');
%
%% ---------------------------- Basic Data ----------------------------- %%

% Number of element
Num_Gen      = size(Gen_Capacity, 1);
Num_Branch   = size(Branch, 1);
Num_Bus      = max(max(Branch(:, 2:3)));
Num_Bus_Load = 91;
Num_Seg      = 3;
Num_BKPoint  = Num_Seg+1; 
Num_Hour     = 24*length(Date_Dispatch); 
Num_Day      = length(Date_Dispatch);     
VOLL_Price   = 10000; %Set to $10,000 based on MISO 2024 value 


% For SF (Security Function?)
Ref_Bus = 69;
PTDF = Calculate_PTDF(Branch, Ref_Bus);
PTDF = round(PTDF, 4);

% Unit types 
Unit_Gas  = [1;2;3;6;8;9;12;13;15;17;18];
Unit_Oil  = [31;32;33;38;41;42;46;49;50;54];
Unit_Coal = [4;5;7;10;11;14;16;19;20;21;22;23;24;25;26;27;28;29;30;34;35;...
             36;37;39;40;43;44;45;47;48;51;52;53];
Unit_Quick   = sort([Unit_Gas; Unit_Oil]);
Unit_Thermal = sort([Unit_Coal]);


%Define Forced Outage Rates of Generators
For_Out_Rate = calculate_thermal_outages(Unit_Gas, Unit_Oil, Unit_Coal, hourly_temp, Num_Hour, Num_Gen);







% Confirm subhour
Subhour = 'hh:00';
if Subhour == 'hh:00'
    for i = 1:24
        Point(i, 1) = (i-1)*4+1;
    end
end
if Subhour == 'hh:15'
    for i = 1:24
        Point(i, 1) = (i-1)*4+2;
    end
end
if Subhour == 'hh:30'
    for i = 1:24
        Point(i, 1) = (i-1)*4+3;
    end
end
if Subhour == 'hh:45'
    for i = 1:24
        Point(i, 1) = (i-1)*4+4;
    end
end

%% Transmission System Settings

hourly_Branch_AAR=Transmission_AAR_Adjustment(hourly_temp); %Calculates hourly temperature adjustments

%The following values were changed for the transmission sensitivity
%analyses
%Wind Farm 3
Branch(154,   5) = Branch(154,   5)*1;
Branch(155,   5) = Branch(155,   5)*1;
Branch(158,   5) = Branch(158,   5)*1;
Branch(159,   5) = Branch(159,   5)*1;
Branch(160,   5) = Branch(160,   5)*1;
Branch(163,   5) = Branch(163,   5)*1;
Branch(164,   5) = Branch(164,   5)*1;
Branch(167,   5) = Branch(167,   5)*1;

%Solar Farm 3
Branch(167,   5) = Branch(167,   5)*1;
Branch(169,   5) = Branch(169,   5)*1;
Branch(172,   5) = Branch(172,   5)*1;

%Transmission Limiting Branches
Branch(128,   5) = Branch(128,   5)*1;
Branch(129,   5) = Branch(129,   5)*1;
Branch(155,   5) = Branch(155,   5)*1;
Branch(37,    5) = Branch(37,    5)*1;
Branch(147,   5) = Branch(147,   5)*1;
Branch(153,   5) = Branch(153,   5)*1;
Branch(169,   5) = Branch(169,   5)*1;



%This was used for the full transmission system upgrade
Branch(:,5)= Branch(:,5) * 1;


%% --------------------------- Load_Gro_SUM ---------------------------- %%


Scaler_Load   = 1;

for t=1:Num_Hour
    Load_System_DAF_Dis(t, 1) = Scaler_Load*Load_System_DAF_Dis(t, 1);
end



%% ----------------------------- Calculates Load at each Bus ----------------------------- %%

for t = 1:Num_Hour
    for c = 1:Num_Bus_Load
        Load_Bus_DAF_Dis(t, c) = Load_System_DAF_Dis(t).*Load_Bus_Weight(c);
       
    end
end

%
%% -------------------------------- Renewable Power Production-------------------------------- %%


[Wind_Farm_DAF_Dis, on_off_shore] = calculate_wind_power(hourly_onshore_wind, hourly_offshore_wind, Scaler_Wind);
Solar_Farm_DAF_Dis = calculate_solar_power(hourly_irr, hourly_temp, Scaler_Solar);

for t=1:Num_Hour
    Wind_SUM_DAF_Dis = sum(Wind_Farm_DAF_Dis(t,:));
    Solar_SUM_DAF_Dis = sum(Solar_Farm_DAF_Dis(t,:));
end

Num_Wind     = size(Wind_Farm_DAF_Dis, 2);
Num_Solar    = size(Solar_Farm_DAF_Dis, 2);

% Wind Farm Bus Locations
Wind_01_Bus = 5;
Wind_02_Bus = 49;
Wind_03_Bus = 100;
Wind_Bus = [Wind_01_Bus; Wind_02_Bus; Wind_03_Bus];

%Solar Farm Bus Locations
Solar_01_Bus = 30;
Solar_02_Bus = 60;
Solar_03_Bus = 106;
Solar_Bus = [Solar_01_Bus; Solar_02_Bus; Solar_03_Bus];



%% --------------------------- Battery Storage --------------------------- %%


Num_Batt = size(batt_data,1);

%Battery buses (Assumes 3 batteries)
Battery_01_Bus = 25;
Battery_02_Bus = 48;
Battery_03_Bus = 92;

Battery_Bus = [Battery_01_Bus; Battery_02_Bus; Battery_03_Bus];


%% ------------------------------- PTDF -------------------------------- %%


PTDF_Gen=zeros(Num_Branch, Num_Gen);
PTDF_Load=zeros(Num_Branch, Num_Bus_Load);
PTDF_Wind=zeros(Num_Branch, Num_Wind);
PTDF_Solar=zeros(Num_Branch, Num_Solar);
PTDF_Batt=zeros(Num_Branch, Num_Batt);

for i = 1:Num_Gen
    PTDF_Gen(:,i) = PTDF(:, Gen_Capacity(i, 2));
end
for i = 1:Num_Bus_Load
    PTDF_Load(:,i) = PTDF(:, Load_Bus_Index(i, 1));
end
for i = 1:Num_Wind
    PTDF_Wind(:,i) = PTDF(:, Wind_Bus(i, 1));
end
for i = 1:Num_Solar
    PTDF_Solar(:,i) = PTDF(:, Solar_Bus(i, 1));
end
for i = 1:Num_Batt
    PTDF_Batt(:,i) = PTDF(:, Battery_Bus(i, 1));
end
disp('Modeling...');
%
%% ------------------------------- PWL -------------------------------- %%
Seg_Range = (Gen_Capacity(:, 3) - Gen_Capacity(:, 4))/Num_Seg; %For all generators: Max Gen - (Min Gen/#Segments)

%Pre-defines matrices [# Generators, #System Segements +1]
BK_Point_Gen = zeros(Num_Gen, Num_BKPoint); 
BK_Point_Cost = zeros(Num_Gen, Num_BKPoint);
Gen_Price_PWL_Intercept = zeros(Num_Gen, Num_Seg);
Gen_Price_PWL_Slope = zeros(Num_Gen, Num_Seg);


%Produces a quadratic price curve for each generator
for i = 1:Num_Gen    
    for z = 1:Num_BKPoint
        BK_Point_Gen(i, z) = Gen_Capacity(i, 4) + (z-1)*Seg_Range(i, 1); 
        BK_Point_Cost(i, z) = Gen_Price(i, 2)...
                            + Gen_Price(i, 3).*BK_Point_Gen(i, z)...
                            + Gen_Price(i, 4).*BK_Point_Gen(i, z).^2;
    end
end


for i = 1:Num_Gen                   
    for k = 1:Num_Seg
        Gen_Price_PWL_Slope(i, k) = (BK_Point_Cost(i, k+1) - BK_Point_Cost(i, k))/Seg_Range(i);
        Gen_Price_PWL_Intercept(i, k) = BK_Point_Cost(i, k) - Gen_Price_PWL_Slope(i, k)*BK_Point_Gen(i, k) ;
    end
end

