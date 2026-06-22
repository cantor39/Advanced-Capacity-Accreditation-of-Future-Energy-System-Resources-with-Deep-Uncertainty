
function [For_Out_Rate] = calculate_thermal_outages(Unit_Gas, Unit_Oil, Unit_Coal, hourly_temp, Num_Hour, Num_Gen)


For_Out_Rate = zeros(Num_Hour, Num_Gen);



for t=1:Num_Hour
    for c=1:length(Unit_Gas)
    %function: = 2E-07x4 - 1E-05x3 + 0.0002x2 - 0.0017x + 0.0318

        For_Out_Rate(t, Unit_Gas(c))= (2E-7)*hourly_temp(t)^4 - (1E-5)*hourly_temp(t)^3 + 0.0002*hourly_temp(t)^2 - 0.0017*hourly_temp(t)^1 + 0.0318;
        
        if For_Out_Rate(t,Unit_Gas(c))>1

            For_Out_Rate(t, Unit_Gas(c)) = 1; % Cap the max output rate at 1

        elseif For_Out_Rate(t,Unit_Gas(c))<0

            For_Out_Rate(t, Unit_Gas(c)) = 0; % Cap the minoutput rate at 0

        end

    end

    for c=1:length(Unit_Oil)
    %6E-09x4 - 2E-06x3 + 0.0002x2 - 0.0029x + 0.1163

        For_Out_Rate(t, Unit_Oil(c))=(6E-09)*hourly_temp(t)^4 - (2E-6)*hourly_temp(t)^3 + 0.0002*hourly_temp(t)^2 - 0.0029*hourly_temp(t)^1 + 0.1163;

        if For_Out_Rate(t,Unit_Oil(c))>1

            For_Out_Rate(t, Unit_Oil(c)) = 1; % Cap the max output rate at 1

        elseif For_Out_Rate(t,Unit_Oil(c))<0

            For_Out_Rate(t, Unit_Oil(c)) = 0; % Cap the minoutput rate at 0

        end



    end

    for c=1:length(Unit_Coal)
    %6E-08x4 - 2E-06x3 + 6E-05x2 - 0.0013x + 0.0909

        For_Out_Rate(t, Unit_Coal(c))=(6E-08)*hourly_temp(t)^4 - (2E-6)*hourly_temp(t)^3 + (6E-5)*hourly_temp(t)^2 - 0.0013*hourly_temp(t)^1 + 0.0909;

        if For_Out_Rate(t,Unit_Coal(c))>1

            For_Out_Rate(t, Unit_Coal(c)) = 1; % Cap the max output rate at 1

        elseif For_Out_Rate(t,Unit_Coal(c))<0

            For_Out_Rate(t, Unit_Coal(c)) = 0; % Cap the minoutput rate at 0

        end


    end

end
