function [hourly_AAR] = Transmission_AAR_Adjustment(hourly_temp)

set_points = [10,15,20,25,30,35,40,45,50];
AAR = [1.2,1.15,1.11,1.05,1.00,0.94,0.88,0.82,0.75];

hourly_AAR = zeros(length(hourly_temp),1);

for i=1:length(hourly_temp)

    if hourly_temp(i) < set_points(1)
        hourly_AAR(i) = AAR(1);
    elseif hourly_temp(i) < set_points(2)
        hourly_AAR(i) = AAR(2);
    elseif hourly_temp(i) < set_points(3)
        hourly_AAR(i) = AAR(3);
    elseif hourly_temp(i) < set_points(4)
        hourly_AAR(i) = AAR(4);
    elseif hourly_temp(i) < set_points(5)
        hourly_AAR(i) = AAR(5);
    elseif hourly_temp(i) < set_points(6)
        hourly_AAR(i) = AAR(6);
    elseif hourly_temp(i) < set_points(7)
        hourly_AAR(i) = AAR(7);
    elseif hourly_temp(i) < set_points(8)
        hourly_AAR(i) = AAR(8);
    else
        hourly_AAR = AAR(9);
    end

end

