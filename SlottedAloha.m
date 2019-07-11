N=60;
Ts=0.0002; %Ts= 1200/6000000= 0.2msec
lamda= 250:200:2050; %[packet/sec] 
lamda2= lamda.*Ts; % lamda2=arrival rate=0.05:0.03:0.32 [packet/slot]
s = zeros(1, length(lamda));
g = zeros(1, length(lamda));
d = zeros(1, length(lamda));

for l=1:1:length(lamda)
    %TIMING PARAMETERS (PART 1)
    num_arrival_per_station = 1000000;
    interarrival_time= exprnd(1/(lamda2(l)), N, num_arrival_per_station); %[slot]
    arrival_schedule= cumsum(interarrival_time,2); %cumsum:Cumulative sumcollapse. B = cumsum(A,dim)
    %this double loop method works but very inefficient
    % arrival_schedule= zeros(N,num_arrival_per_station);
    % for n =1:N
    %     for i = 1:num_arrival_per_station
    %         arrival_schedule(n, i) = sum(interarrival_time(n, 1:i));
    %     end
    % end
    retransmission_schedule= zeros(1,N);
    simulation_time=1000000;
    current_time_slot=1;
    
    %DIFFERENT TRANSMIT INDICATORS (PART 2)
    transmit_status_indicator = zeros(1,N) ; % 0 for not transmitting, 1 for transmitting
    retransmit_status = zeros(1,N) ; % 0 for no retransmission, 1 for pending retransmission
    retransmission_attempt = zeros(1,N) ; %if pkt tx fail once becomes 1 , fail twice becomes 2, and so on ...useful for updating window for retransmission scheduling
    max_retransmission_attempt = 11;
    
    %%STATS PARAMETERS (PART 3)
    total_transmissions = 0;
    total_successful_transmissions = 0 ; %use for throughput computation
    total_delay_time = 0 ; %use for average delay computation
    packet_index=ones(1, N);
    
    while (current_time_slot < simulation_time)
        %%FUNCTION: check_whether_each_station_transmits_in_this_slot (PART 4)
        for j= 1:1:N
            %retransmission_schedule(1,j)
            if (retransmit_status(1,j)==1) %check if status is retransmit
                if (retransmission_schedule(1,j)==current_time_slot) %check if retransmission count down timer arrived
                    transmit_status_indicator(1,j)=1;
                    j_tx=j;
                end
            elseif (all(retransmit_status==0)==1) %no pendiong retranmission
                if (current_time_slot >= arrival_schedule(j,packet_index(1,j))) % there's a new packet
                    transmit_status_indicator(1,j)=1;
                    j_tx=j;
                end
            end
        end
        % Number of stations which transmit in this slot
        num_transmitting_stations = sum(transmit_status_indicator);
        total_transmissions = total_transmissions + num_transmitting_stations;
        %%FUNCTION: CHECK_SUCCESSFUL_OR_FAILED_TRANSMISSION (PART 5)
        if (num_transmitting_stations==1) %if transmission succeed
            total_successful_transmissions = total_successful_transmissions+1;
            % get packet arrival time. Based on difference between transmitted time and original arrival time, we can get this_unique_packet_delay_time
            this_unique_packet_delay_time_after_successful_tx= current_time_slot - arrival_schedule(j_tx, packet_index(1,j_tx));
            total_delay_time = total_delay_time + this_unique_packet_delay_time_after_successful_tx;
            transmit_status_indicator(1,j_tx) = 0; %update tx status
            retransmit_status(1,j_tx) = 0; %update re-tx status
            %update which next packet to be served, do something with arrival_schedule?
            packet_index(1,j_tx)= packet_index(1,j_tx) + 1; %increase packet index at the station has packet successfully transmitted
            retransmission_attempt(1,j_tx)=0;
            retransmission_schedule(1,j_tx)=0;
        else %if transmission fails
            for j=1:1:N
                retransmit_status(1,j) = transmit_status_indicator(1,j);
                if ((retransmit_status(1,j)==1)&&(retransmission_schedule(1,j)<=current_time_slot))
                    %if (retransmit_status(1,j)==1)
                    retransmission_schedule(1,j) = current_time_slot + randi([1, 2^(retransmission_attempt(1,j))+1],1);
                    retransmission_attempt(1,j) = retransmission_attempt(1,j)+1;
                    if (retransmission_attempt(1,j) > max_retransmission_attempt)
                        %discard the packet and serving next packet
                        packet_index(1,j)= packet_index(1,j) + 1;
                        retransmission_attempt(1,j)=0;
                        retransmission_schedule(1,j)=0;
                        retransmit_status(1,j)=0;
                    end
                    transmit_status_indicator(1,j)=0;
                end
            end
        end
        current_time_slot = current_time_slot + 1 ;
    end %belongs to while loop of incrementing simulation time
    
    %Harvest STATISTICS 3 (PART 5) : process data that you obtain earlier
    s(1,l) = total_successful_transmissions/simulation_time; %normalized throughput rate [packet/slot]
    g(1,l) = total_transmissions/simulation_time; %normalized channel loading [packet/slot]
    d(1,l) = total_delay_time/total_successful_transmissions; %mean packet delay [slot/packet]
    %Use fprintf to directly display the text without creating a variable. However, to terminate the display properly, you must end the text with the newline (\n) metacharacter.
    fprintf(['\n Offered load (lamda2)[packet/slot]: %.3f packet/slot,', ...
        '\n Normalized throughput (s)[packet/slot]: %.3f packet/slot,', ...
        '\n Normalized channel loading (g)[packet/slot]: %.3f packet/slot,', ...
        '\n Mean packet delay (d)[slot/packet]: %.3f slot/packet \n'], lamda2(l), s(1,l), g(1,l), d(1,l));
end
figure(1)
plot(g,s)
title('s vs g Performance Curve')
xlabel('Normalized channel loading (g)[packet/slot]') 
ylabel('Normalized throughput (s)[packet/slot]')

figure(2)
plot(s,d)
title('d vs s Performance Curve')
xlabel('Normalized throughput (s)[packet/slot]') 
ylabel('Mean packet delay (d)[slot/packet]')

figure(3)
plot(lamda,d)
title('d vs lamda Performance Curve')
xlabel('Offered load (lamda)[packet/sec]') 
ylabel('Mean packet delay (d)[slot/packet]')
