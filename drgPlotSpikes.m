%This program will plot the shape of the spikes in each channel of the
%tetrode
clear all
close all

%Enter the input file, which unit you want to plot, etc

%Enter the file generated by drgReadWilder
%load('/Users/restrepd/Documents/Projects/Ananawakebehaving/omp/baseline_files_chr20p75.mat');
load('/Users/restrepd/Documents/Projects/Ananawakebehaving/gngalwd/drs_files_all_BFRalwdp75.mat');

%load('/Users/restrepd/Documents/Projects/Shane/Shane Temp folder/100515-623-D13-S+S-iso_drg.mat')
%Enter the event type
%   Events 1 through 6
%     'TStart'    'OdorOn'    'Hit'    'HitE'    'S+'    'S+E'
%   Events 7 through 13
%     'Miss'    'MissE'    'CR'    'CRE'    'S-'    'S-E'    'FA'
%   Events 14 through 19
%     'FAE'    'Reinf'    'L+'    'L-' 'S+TStart' 'S-TStart'
%   'S+TStart' = 18
evTypeNo=2;

%Enter the unit number
unitNo=207;

%Enter electrodes you want to plot peak to valley
electrode_x=2;
electrode_y=4;
    
% if unitNo==4
%     electrode_x=2;
%     electrode_y=3;
% end
% 
% if unitNo==395
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==439
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% if unitNo==378
%     electrode_x=2;
%     electrode_y=3;
% end
% 
% if unitNo==70
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==14
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% 
% if unitNo==15
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==17
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==54
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==57
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==156
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==8
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% if unitNo==37
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% if unitNo==38
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% if unitNo==153
%     electrode_x=3;
%     electrode_y=4;
% end
%Do not change below, unless you want to modify the program
offset_factor=4;

sessionNo=drg.unit(unitNo).sessionNo;
tetrode=drg.unit(unitNo).channel;
trial_window=20;

start_pre=1;
end_pre=24;

bin_size=0.10;
nobins=fix((drg.time_post-drg.time_pre)/bin_size);

%Find the units in this tetrode
ii_start=unitNo;
if ii_start<1
    ii_start=1;
end

ii_end=unitNo+10;
if ii_end>drg.noUnits
    ii_end=drg.noUnits;
end

units=[];
no_units_in_channel=0;
for ii=ii_start:ii_end
    if (drg.unit(ii).sessionNo==sessionNo)&(drg.unit(ii).channel==drg.unit(unitNo).channel)
        no_units_in_channel=no_units_in_channel+1;
        units(no_units_in_channel)=ii;
    end
end



textout='drgPlotSpikes'
tic

%This is dg
bytes_per_native=2;     %Note: Native is unit16
size_per_ch_bytes=drg.draq_p.sec_per_trigger*drg.draq_p.ActualRate*bytes_per_native;
no_unit16_per_ch=size_per_ch_bytes/bytes_per_native;
low_filter=1000;
high_filter=5000;

jt_f=drg.fls{sessionNo};
if drg.session(sessionNo).dgordra==1
    dgfile=[drg.drg_directory jt_f(10:end-4) '.dra'];
else
    dgfile=[drg.drg_directory jt_f(10:end-4) '.dg'];
end
fdg=fopen(dgfile,'r'); 
      
% Enter maximum and minimum time differences to enter in
% cross-correlogram as well as the bin size
for no_unitspc=1:no_units_in_channel
    unit(no_unitspc).all_sps=[];;
end

no_spikes_per_block=zeros(4,no_units_in_channel,2);

for no_unitspc=1:no_units_in_channel
    szblocks=size(drg.session(sessionNo).blocks);
    
    spikes1=[];
    spikes1=drg.unit(units(no_unitspc)).spike_times;
    
    
    % %Find out how many trials are not excluded
    num_trials = 0;
     per_u_BFR=[];
    for evNo=1:drg.session(sessionNo).events(evTypeNo).noTimes
        excludeTrial=drgExcludeTrial(drg,drg.unit(units(no_unitspc)).channel,drg.session(sessionNo).events(evTypeNo).times(evNo),sessionNo);
        if excludeTrial==0
            num_trials=num_trials+1;
            these_spikes=[];
            these_spikes=(spikes1>drg.session(sessionNo).events(evTypeNo).times(evNo)+drg.time_pre)&...
                (spikes1<=drg.session(sessionNo).events(evTypeNo).times(evNo)+drg.time_post);
            these_spikes1=[];
            these_spikes1=spikes1(these_spikes)-(drg.session(sessionNo).events(evTypeNo).times(evNo)+drg.time_pre);
            PSTHSplus=zeros(1,nobins);
            for spk=1:length(these_spikes1)
                this_bin=ceil(these_spikes1(spk)/bin_size);
                PSTHSplus(1,this_bin)=PSTHSplus(1,this_bin)+1;
            end %for spk
            
            
            PSTHSplus=PSTHSplus/bin_size;
            
            %Now enter the BFR per unit
            per_u_BFR(num_trials)=mean(PSTHSplus(1,start_pre:end_pre));
            
        end
    end
    
    trials=[1:length(per_u_BFR)];
    to_sort=[per_u_BFR' trials'];
    sorted_trials=sortrows(to_sort,1);
    
    
    plot_y=szblocks(1)*10+num_trials*5+10;
    previous_block=-1;
    
    
    
    hold on;
    
    
    
    %Plot spikes
    
    trNo=0;
    block1BFR=[];
    block2BFR=[];
    for evNo=1:drg.session(sessionNo).events(evTypeNo).noTimes
        
        excludeTrial=drgExcludeTrial(drg,drg.unit(units(no_unitspc)).channel,drg.session(sessionNo).events(evTypeNo).times(evNo),sessionNo);
        
        if excludeTrial==0
            trNo=trNo+1
            
            blockNo=-1;
            
            if find(sorted_trials(:,2)==trNo)<=trial_window
                %Save these as spikes in the first block
                blockNo=1;
                block1BFR=[block1BFR sorted_trials(find(sorted_trials(:,2)==trNo),1)];
            end
            
            if find(sorted_trials(:,2)==trNo)>=num_trials-trial_window+1
                %Save these as spikes in the last block
                blockNo=2;
                block2BFR=[block2BFR sorted_trials(find(sorted_trials(:,2)==trNo),1)];
            end
            
            this_event_time=drg.session(sessionNo).events(evTypeNo).times(evNo);
            
            %         blockNo=-1;
            %         for ii=1:szblocks(1)
            %
            %             if ( (drg.session(sessionNo).blocks(ii,1)<this_event_time)&(drg.session(sessionNo).blocks(ii,2)>this_event_time) )
            %                 blockNo=ii;
            %             end
            %         end
            %
            %         x=1:25;
            %         if (blockNo~=previous_block)
            if blockNo~=-1
                trial_no=find(drg.session(sessionNo).start_times<drg.session(sessionNo).events(evTypeNo).times(evNo),1,'last');
                trial_offset=drg.session(sessionNo).no_chans*size_per_ch_bytes*(trial_no-1);
                
                
                
                %Get spikes for all electrodes in this tetrode
                these_iis=[];
                these_iis=find((spikes1>this_event_time+drg.time_pre)&(spikes1<this_event_time+drg.time_post));
                for electrode=4*(tetrode-1)+1:4*tetrode
                    
                    fseek(fdg, (electrode-1)*size_per_ch_bytes+trial_offset, 'bof');
                    
                    data=fread(fdg,no_unit16_per_ch,'uint16');
                    [b,a] = butter(2,[low_filter/(drg.draq_p.ActualRate/2) high_filter/(drg.draq_p.ActualRate/2)]);
                    data =filtfilt(b,a,data);
                    
                    spikes=[];
                    
                    
                    
                    for ii=1:length(these_iis)
                            ii_spike=ceil((spikes1(these_iis(ii))-drg.session(sessionNo).start_times(trial_no))*drg.draq_p.ActualRate);
                            spikes(ii,:)=data(ii_spike-12:ii_spike+12);
                            unit(no_unitspc).all_sps=[unit(no_unitspc).all_sps data(ii_spike-12:ii_spike+12)'];
                    end
                    %                     figure(electrode)
                    %                 x=x+30;
                    
                    
                    size_spikes=size(spikes);
                    
                    all_spikes(no_unitspc,electrode-4*(tetrode-1),blockNo,1:25,no_spikes_per_block(electrode-4*(tetrode-1),no_unitspc,blockNo)+1:no_spikes_per_block(electrode-4*(tetrode-1),no_unitspc,blockNo)+size_spikes(1))=spikes';
                    actual_electrode(electrode-4*(tetrode-1))=electrode;
                    no_spikes_per_block(electrode-4*(tetrode-1),no_unitspc,blockNo)=no_spikes_per_block(electrode-4*(tetrode-1),no_unitspc,blockNo)+size_spikes(1);
                     
                end
                
                number_of_spikes=length(these_iis)
                
            end
        end %if drsExcludeTrial
    end %for evNo
    %y_offset=(max(szevents))*1.2;
    %y_offset=30;
end

for no_unitspc=1:no_units_in_channel
    SD_all_spc(no_unitspc)=std(unit(no_unitspc).all_sps);
end
SD_max_all=max(SD_all_spc);

 max_these_spikes=zeros(no_units_in_channel,4,2,max(max(max(no_spikes_per_block))));
 min_these_spikes=zeros(no_units_in_channel,4,2,max(max(max(no_spikes_per_block))));
            
for no_unitspc=1:no_units_in_channel
    y=0;
    y_offset=offset_factor*SD_max_all;
    x=1:25;
    
    figure(no_unitspc)
    hold on
    
    %det min + Max, calc difference (max-min), then set y offset larger than max-min.
   
    
    for blocks=1:2
        %tetrode=1:4;
        y=y+y_offset;
        for electrode=1:4
            x=x+25;
            mean_these_spikes=zeros(1,25);
            SD_these_spikes=zeros(1,25);
            if drg.session(sessionNo).doSubtract==0
                mean_these_spikes(1,:)=mean(all_spikes(no_unitspc,electrode,blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks)),5);
                SD_these_spikes(1,:)=std(all_spikes(no_unitspc,electrode,blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks)),1,5);
                max_these_spikes(no_unitspc,electrode,blocks,1:no_spikes_per_block(electrode,no_unitspc,blocks))=max(all_spikes(no_unitspc,electrode,blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks)));
                min_these_spikes(no_unitspc,electrode,blocks,1:no_spikes_per_block(electrode,no_unitspc,blocks))=min(all_spikes(no_unitspc,electrode,blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks)));
            else
                %these_spikes(:,:)=all_spikes(electrode,blocks,:,1:no_spikes (blocks));
                sub_electrode=drg.session(sessionNo).subtractCh(actual_electrode(electrode));
                mean_these_spikes(1,:)=mean(all_spikes(no_unitspc,electrode,blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks))-...
                    all_spikes(no_unitspc,sub_electrode-4*(tetrode-1),blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks)),5);
                SD_these_spikes(1,:)=std(all_spikes(no_unitspc,electrode,blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks))-...
                    all_spikes(no_unitspc,sub_electrode-4*(tetrode-1),blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks)),1,5);
                max_these_spikes(no_unitspc,electrode,blocks,1:no_spikes_per_block(electrode,no_unitspc,blocks))=max(all_spikes(no_unitspc,electrode,blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks))-...
                    all_spikes(no_unitspc,sub_electrode-4*(tetrode-1),blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks)));
                min_these_spikes(no_unitspc,electrode,blocks,1:no_spikes_per_block(electrode,no_unitspc,blocks))=min(all_spikes(no_unitspc,electrode,blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks))-...
                    all_spikes(no_unitspc,sub_electrode-4*(tetrode-1),blocks,:,1:no_spikes_per_block(electrode,no_unitspc,blocks)));
            end
            if length(mean_these_spikes~=0)
                if no_unitspc==1
                    plot(x,mean_these_spikes+y+SD_these_spikes,'-','Color',[1,  0.7,  0.7 ]);
                    plot(x,mean_these_spikes+y-SD_these_spikes,'-','Color',[1,  0.7,  0.7 ]);
                    plot(x,mean_these_spikes+y,'-r','LineWidth',2);
                else
                    if no_unitspc==2
                        plot(x,mean_these_spikes+y+SD_these_spikes,'-','Color',[0.7,  0.7,  1]);
                        plot(x,mean_these_spikes+y-SD_these_spikes,'-','Color',[0.7,  0.7,  1]);
                        plot(x,mean_these_spikes+y,'-b','LineWidth',2);
                    else
                        plot(x,mean_these_spikes+y+SD_these_spikes,'-','Color',[0.7,  1,  0.7]);
                        plot(x,mean_these_spikes+y-SD_these_spikes,'-','Color',[0.7,  1,  0.7]);
                        plot(x,mean_these_spikes+y,'-g','LineWidth',2);
                    end
                end
            end
            
        end
        %     plot(all_spikes);
        %     hold on;
        
        x=1:25;
    end
    ylim([0+0.25*SD_max_all y+y_offset-0.25*SD_max_all])
    
    title(['Spike shape in the first and last ' num2str(length(mean_these_spikes)) ' trials'])
    xlabel(['Unit No ' num2str(units(no_unitspc))])
    ylabel('Bottom: first block, top: last block')
end

%Now plot the clusters
%     electrode_x=2;
%     electrode_y=4;
%     
% if unitNo==4
%     electrode_x=2;
%     electrode_y=3;
% end
% 
% if unitNo==395
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==439
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% if unitNo==378
%     electrode_x=2;
%     electrode_y=3;
% end
% 
% if unitNo==70
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==14
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% 
% if unitNo==15
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==17
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==54
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==57
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==156
%     electrode_x=2;
%     electrode_y=4;
% end
% 
% if unitNo==8
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% if unitNo==37
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% if unitNo==38
%     electrode_x=3;
%     electrode_y=4;
% end
% 
% if unitNo==153
%     electrode_x=3;
%     electrode_y=4;
% end

for blocks=2:-1:1
    figure(no_units_in_channel+blocks)
    hold on
    for no_unitspc=1:no_units_in_channel
        x=zeros(1,no_spikes_per_block(electrode_x,no_unitspc,blocks));
        x(1,:)=max_these_spikes(no_unitspc,electrode_x,blocks,1:no_spikes_per_block(electrode_x,no_unitspc,blocks))-...
            min_these_spikes(no_unitspc,electrode_x,blocks,1:no_spikes_per_block(electrode_x,no_unitspc,blocks));
        y=zeros(1,no_spikes_per_block(electrode_x,no_unitspc,blocks));
        y(1,:)=max_these_spikes(no_unitspc,electrode_y,blocks,1:no_spikes_per_block(electrode_y,no_unitspc,blocks))...
            -min_these_spikes(no_unitspc,electrode_y,blocks,1:no_spikes_per_block(electrode_y,no_unitspc,blocks));
        if no_unitspc==1
            
            plot(x,y,'.r','MarkerFace','r');
            
        else
            if no_unitspc==2
                plot(x,y,'.b','MarkerFace','b');
            else
                plot(x,y,'.g','MarkerFace','g');
            end
        end
    end
    if blocks==1
        title('Clusters in the first 10 trials')
    else
        title('Clusters in the last 10 trials')
    end
    xlabel(['Peak to valley for electrode #' num2str(electrode_x)])
    ylabel(['Peak to valley for electrode #' num2str(electrode_y)])
end

%Now plot the clusters in the same figure


% figure(no_units_in_channel+3)
% hold on
% 
% for blocks=1:2
% 
%    
%     for no_unitspc=1:no_units_in_channel
%         x=zeros(1,no_spikes_per_block(electrode_x,no_unitspc,blocks));
%         x(1,:)=max_these_spikes(no_unitspc,electrode_x,blocks,1:no_spikes_per_block(electrode_x,no_unitspc,blocks))-...
%             min_these_spikes(no_unitspc,electrode_x,blocks,1:no_spikes_per_block(electrode_x,no_unitspc,blocks));
%         y=zeros(1,no_spikes_per_block(electrode_x,no_unitspc,blocks));
%         y(1,:)=max_these_spikes(no_unitspc,electrode_y,blocks,1:no_spikes_per_block(electrode_y,no_unitspc,blocks))...
%             -min_these_spikes(no_unitspc,electrode_y,blocks,1:no_spikes_per_block(electrode_y,no_unitspc,blocks));
%       
%             if blocks==1
%                 plot(x,y,'.b');
%             else
%                 plot(x,y,'.r');
%             end
%         
%     end
%     
% end
% 
% title('Clusters. Blue:first 10 trials, Red: last 10')
% 
% xlabel(['Peak to valley for electrode #' num2str(electrode_x)])
% ylabel(['Peak to valley for electrode #' num2str(electrode_y)])

this_file=dgfile

mean_low_BFR=mean(block1BFR)
mean_high_BFR=mean(block2BFR)
fclose(fdg)

toc