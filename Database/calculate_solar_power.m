%Column   #1            #2              #3                  #4              
%Data     Farm Number   Panel Model     Panel Capacity      Farm Capacity   
%Column   #5                                                     #6                 
%Data     Nominal Operating Cell Temperature (NOCT) (Celcius)    temperature degredation coeffient (%/Celcius)
%Column   #7                                                                     
%Data     System Efficiency

function [solar_farm_output] = calculate_solar_power(irr_data, temp_air_data, Scaler_Solar)

panel_data = readmatrix('/home/ifrost/cantor39/ELCC Work/UC/UC/v2 - Rolling Horizon/Database/solar_farm_parameters.csv');
%panel_data = panel_data(2:4, :);

temp_cell=zeros(length(irr_data), size(panel_data, 1));
pv_cell_output=zeros(length(irr_data), size(panel_data, 1));
solar_farm_output=zeros(length(irr_data), size(panel_data, 1));

for c = 1:size(panel_data, 1)

    for t=1:length(irr_data)

        temp_cell(t, c) = temp_air_data(t) + (((panel_data(c,5)-20)/800)*irr_data(t)); %Equation 8 from Pat's paper

        pv_cell_output(t, c) = panel_data(c,3) * (irr_data(t)/1000) * (1-(panel_data(c,6)/100*(temp_cell(t,c)-25))); %Equation 9 from Pat's paper

        if pv_cell_output(t,c)>panel_data(c,3) 

            pv_cell_output(t,c)=panel_data(c,3); %if the panel output would be greater than its maximum limit, reduce it to that limit

        end

        solar_farm_output(t,c) = pv_cell_output(t,c) * (panel_data(c,4)/panel_data(c,3)) * panel_data(c,7) * Scaler_Solar(c)/1000; % PV Output * (Farm Capacity/Panel Capacity) * System Efficiency * User Input Scaling Factor / 1000
        

    end
end
