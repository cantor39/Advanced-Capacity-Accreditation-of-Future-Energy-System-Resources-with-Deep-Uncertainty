%This function is used to sample whether or not each generator at each time
%will experience a forced outage. In this context, if FOR = 1, then the
%generator is experiencing a forced outage


function [hourly_outages] = sample_gen_for_out(For_Out_Rate, Num_Gen, Num_Hour)

hourly_outages = zeros(Num_Gen, Num_Hour);

for i = 1:Num_Gen
    for t = 1:Num_Hour
        if (For_Out_Rate(i,1)>rand)
            hourly_outages(i,t)=1; 
        else
            hourly_outages(i,t)=0;
        end
    end
end