function drgAnalysisBatchLFP(handles)

%This function displays the LFP power spectrum for drgRunBatch-generated
%data

%Which analysis is performed is determined by the value enterd in the
%variable which_display:
%
%
% 1 ERP analysis compare auROC in the last few trials of pre with first few trials of post
%
% 2 Generate delta LFP power and auROC for reversal figure for Daniel's paper
%
% 3 For a subset of first files for events 1 and 2 plot the LFP bandwide spectrum,
%   LFP power histograms for different bandwidths for each electrode and LFP auROCs.
%   To generate Fig. 2 for Daniels' LFP power paper enter the proficient files
%
% 4 Generate LFP power auROC for Fig. 3 for Daniel's paper. first vs last.
%
%
% 5 Compare auROC in the last few trials of pre with first few trials of post
%    Used for old Fig. 4 of Daniel's paper with acetoethylben_electrode9202017.mat
%
% 6 For a subset of first files for events 1 and 2 plot the ERP LFP bandwide spectrum,
%   ERP LFP power histograms for different bandwidths for each electrode and ERP LFP auROCs.
%
% 7 Generate ERP LFP power auROC. first vs last.
%
% 8 Compare auROC for ERP LFP in the last few trials of pre with first few trials of post
%   Used for New Fig. 7 of Daniel's paper
%
% 9 Compare auROC for power LFP in two percent windows for all of the files 
%
% 10 Compare auROC for power LFP for two groups (e.g. NRG1 vs control)
% within one precent window
%
% 11 Compare auROC for ERP LFP powerin between two percent correct windows
%
% 12 Justin's analysis of LFP power differences for naive and proficient
% mice

%% Read the BatchParameters
[parsFileName,parsPathName] = uigetfile({'drgLFPBatchAnalPars*.m'},'Select the .m file with all the parameters for LFP batch analysis');
fprintf(1, ['\ndrgAnalysisBatchLFP run for ' parsFileName '\n\n']);

addpath(parsPathName)
eval(['handles_pars=' parsFileName(1:end-2) ';'])
handles.parsFileName=parsFileName;
handles.parsPathName=parsPathName;


winNo=handles_pars.winNo;
which_display=handles_pars.which_display;
eventType=handles_pars.eventType;
evTypeLabels=handles_pars.evTypeLabels;
file_pairs=handles_pars.file_pairs;
trials_to_process=handles_pars.trials_to_process;
min_trials_per_event=handles_pars.min_trials_per_event;
shift_time=handles_pars.shift_time;
shift_from_event=handles_pars.shift_from_event;
grpre=handles_pars.grpre;
grpost=handles_pars.grpost;
file_label=handles_pars.file_label;
front_mask=handles_pars.front_mask;
output_suffix=handles_pars.output_suffix;
percent_windows=handles_pars.percent_windows;
if isfield(handles_pars,'which_electrodes')
   which_electrodes=handles_pars.which_electrodes;
end
files=handles_pars.files;

if ~isfield(handles_pars,'no_bandwidths')
    no_bandwidths=4;
    low_freq=[6 15 35 65];
    high_freq=[12 30 55 95];
    freq_names={'Theta','Beta','Low gamma','High gamma'};
else
    no_bandwidths=handles_pars.no_bandwidths;
    low_freq=handles_pars.low_freq;
    high_freq=handles_pars.high_freq;
    freq_names=handles_pars.freq_names;
end

refWin=handles_pars.refWin;


%% The code processing pairwise batch LFP starts here

close all
warning('off')


%Bandwidths

if exist('no_bandwidths')==0
    no_bandwidths=4;
    low_freq=[6 15 35 65];
    high_freq=[12 30 55 95];
    freq_names={'Theta','Beta','Low gamma','High gamma'};
end


event1=eventType(1);
event2=eventType(2);


%Ask user for the drgb output .mat file and load those data
[handles.drgb.outFileName,handles.PathName] = uigetfile('*.mat','Select the drgb output file');
load([handles.PathName handles.drgb.outFileName])


fprintf(1, ['\ndrgDisplayBatchLFPPowerPairwise run for ' handles.drgb.outFileName '\nwhich_display= = %d\n\n'],which_display);

switch which_display

    case {1,6,7,8,11}

        frequency=handles_drgb.drgb.lfpevpair(1).fERP;
        max_events_per_sec=(handles_drgb.drgbchoices.timeEnd(winNo)-handles_drgb.drgbchoices.timeStart(winNo))*handles_drgb.max_events_per_sec;
    otherwise
        frequency=handles_drgb.drgb.freq_for_LFPpower;
end



%These are the colors for the different lines

these_colors{1}='b';
these_colors{2}='r';
these_colors{3}='m';
these_colors{8}='g';
these_colors{5}='y';
these_colors{6}='k';
these_colors{7}='c';
these_colors{4}='k';

these_lines{1}='-b';
these_lines{2}='-r';
these_lines{3}='-m';
these_lines{8}='-g';
these_lines{5}='-y';
these_lines{6}='-k';
these_lines{7}='-c';
these_lines{4}='-k';

%Initialize the variables
%Get files and electrode numbers
for lfpodNo=1:handles_drgb.drgb.lfpevpair_no
    files_per_lfp(lfpodNo)=handles_drgb.drgb.lfpevpair(lfpodNo).fileNo;
    elec_per_lfp(lfpodNo)=handles_drgb.drgb.lfpevpair(lfpodNo).elecNo;
    window_per_lfp(lfpodNo)=handles_drgb.drgb.lfpevpair(lfpodNo).timeWindow;
end

switch which_display
    case 1
        %Compare auROC for ERP LFP in the last few trials of pre with first few trials of post
        %Used for New Fig. 5 of Daniel's paper
        no_dBs=1;
        delta_dB_power_pre=[];
        no_ROCs=0;
        ROCoutpre=[];
        ROCoutpost=[];
        p_vals_ROC=[];
        delta_dB_powerpreHit=[];
        no_hits=0;
        perCorr_pre=[];
        perCorr_post=[];
        group_pre=[];
        group_post=[];
        shift_ii=floor(length(handles_drgb.drgb.lfpevpair(1).out_times)/2)+1+shift_from_event;
        
        
        fprintf(1, ['Pairwise auROC analysis for ERP LFP power\n\n'],'perCorr_pre','perCorr_post')
        p_vals=[];
        for fps=1:no_file_pairs
            for elec=1:16
                
                lfpodNopre=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                lfpodNopost=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                
                
                if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNopre)))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNopost)))
                    
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNopre).log_P_tERP))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNopost).log_P_tERP))
                        
                        if (length(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(1,:))>=trials_to_process) &...
                                (length(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(1,:))>=trials_to_process)
                            
                            length_pre=length(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(1,:));
                            pre_mask=logical([zeros(1,length_pre-trials_to_process) ones(1,trials_to_process)]);
                            trials_in_event_preHit=(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(event1,:)==1);
                            trials_in_event_preCR=(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(event2,:)==1);
                            
                            trials_with_event_pre=(handles_drgb.drgb.lfpevpair(lfpodNopre).no_events_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNopre).no_events_per_trial<=max_events_per_sec)...
                                &(handles_drgb.drgb.lfpevpair(lfpodNopre).no_ref_evs_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNopre).no_ref_evs_per_trial<=max_events_per_sec);
                            
                            
                            length_post=length(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(1,:));
                            post_mask=logical([ones(1,trials_to_process) zeros(1,length_post-trials_to_process)]);
                            trials_in_event_postHit=(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(event1,:)==1);
                            trials_in_event_postCR=(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(event2,:)==1);
                            
                            trials_with_event_post=(handles_drgb.drgb.lfpevpair(lfpodNopost).no_events_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNopost).no_events_per_trial<=max_events_per_sec)...
                                &(handles_drgb.drgb.lfpevpair(lfpodNopost).no_ref_evs_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNopost).no_ref_evs_per_trial<=max_events_per_sec);
                            
                            
                            if (sum(trials_in_event_preHit&trials_with_event_pre&pre_mask)>=min_trials_per_event) & (sum(trials_in_event_preCR&trials_with_event_pre&pre_mask)>=min_trials_per_event) & ...
                                    (sum(trials_in_event_postHit&trials_with_event_post&post_mask)>=min_trials_per_event) & (sum(trials_in_event_postCR&trials_with_event_post&post_mask)>=min_trials_per_event)
                                
                                
                                %pre Hits
                                this_dB_powerpreHit=zeros(sum(trials_in_event_preHit&pre_mask),length(frequency));
                                this_dB_powerpreHit(:,:)=handles_drgb.drgb.lfpevpair(lfpodNopre).log_P_tERP(trials_in_event_preHit&pre_mask,:,shift_ii);
                                
                                
                                %pre CRs
                                this_dB_powerpreCR=zeros(sum(trials_in_event_preCR&pre_mask),length(frequency));
                                this_dB_powerpreCR(:,:)=handles_drgb.drgb.lfpevpair(lfpodNopre).log_P_tERP(trials_in_event_preCR&pre_mask,:,shift_ii);
                                
                                
                                %post Hits
                                this_dB_powerpostHit=zeros(sum(trials_in_event_postHit&post_mask),length(frequency));
                                this_dB_powerpostHit(:,:)=handles_drgb.drgb.lfpevpair(lfpodNopost).log_P_tERP(trials_in_event_postHit&post_mask,:,shift_ii);
                                
                                
                                %post CRs
                                this_dB_powerpostCR=zeros(sum(trials_in_event_postCR&post_mask),length(frequency));
                                this_dB_powerpostCR(:,:)=handles_drgb.drgb.lfpevpair(lfpodNopost).log_P_tERP(trials_in_event_postCR&post_mask,:,shift_ii);
                                
                                for bwii=1:no_bandwidths
                                    
                                    no_ROCs=no_ROCs+1;
                                    this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                    
                                    %Enter the pre Hits
                                    this_delta_dB_powerpreHit=zeros(sum(trials_in_event_preHit&pre_mask),1);
                                    this_delta_dB_powerpreHit=mean(this_dB_powerpreHit(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_preHit&pre_mask),1)=this_delta_dB_powerpreHit;
                                    roc_data(1:sum(trials_in_event_preHit&pre_mask),2)=zeros(sum(trials_in_event_preHit&pre_mask),1);
                                    
                                    %Enter pre CR
                                    total_trials=sum(trials_in_event_preHit&pre_mask)+sum(trials_in_event_preCR&pre_mask);
                                    this_delta_dB_powerpreCR=zeros(sum(trials_in_event_preCR&pre_mask),1);
                                    this_delta_dB_powerpreCR=mean(this_dB_powerpreCR(:,this_band),2);
                                    roc_data(sum(trials_in_event_preHit&pre_mask)+1:total_trials,1)=this_delta_dB_powerpreCR;
                                    roc_data(sum(trials_in_event_preHit&pre_mask)+1:total_trials,2)=ones(sum(trials_in_event_preCR&pre_mask),1);
                                    
                                    
                                    %Find pre ROC
                                    ROCoutpre(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCoutpre(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNopre).fileNo;
                                    ROCgroupNopre(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNopre).fileNo);
                                    ROCoutpre(no_ROCs).timeWindow=winNo;
                                    ROCbandwidthpre(no_ROCs)=bwii;
                                    auROCpre(no_ROCs)=ROCoutpre(no_ROCs).roc.AUC-0.5;
                                    p_valROCpre(no_ROCs)=ROCoutpre(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCoutpre(no_ROCs).roc.p];
                                    
                                    %Enter the post Hits
                                    this_delta_dB_powerpostHit=zeros(sum(trials_in_event_postHit&post_mask),1);
                                    this_delta_dB_powerpostHit=mean(this_dB_powerpostHit(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_postHit&post_mask),1)=this_delta_dB_powerpostHit;
                                    roc_data(1:sum(trials_in_event_postHit&post_mask),2)=zeros(sum(trials_in_event_postHit&post_mask),1);
                                    
                                    %Enter post CR
                                    total_trials=sum(trials_in_event_postHit&post_mask)+sum(trials_in_event_postCR&post_mask);
                                    this_delta_dB_powerpostCR=zeros(sum(trials_in_event_postCR&post_mask),1);
                                    this_delta_dB_powerpostCR=mean(this_dB_powerpostCR(:,this_band),2);
                                    roc_data(sum(trials_in_event_postHit&post_mask)+1:total_trials,1)=this_delta_dB_powerpostCR;
                                    roc_data(sum(trials_in_event_postHit&post_mask)+1:total_trials,2)=ones(sum(trials_in_event_postCR&post_mask),1);
                                    
                                    
                                    %Find post ROC
                                    ROCoutpost(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCoutpost(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNopost).fileNo;
                                    ROCgroupNopost(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNopost).fileNo);
                                    ROCoutpost(no_ROCs).timeWindow=winNo;
                                    ROCbandwidthpost(no_ROCs)=bwii;
                                    auROCpost(no_ROCs)=ROCoutpost(no_ROCs).roc.AUC-0.5;
                                    p_valROCpost(no_ROCs)=ROCoutpost(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCoutpost(no_ROCs).roc.p];
                                    
                                    if (auROCpost(no_ROCs)<0.3)&(auROCpre(no_ROCs)>0.4)&(ROCgroupNopre(no_ROCs)==1)&(ROCbandwidthpre(no_ROCs)==2)
                                        fprintf(1, ['Decrease in auROC for file No %d vs file No %d electrode %d bandwidth No: %d\n'],file_pairs(fps,1),file_pairs(fps,2),elec,bwii);
                                    end
                                    
                                    %Are the delta dB LFP's different?
                                    
                                    %Hit
                                    p_val(no_dBs,bwii)=ranksum(this_delta_dB_powerpreHit,this_delta_dB_powerpostHit);
                                    p_vals=[p_vals p_val(no_dBs,bwii)];
                                    groupNopre(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                    groupNopost(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                    events(no_dBs)=1;
                                    
                                    
                                    %CR
                                    p_val(no_dBs+1,bwii)=ranksum(this_delta_dB_powerpreCR,this_delta_dB_powerpostCR);
                                    p_vals=[p_vals p_val(no_dBs+1,bwii)];
                                    groupNopre(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                    groupNopost(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                    events(no_dBs+1)=2;
                                    
                                    if p_val(no_dBs,bwii)<0.05
                                        dB_power_changeHit(no_ROCs)=1;
                                    else
                                        dB_power_changeHit(no_ROCs)=0;
                                    end
                                    
                                    if p_val(no_dBs+1,bwii)<0.05
                                        dB_power_changeCR(no_ROCs)=1;
                                    else
                                        dB_power_changeCR(no_ROCs)=0;
                                    end
                                    
                                    %Plot the points and save the data
                                    if groupNopre(no_dBs)==1
                                        
                                        
                                        %Hit, all points
                                        delta_dB_powerpreHit(no_ROCs)=mean(this_delta_dB_powerpreHit);
                                        delta_dB_powerpostHit(no_ROCs)=mean(this_delta_dB_powerpostHit);
                                        
                                        
                                        %CR, all points
                                        delta_dB_powerpreCR(no_ROCs)=mean(this_delta_dB_powerpreCR);
                                        delta_dB_powerpostCR(no_ROCs)=mean(this_delta_dB_powerpostCR);
                                        
                                    else
                                        if groupNopre(no_dBs)==3
                                            
                                            %Hit, all points
                                            delta_dB_powerpreHit(no_ROCs)=mean(this_delta_dB_powerpreHit);
                                            delta_dB_powerpostHit(no_ROCs)=mean(this_delta_dB_powerpostHit);
                                            
                                            
                                            %CR, all points
                                            delta_dB_powerpreCR(no_ROCs)=mean(this_delta_dB_powerpreCR);
                                            delta_dB_powerpostCR(no_ROCs)=mean(this_delta_dB_powerpostCR);
                                            %                                             figure(bwii+4+12)
                                            %                                             hold on
                                            %                                             plot([3 4],[delta_dB_powerpreCR(no_ROCs) delta_dB_powerpostCR(no_ROCs)],'-o', 'Color',[0.7 0.7 0.7])
                                        end
                                    end
                                end
                                
                                no_dBs=no_dBs+2;
                                
                            else
                                
                                if (sum(trials_in_event_preHit&trials_with_event_pre&pre_mask)<min_trials_per_event)
                                    fprintf(1, ['%d trials with lick events in ' evTypeLabels{find(eventType==event1)} ' fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_preHit&trials_with_event_pre&pre_mask), min_trials_per_event,file_pairs(fps,1),elec);
                                end
                                
                                if (sum(trials_in_event_preCR&trials_with_event_pre&pre_mask)<min_trials_per_event)
                                    fprintf(1, ['%d trials with lick events in ' evTypeLabels{find(eventType==event2)} ' fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_preCR&trials_with_event_pre&pre_mask),event2, min_trials_per_event,file_pairs(fps,1),elec);
                                end
                                
                                if (sum(trials_in_event_postHit&trials_with_event_post&post_mask)<min_trials_per_event)
                                    fprintf(1, ['%d trials with lick events in ' evTypeLabels{find(eventType==event1)} ' fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_postHit&trials_with_event_post&post_mask),event1, min_trials_per_event,file_pairs(fps,2),elec);
                                end
                                
                                if (sum(trials_in_event_postCR&trials_with_event_post&post_mask)<min_trials_per_event)
                                    fprintf(1, ['%d trials with lick events in ' evTypeLabels{find(eventType==event2)} ' fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_postCR&trials_with_event_post&post_mask),event2, min_trials_per_event,file_pairs(fps,2),elec);
                                end
                                
                            end
                            
                        else
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(1,:))<trials_to_process)
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(1,:)),trials_to_process,file_pairs(fps,1),elec);
                            end
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(1,:))<trials_to_process)
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(1,:)),trials_to_process,file_pairs(fps,1),elec);
                            end
                            
                        end
                    else
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).log_P_tERP)
                            fprintf(1, ['Empty log_P_tERP for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                        end
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).log_P_tERP)
                            fprintf(1, ['Empty log_P_tERP for file No %d electrode %d\n'],file_pairs(fps,2),elec);
                        end
                        
                    end
                  
                else
                    
                    if isempty(handles_drgb.drgb.lfpevpair(lfpodNopre_ref))
                        fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                    end
                    
                    if isempty(handles_drgb.drgb.lfpevpair(lfpodNopost_ref))
                        fprintf(1, ['Empty lfpevpairfor file No %d electrode %d\n'],file_pairs(fps,2),elec);
                    end
                    
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        
        pFDRROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for significant difference of auROC p value from 0.5  = %d\n\n'],pFDRROC);
        
        
        %Now plot the bar graphs and do anovan for LFP power
        p_vals_anovan=[];
        pvals_ancova=[];
        pvals_auROCancova=[];
        for bwii=1:4
            
            
            %Do ancova for auROC auROCpre
            this_auROCpre=[];
            this_auROCpre=auROCpre((ROCgroupNopre==1)&(ROCbandwidthpre==bwii))';
            this_auROCpre=[this_auROCpre; auROCpre((ROCgroupNopre==3)&(ROCbandwidthpre==bwii))'];
            
            
            this_auROCpost=[];
            this_auROCpost=auROCpost((ROCgroupNopre==1)&(ROCbandwidthpost==bwii))';
            this_auROCpost=[this_auROCpost; auROCpost((ROCgroupNopre==3)&(ROCbandwidthpost==bwii))'];
            
            pre_post=[];
            pre_post=[zeros(sum((ROCgroupNopre==1)&(ROCbandwidthpre==bwii)),1); ones(sum((ROCgroupNopre==3)&(ROCbandwidthpre==bwii)),1)];
            
            
            [h,atab,ctab,stats] = aoctool(this_auROCpre,this_auROCpost,pre_post,0.05,'','','','off');
            
            
            pvals_auROCancova=[pvals_auROCancova atab{4,6}];
            fprintf(1, ['ancova auROC p value ' freq_names{bwii} ' = %d\n\n'],atab{4,6});
            
            %Do ancova figure for auROC
            figure(10+bwii)
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            h1=plot(auROCpre((ROCgroupNopre==1)&(ROCbandwidthpre==bwii)),auROCpost((ROCgroupNopre==1)&(ROCbandwidthpost==bwii)),'or','MarkerFace','r');
            hold on
            h2=plot(auROCpre((ROCgroupNopre==3)&(ROCbandwidthpre==bwii)),auROCpost((ROCgroupNopre==3)&(ROCbandwidthpost==bwii)),'ob','MarkerFace','b');
            
            slope_pre=ctab{5,2}+ctab{6,2};
            int_pre=ctab{2,2}+ctab{3,2};
            min_x=min([min(auROCpre((ROCgroupNopre==1)&(ROCbandwidthpre==bwii))) min(auROCpre((ROCgroupNopre==3)&(ROCbandwidthpre==bwii)))]);
            max_x=max([max(auROCpre((ROCgroupNopre==1)&(ROCbandwidthpre==bwii))) max(auROCpre((ROCgroupNopre==3)&(ROCbandwidthpre==bwii)))]);
            x=[-0.2 0.5];
            plot(x,slope_pre*x+int_pre,'-r','LineWidth',2)
            
            slope_post=ctab{5,2}+ctab{7,2};
            int_post=ctab{2,2}+ctab{4,2};
            x=[-0.2 0.5];
            plot(x,slope_post*x+int_post,'-b','LineWidth',2)
            
            plot([-0.2 0.5],[-0.2 0.5],'-k','LineWidth',2)
            
            title(['post vs pre auROC for ' freq_names{bwii} ])
            xlabel('pre auROC')
            ylabel('post auROC')
            legend([h1 h2],'halo','no halo')
            xlim([-0.2 0.5])
            ylim([-0.2 0.5])
            ax=gca;
            ax.LineWidth=3;
        end
        
        %         pFDRanovan=drsFDRpval(p_vals_anovan);
        %         fprintf(1, ['pFDR for anovan p value  = %d\n\n'],pFDRanovan);
        %
        %         pFDRancova=drsFDRpval(pvals_ancova);
        %         fprintf(1, ['pFDR for power dB ancova p value  = %d\n\n'], pFDRancova);
        
        pFDRauROCancova=drsFDRpval(pvals_auROCancova);
        fprintf(1, ['pFDR for auROC ancova p value  = %d\n\n'], pFDRauROCancova);
        
        fprintf(1, '\n\n')
        
        %         p_chi=[];
        %         for evTN1=1:length(eventType)
        %             fprintf(1, ['Significant changes in pairwise LFP power analysis for event: ' evTypeLabels{evTN1} '\n\n'])
        %             for bwii=1:4
        %                 for grs=grpre
        %                     num_sig(grs)=sum(p_val((events==evTN1)&(groupNopre==grs),bwii)<=0.05);
        %                     tot_num(grs)=sum((events==evTN1)&(grs==groupNopre));
        %                     fprintf(1, ['Number significant for ' freq_names{bwii} ' and ' handles_drgb.drgbchoices.group_no_names{grs} ' = %d of %d\n'],num_sig(grs),tot_num(grs));
        %                 end
        %                 [p, Q]= chi2test([num_sig(grpre(1)), tot_num(grpre(1))-num_sig(grpre(1)); num_sig(grpre(2)), tot_num(grpre(2))-num_sig(grpre(2))]);
        %                 fprintf(1, ['Chi squared p value  = %d\n\n'],p);
        %                 p_chi=[p_chi p];
        %             end
        %             fprintf(1, '\n\n\n')
        %         end
        %
        %         pFDRchi=drsFDRpval(p_chi);
        %         fprintf(1, ['pFDR for Chi squared p value  = %d\n\n'],pFDRchi);
        
        %Plot cumulative histos for auROCs
        dB_power_change=logical(dB_power_changeHit+dB_power_changeCR);
        figNo=0;
        p_val_ROC=[];
        pvals_auROCperm=[];
        
        
        for bwii=1:4
            n_cum=0;
            this_legend=[];
            data_auROC=[];
            pre_post_auROC=[];
            gr_auROC=[];
            for grs=1:2
                if grs==1
                    try
                        close(figNo+1)
                    catch
                    end
                    figure(figNo+1)
                else
                    try
                        close(figNo+2)
                    catch
                    end
                    figure(figNo+2)
                end
                hold on
                
                %Plot the histograms
                maxauROC=max([max(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))) max(auROCpost((ROCgroupNopost==grpost(grs))&(ROCbandwidthpost==bwii)))]);
                minauROC=min([min(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))) min(auROCpost((ROCgroupNopost==grpost(grs))&(ROCbandwidthpost==bwii)))]);
                edges=[-0.5:0.05:0.5];
                pos2=[0.1 0.1 0.6 0.8];
                subplot('Position',pos2)
                set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
                hold on
                
                h2=histogram(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)),edges);
                h2.FaceColor='b';
                h1=histogram(auROCpost((ROCgroupNopost==grpost(grs))&(ROCbandwidthpost==bwii)),edges);
                h1.FaceColor='r';
                
                xlabel('auROC')
                ylabel('# of electrodes')
                legend('Pre','Laser')
                if grs==1
                    title(['auROC DBh Cre x halo for ' freq_names{bwii}])
                else
                    title(['auROC DBh Cre for ' freq_names{bwii}])
                end
                xlim([-0.3 0.6])
                ylim([0 40])
                ax=gca;
                ax.LineWidth=3;
                %                 if grs==1
                %                     ylim([0 30])
                %                 else
                %                     ylim([0 40])
                %                 end
                
                %Plot the single electrodes
                pos2=[0.8 0.1 0.1 0.8];
                subplot('Position',pos2)
                hold on
                for ii=1:length(auROCpre)
                    if (ROCgroupNopre(ii)==grpre(grs))&(ROCbandwidthpre(ii)==bwii)
                        plot([0 1],[auROCpre(ii) auROCpost(ii)],'-o', 'Color',[0.7 0.7 0.7])
                    end
                end
                
                
                plot([0 1],[mean(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))) mean(auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))],'-k','LineWidth', 3)
                CI = bootci(1000, @mean, auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                plot([0 0],CI,'-b','LineWidth',3)
                plot(0,mean(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))),'ob','MarkerSize', 10,'MarkerFace','b')
                CI = bootci(1000, @mean, auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                plot([1 1],CI,'-r','LineWidth',3)
                plot(1,mean(auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))),'or','MarkerSize', 10,'MarkerFace','r')
                ylabel('auROC')
                ylim([-0.2 0.5])
                ax=gca;
                ax.LineWidth=3;
                %Do the statistics for auROC differences
                %                 a={auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))' auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))'};
                %                 mode_statcond='perm';
                %                 [F df pval_auROCperm] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
                %
                pval_auROCperm=ranksum(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)), auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                
                if grs==1
                    fprintf(1, ['p value for premuted anovan for auROC DBH Cre x halo pre vs laser ' freq_names{bwii} '= %d\n'],  pval_auROCperm);
                else
                    fprintf(1, ['p value for premuted anovan for auROC DBH Cre pre vs laser ' freq_names{bwii} '= %d\n'],  pval_auROCperm);
                end
                pvals_auROCperm=[pvals_auROCperm pval_auROCperm];
                
                %Save the data for anovan interaction
                %Pre
                data_auROC=[data_auROC auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))];
                gr_auROC=[gr_auROC grs*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                pre_post_auROC=[pre_post_auROC ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                
                %Post
                data_auROC=[data_auROC auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))];
                gr_auROC=[gr_auROC grs*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                pre_post_auROC=[pre_post_auROC 2*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
            end
            figNo=figNo+2;
            x=x+3;
            
            %Calculate anovan for inteaction
            [p,tbl,stats]=anovan(data_auROC,{pre_post_auROC gr_auROC},'model','interaction','varnames',{'pre_vs_post','halo_vs_no_halo'},'display','off');
            fprintf(1, ['p value for anovan auROC interaction for ' freq_names{bwii} '= %d\n'],  p(3));
            p_aovan_int(bwii)=p(3);
            
        end
        
        pFDRauROC=drsFDRpval(pvals_auROCperm);
        fprintf(1, ['pFDR for auROC  = %d\n\n'],pFDRauROC);
        
        pFDRauROCint=drsFDRpval(p_aovan_int);
        fprintf(1, ['pFDR for auROC anovan interaction  = %d\n\n'],pFDRauROCint);
        

        save([handles.PathName handles.drgb.outFileName(1:end-4) '_out.mat'],'perCorr_pre','perCorr_post','group_pre', 'group_post');
        pfft=1;
        
    case 2
        %Compare auROC in the last few trials of the last session file with
        %first few trials of session
        % Generate figure 2 for Daniel's paper. first vs last.
        no_dBs=1;
        delta_dB_power_fp1=[];
        no_ROCs=0;
        ROCoutfp1=[];
        ROCoutfp2=[];
        p_vals_ROC=[];
        delta_dB_powerfp1Ev1=[];
        no_Ev1=0;
        pvals_auROCperm=[];
        pvals_dBperm=[];
        perCorr_fp1=[];
        perCorr_fp2=[];
        
        fprintf(1, ['Pairwise auROC analysis for ' evTypeLabels{1} ' and ' evTypeLabels{2} ' LFP power\n\n'])
        p_vals=[];
        for fps=1:no_file_pairs
            
            
            for elec=1:16
                
                lfpodNofp1_ref=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                lfpodNofp2_ref=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                
                if elec==1
                    %Find percent correct for fp1 block
                    perCorr_fp1(fps)=handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).perCorrLFPPower(end);
                    
                    %Find percent correct for fp2 block
                    perCorr_fp2(fps)=handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).perCorrLFPPower(1);
                    
                    fprintf(1, '\nPercent correct for session pair %d last= %d, first= %d\n',fps,perCorr_fp1(fps),perCorr_fp2(fps));
                    
                end
                
                if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref)))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref)))
                    
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).allPower))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).allPower))
                        
                        if (length(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(1,:))>=trials_to_process) &...
                                (length(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(1,:))>=trials_to_process)
                            
                            length_fp1=length(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(1,:));
                            if front_mask(1)==1
                                fp1_mask=logical([ones(1,trials_to_process) zeros(1,length_fp1-trials_to_process)]);
                            else
                                fp1_mask=logical([zeros(1,length_fp1-trials_to_process) ones(1,trials_to_process)]);
                            end
                            trials_in_event_fp1Ev1=(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(event1,:)==1);
                            trials_in_event_fp1Ev2=(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(event2,:)==1);
                            
                            length_fp2=length(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(1,:));
                            if front_mask(2)==1
                                fp2_mask=logical([ones(1,trials_to_process) zeros(1,length_fp2-trials_to_process)]);
                            else
                                fp2_mask=logical([zeros(1,length_fp2-trials_to_process) ones(1,trials_to_process)]);
                            end
                            trials_in_event_fp2Ev1=(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(event1,:)==1);
                            trials_in_event_fp2Ev2=(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(event2,:)==1);
                            
                            
                            if (sum(trials_in_event_fp1Ev1)>=min_trials_per_event) & (sum( trials_in_event_fp1Ev2)>=min_trials_per_event) & ...
                                    (sum(trials_in_event_fp2Ev1)>=min_trials_per_event) & (sum(trials_in_event_fp2Ev2)>=min_trials_per_event)
                                
                                lfpodNofp1=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                lfpodNofp2=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                
                                %fp1 Ev1
                                this_dB_powerfp1refEv1=zeros(sum(trials_in_event_fp1Ev1&fp1_mask),length(frequency));
                                this_dB_powerfp1refEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).allPower(trials_in_event_fp1Ev1&fp1_mask,:));
                                
                                this_dB_powerfp1Ev1=zeros(sum(trials_in_event_fp1Ev1&fp1_mask),length(frequency));
                                this_dB_powerfp1Ev1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp1).allPower(trials_in_event_fp1Ev1&fp1_mask,:));
                                
                                %fp1 Ev2
                                this_dB_powerfp1refEv2=zeros(sum(trials_in_event_fp1Ev2&fp1_mask),length(frequency));
                                this_dB_powerfp1refEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).allPower(trials_in_event_fp1Ev2&fp1_mask,:));
                                
                                this_dB_powerfp1Ev2=zeros(sum(trials_in_event_fp1Ev2&fp1_mask),length(frequency));
                                this_dB_powerfp1Ev2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp1).allPower(trials_in_event_fp1Ev2&fp1_mask,:));
                                
                                
                                %fp2 Ev1
                                this_dB_powerfp2refEv1=zeros(sum(trials_in_event_fp2Ev1&fp2_mask),length(frequency));
                                this_dB_powerfp2refEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).allPower(trials_in_event_fp2Ev1&fp2_mask,:));
                                
                                this_dB_powerfp2Ev1=zeros(sum(trials_in_event_fp2Ev1&fp2_mask),length(frequency));
                                this_dB_powerfp2Ev1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp2).allPower(trials_in_event_fp2Ev1&fp2_mask,:));
                                
                                %fp2 Ev2
                                this_dB_powerfp2refEv2=zeros(sum(trials_in_event_fp2Ev2&fp2_mask),length(frequency));
                                this_dB_powerfp2refEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).allPower(trials_in_event_fp2Ev2&fp2_mask,:));
                                
                                this_dB_powerfp2Ev2=zeros(sum(trials_in_event_fp2Ev2&fp2_mask),length(frequency));
                                this_dB_powerfp2Ev2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp2).allPower(trials_in_event_fp2Ev2&fp2_mask,:));
                                
                                for bwii=1:no_bandwidths
                                    
                                    no_ROCs=no_ROCs+1;
                                    this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                    
                                    %Enter the fp1 Ev1
                                    this_delta_dB_powerfp1Ev1=zeros(sum(trials_in_event_fp1Ev1&fp1_mask),1);
                                    this_delta_dB_powerfp1Ev1=mean(this_dB_powerfp1Ev1(:,this_band)-this_dB_powerfp1refEv1(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_fp1Ev1&fp1_mask),1)=this_delta_dB_powerfp1Ev1;
                                    roc_data(1:sum(trials_in_event_fp1Ev1&fp1_mask),2)=zeros(sum(trials_in_event_fp1Ev1&fp1_mask),1);
                                    
                                    %Enter fp1 Ev2
                                    total_trials=sum(trials_in_event_fp1Ev1&fp1_mask)+sum(trials_in_event_fp1Ev2&fp1_mask);
                                    this_delta_dB_powerfp1Ev2=zeros(sum(trials_in_event_fp1Ev2&fp1_mask),1);
                                    this_delta_dB_powerfp1Ev2=mean(this_dB_powerfp1Ev2(:,this_band)-this_dB_powerfp1refEv2(:,this_band),2);
                                    roc_data(sum(trials_in_event_fp1Ev1&fp1_mask)+1:total_trials,1)=this_delta_dB_powerfp1Ev2;
                                    roc_data(sum(trials_in_event_fp1Ev1&fp1_mask)+1:total_trials,2)=ones(sum(trials_in_event_fp1Ev2&fp1_mask),1);
                                    
                                    
                                    %Find fp1 ROC
                                    ROCoutfp1(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCoutfp1(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).fileNo;
                                    ROCgroupNofp1(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).fileNo);
                                    ROCoutfp1(no_ROCs).timeWindow=winNo;
                                    ROCbandwidthfp1(no_ROCs)=bwii;
                                    auROCfp1(no_ROCs)=ROCoutfp1(no_ROCs).roc.AUC-0.5;
                                    p_valROCfp1(no_ROCs)=ROCoutfp1(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCoutfp1(no_ROCs).roc.p];
                                    
                                    %Enter the fp2 Ev1
                                    this_delta_dB_powerfp2Ev1=zeros(sum(trials_in_event_fp2Ev1&fp2_mask),1);
                                    this_delta_dB_powerfp2Ev1=mean(this_dB_powerfp2Ev1(:,this_band)-this_dB_powerfp2refEv1(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_fp2Ev1&fp2_mask),1)=this_delta_dB_powerfp2Ev1;
                                    roc_data(1:sum(trials_in_event_fp2Ev1&fp2_mask),2)=zeros(sum(trials_in_event_fp2Ev1&fp2_mask),1);
                                    
                                    %Enter fp2 Ev2
                                    total_trials=sum(trials_in_event_fp2Ev1&fp2_mask)+sum(trials_in_event_fp2Ev2&fp2_mask);
                                    this_delta_dB_powerfp2Ev2=zeros(sum(trials_in_event_fp2Ev2&fp2_mask),1);
                                    this_delta_dB_powerfp2Ev2=mean(this_dB_powerfp2Ev2(:,this_band)-this_dB_powerfp2refEv2(:,this_band),2);
                                    roc_data(sum(trials_in_event_fp2Ev1&fp2_mask)+1:total_trials,1)=this_delta_dB_powerfp2Ev2;
                                    roc_data(sum(trials_in_event_fp2Ev1&fp2_mask)+1:total_trials,2)=ones(sum(trials_in_event_fp2Ev2&fp2_mask),1);
                                    
                                    
                                    %Find fp2 ROC
                                    ROCoutfp2(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCoutfp2(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).fileNo;
                                    ROCgroupNofp2(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).fileNo);
                                    ROCoutfp2(no_ROCs).timeWindow=winNo;
                                    ROCbandwidthfp2(no_ROCs)=bwii;
                                    auROCfp2(no_ROCs)=ROCoutfp2(no_ROCs).roc.AUC-0.5;
                                    p_valROCfp2(no_ROCs)=ROCoutfp2(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCoutfp2(no_ROCs).roc.p];
                                    
                                    
                                    %Are the delta dB LFP's different?
                                    
                                    %Ev1
                                    
                                    p_val(no_dBs,bwii)=ranksum(this_delta_dB_powerfp1Ev1,this_delta_dB_powerfp2Ev1);
                                    p_vals=[p_vals p_val(no_dBs,bwii)];
                                    groupNofp1(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                    groupNofp2(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                    events(no_dBs)=1;
                                    
                                    
                                    %Ev2
                                    p_val(no_dBs+1,bwii)=ranksum(this_delta_dB_powerfp1Ev2,this_delta_dB_powerfp2Ev2);
                                    p_vals=[p_vals p_val(no_dBs+1,bwii)];
                                    groupNofp1(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                    groupNofp2(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                    events(no_dBs+1)=2;
                                    
                                    if p_val(no_dBs,bwii)<0.05
                                        dB_power_changeEv1(no_ROCs)=1;
                                    else
                                        dB_power_changeEv1(no_ROCs)=0;
                                    end
                                    
                                    if p_val(no_dBs+1,bwii)<0.05
                                        dB_power_changeEv2(no_ROCs)=1;
                                    else
                                        dB_power_changeEv2(no_ROCs)=0;
                                    end
                                    
                                    %Save the data
                                    
                                    %Ev1, all points
                                    delta_dB_powerfp1Ev1(no_ROCs)=mean(this_delta_dB_powerfp1Ev1);
                                    delta_dB_powerfp2Ev1(no_ROCs)=mean(this_delta_dB_powerfp2Ev1);
                                    
                                    %Ev2, all points
                                    delta_dB_powerfp1Ev2(no_ROCs)=mean(this_delta_dB_powerfp1Ev2);
                                    delta_dB_powerfp2Ev2(no_ROCs)=mean(this_delta_dB_powerfp2Ev2);
                                    
                                    
                                    
                                    %Plot these points
                                    %Odorant 1 S+ on the left
                                    figure(2*(bwii-1)+1)
                                    pos2=[0.8 0.1 0.1 0.8];
                                    subplot('Position',pos2)
                                    hold on
                                    plot([0 1],[delta_dB_powerfp2Ev1(no_ROCs) delta_dB_powerfp1Ev2(no_ROCs)],'-o', 'Color',[0.7 0.7 0.7])
                                    set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
                                    
                                    %Odorant 2 S+ on the right
                                    figure(2*(bwii-1)+2)
                                    pos2=[0.8 0.1 0.1 0.8];
                                    subplot('Position',pos2)
                                    hold on
                                    plot([1 0],[delta_dB_powerfp1Ev1(no_ROCs) delta_dB_powerfp2Ev2(no_ROCs)],'-o', 'Color',[0.7 0.7 0.7])
                                    set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
                                end
                                
                                no_dBs=no_dBs+2;
                                
                            else
                                
                                if (sum(trials_in_event_fp1Ev1)<min_trials_per_event)
                                    fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp1Ev1),event1, min_trials_per_event,file_pairs(fps,1),elec);
                                end
                                
                                if (sum(trials_in_event_fp1Ev2)<min_trials_per_event)
                                    fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp1Ev2),event2, min_trials_per_event,file_pairs(fps,1),elec);
                                end
                                
                                if (sum(trials_in_event_fp2Ev1)<min_trials_per_event)
                                    fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp2Ev1),event1, min_trials_per_event,file_pairs(fps,2),elec);
                                end
                                
                                if (sum(trials_in_event_fp2Ev2)<min_trials_per_event)
                                    fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp2Ev2),event2, min_trials_per_event,file_pairs(fps,2),elec);
                                end
                                
                            end
                            
                        else
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNofp1).which_eventLFPPower(1,:))<trials_to_process)
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNofp1).which_eventLFPPower(1,:)),trials_to_process,file_pairs(fps,1),elec);
                            end
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNofp2).which_eventLFPPower(1,:))<trials_to_process)
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNofp2).which_eventLFPPower(1,:)),trials_to_process,file_pairs(fps,1),elec);
                            end
                            
                        end
                    else
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).allPower)
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                        end
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).allPower)
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],file_pairs(fps,2),elec);
                        end
                        
                    end
                    
                else
                    
                    if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref))
                        fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                    end
                    
                    if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref))
                        fprintf(1, ['Empty lfpevpairfor file No %d electrode %d\n'],file_pairs(fps,2),elec);
                    end
                    
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        %Now plot the histograms and the average for LFP power
        num_pv_perm=0;
        for bwii=1:4
            
            
            %Plot the mean and CI for odorant 1 S+ on the left
            figure(2*(bwii-1)+1)
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            
            hold on
            plot([0 1],[mean(delta_dB_powerfp2Ev1(ROCbandwidthfp2==bwii)) mean(delta_dB_powerfp1Ev2(ROCbandwidthfp1==bwii))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, delta_dB_powerfp2Ev1(ROCbandwidthfp2==bwii));
            plot([0 0],CI,'-r','LineWidth',3)
            plot(0,mean(delta_dB_powerfp2Ev1(ROCbandwidthfp2==bwii)),'or','MarkerSize', 10,'MarkerFace','r')
            CI = bootci(1000, @mean, delta_dB_powerfp1Ev2(ROCbandwidthfp1==bwii));
            plot([1 1],CI,'-b','LineWidth',3)
            plot(1,mean(delta_dB_powerfp1Ev2(ROCbandwidthfp1==bwii)),'ob','MarkerSize', 10,'MarkerFace','b')
            ylabel('delta Power (dB)')
            ylim([-10 10])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the mean and CI for odorant 2 S+ on the right
            figure(2*(bwii-1)+2)
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            
            hold on
            plot([1 0],[mean(delta_dB_powerfp1Ev1(ROCbandwidthfp1==bwii)) mean(delta_dB_powerfp2Ev2(ROCbandwidthfp2==bwii))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, delta_dB_powerfp1Ev1(ROCbandwidthfp1==bwii));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(delta_dB_powerfp1Ev1(ROCbandwidthfp1==bwii)),'or','MarkerSize', 10,'MarkerFace','r')
            CI = bootci(1000, @mean, delta_dB_powerfp2Ev2(ROCbandwidthfp2==bwii));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(delta_dB_powerfp2Ev2(ROCbandwidthfp2==bwii)),'ob','MarkerSize', 10,'MarkerFace','b')
            ylabel('delta Power (dB)')
            ylim([-10 10])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the histograms for odorant 1 S+ red
            figure(2*(bwii-1)+1)
            edges=[-15:1:15];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h1=histogram(delta_dB_powerfp2Ev1(ROCbandwidthfp2==bwii),edges);
            h1.FaceColor='r';
            h2=histogram(delta_dB_powerfp1Ev2(ROCbandwidthfp1==bwii),edges);
            h2.FaceColor='b';
            xlabel('delta Power (dB)')
            ylabel('# of electrodes')
            legend([odorant{1} ' S+'],[odorant{1} ' S-'])
            xlim([-12 12])
            ylim([0 30])
            title(['delta LFP power (dB) for ' odorant{1} ' ' freq_names{bwii}])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the histograms for odorant 2 S+ red
            figure(2*(bwii-1)+2)
            edges=[-15:1:15];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h1=histogram(delta_dB_powerfp1Ev1(ROCbandwidthfp1==bwii),edges);
            h1.FaceColor='r';
            h2=histogram(delta_dB_powerfp2Ev2(ROCbandwidthfp2==bwii),edges);
            h2.FaceColor='b';
            xlabel('delta Power (dB)')
            ylabel('# of electrodes')
            legend([odorant{2} ' S+'],[odorant{2} ' S-'])
            xlim([-12 12])
            ylim([0 30])
            title(['delta LFP power (dB) for ' odorant{2} ' ' freq_names{bwii}])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            
            %Odorant 1
            a={delta_dB_powerfp2Ev1(ROCbandwidthfp2==bwii)' delta_dB_powerfp1Ev2(ROCbandwidthfp1==bwii)'};
            mode_statcond='perm';
            num_pv_perm=num_pv_perm+1;
            [F df pvals_perm(num_pv_perm)] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for premuted anovan dB delta power S+ vs S- for odorant ' odorant{1} ' ' freq_names{bwii} '= %d\n\n'],  pvals_perm(bwii));
            
            
            %Odorant 2
            a={delta_dB_powerfp1Ev1(ROCbandwidthfp1==bwii)' delta_dB_powerfp2Ev2(ROCbandwidthfp2==bwii)'};
            mode_statcond='perm';
            num_pv_perm=num_pv_perm+1;
            [F df pvals_perm(num_pv_perm)] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for premuted anovan dB delta power S+ vs S- for odorant ' odorant{2} ' ' freq_names{bwii} '= %d\n\n'],  pvals_perm(bwii));
            
        end
        
        pFDRanovan=drsFDRpval(pvals_perm);
        fprintf(1, ['pFDR for premuted anovan p value  = %d\n\n'],pFDRanovan);
        
        
        
        fprintf(1, '\n\n')
        
        pFDRROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for significant difference of auROC p value from 0.5  = %d\n\n'],pFDRROC);
        
        
        fprintf(1, '\n\n')
        
        
        %Plot cumulative histos for auROCs
        
        figNo=8;
        p_val_ROC=[];
        
        
        x=0;
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            
            %Plot the histograms
            
            edges=[-0.5:0.05:0.5];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h2=histogram(auROCfp2(ROCbandwidthfp1==bwii),edges);
            h2.FaceColor='b';
            h1=histogram(auROCfp1(ROCbandwidthfp1==bwii),edges);
            h1.FaceColor='r';
            
            xlabel('auROC')
            ylabel('# of electrodes')
            legend(file_label{2},file_label{1})
            title(['auROC for ' freq_names{bwii}])
            xlim([-0.3 0.6])
            ylim([0 30])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the single electrodes
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            hold on
            for ii=1:length(auROCfp1)
                if ROCbandwidthfp1(ii)==bwii
                    plot([0 1],[auROCfp2(ii) auROCfp1(ii)],'-o', 'Color',[0.7 0.7 0.7])
                end
            end
            
            %PLot the mean and 95% CI
            plot([0 1],[mean(auROCfp2(ROCbandwidthfp1==bwii)) mean(auROCfp1(ROCbandwidthfp1==bwii))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, auROCfp2(ROCbandwidthfp1==bwii));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(auROCfp2(ROCbandwidthfp1==bwii)),'ob','MarkerSize', 10,'MarkerFace','b')
            CI = bootci(1000, @mean, auROCfp1(ROCbandwidthfp1==bwii));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(auROCfp1(ROCbandwidthfp1==bwii)),'or','MarkerSize', 10,'MarkerFace','r')
            ylabel('auROC')
            ylim([-0.2 0.5])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Do the statistics for auROC differences
            a={auROCfp2(ROCbandwidthfp1==bwii)' auROCfp1(ROCbandwidthfp1==bwii)'};
            mode_statcond='perm';
            [F df pval_auROCperm] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for permuted anovan for auROC S+ vs S- ' freq_names{bwii} '= %d\n\n'],  pval_auROCperm);
            pvals_auROCperm=[pvals_auROCperm pval_auROCperm];
            
            
            figure(13)
            hold on
            
            percent_auROCfp2=100*sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC)/sum(ROCbandwidthfp1==bwii);
            bar(x,percent_auROCfp2,'b')
            
            learn_sig(bwii)=sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC);
            learn_not_sig(bwii)=sum(ROCbandwidthfp1==bwii)-sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC);
            
            percent_auROCfp1=100*sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC)/sum(ROCbandwidthfp1==bwii);
            bar(x+1,percent_auROCfp1,'r')
            
            prof_sig(bwii)=sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC);
            prof_not_sig(bwii)=sum(ROCbandwidthfp1==bwii)-sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC);
            
            
            
            x=x+3;
            
        end
        
        figure(13)
        title('Percent significant auROC')
        legend(file_label{2},file_label{1})
        ylim([0 100])
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
        
        pFDRanovanauROC=drsFDRpval(pval_auROCperm);
        fprintf(1, ['\npFDR for premuted anovan p value for difference between ' file_label{1} ' and ' file_label{2} ' for auROC = %d\n\n'],pFDRanovanauROC);
        
        
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) output_suffix],'learn_sig','learn_not_sig','prof_sig','prof_not_sig');
        
        pffft=1;
        
    case 3
        %Generate Fig. 2  for Daniels' LFP power paper. For the proficient mice in the first and last sessions
        %plot the LFP spectrum for S+ vs S-, plot LFP power for S+ vs S- for each electrode and plot auROCs
        %NOTE: This does the analysis in all the files and DOES not distinguish between groups!!!
        no_dBs=1;
        delta_dB_power=[];
        no_ROCs=0;
        ROCout=[];
        p_vals_ROC=[];
        delta_dB_powerEv1=[];
        no_Ev1=0;
        noWB=0;
        delta_dB_powerEv1WB=[];
        delta_dB_powerEv2WB=[];
        
        fprintf(1, ['Pairwise auROC analysis for Fig 1 of Daniel''s paper\n\n'])
        p_vals=[];
        no_files=length(files);
        
        if exist('which_electrodes')==0
            which_electrodes=[1:16];
        end
        
        for fileNo=1:no_files
            for elec=1:16
                if sum(which_electrodes==elec)>0
                    lfpodNo_ref=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNo_ref)))
                        
                        
                        if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower))
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(1,:))>=trials_to_process)
                                
                                trials=length(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(1,:));
                                mask=logical([zeros(1,trials-trials_to_process) ones(1,trials_to_process)]);
                                trials_in_eventEv1=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(event1,:)==1);
                                trials_in_eventEv2=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(event2,:)==1);
                                
                                if (sum(trials_in_eventEv1)>=min_trials_per_event) & (sum(trials_in_eventEv2)>=min_trials_per_event)
                                    
                                    lfpodNo=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                    
                                    % Ev1
                                    this_dB_powerrefEv1=zeros(sum(trials_in_eventEv1&mask),length(frequency));
                                    this_dB_powerrefEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower(trials_in_eventEv1&mask,:));
                                    
                                    
                                    this_dB_powerEv1=zeros(sum(trials_in_eventEv1&mask),length(frequency));
                                    this_dB_powerEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo).allPower(trials_in_eventEv1&mask,:));
                                    
                                    % Ev2
                                    this_dB_powerrefEv2=zeros(sum(trials_in_eventEv2&mask),length(frequency));
                                    this_dB_powerrefEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower(trials_in_eventEv2&mask,:));
                                    
                                    
                                    this_dB_powerEv2=zeros(sum(trials_in_eventEv2&mask),length(frequency));
                                    this_dB_powerEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo).allPower(trials_in_eventEv2&mask,:));
                                    
                                    
                                    %Wide band spectrum
                                    noWB=noWB+1;
                                    
                                    delta_dB_powerEv1WB(noWB,:)=mean(this_dB_powerEv1-this_dB_powerrefEv1,1);
                                    delta_dB_powerEv2WB(noWB,:)=mean(this_dB_powerEv2-this_dB_powerrefEv2,1);
                                    
                                    
                                    %Do per badwidth analysis
                                    for bwii=1:no_bandwidths
                                        
                                        no_ROCs=no_ROCs+1;
                                        this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                        
                                        %Enter the  Ev1
                                        this_delta_dB_powerEv1=zeros(sum(trials_in_eventEv1&mask),1);
                                        this_delta_dB_powerEv1=mean(this_dB_powerEv1(:,this_band)-this_dB_powerrefEv1(:,this_band),2);
                                        roc_data=[];
                                        roc_data(1:sum(trials_in_eventEv1&mask),1)=this_delta_dB_powerEv1;
                                        roc_data(1:sum(trials_in_eventEv1&mask),2)=zeros(sum(trials_in_eventEv1&mask),1);
                                        
                                        %Enter  Ev2
                                        total_trials=sum(trials_in_eventEv1&mask)+sum(trials_in_eventEv2&mask);
                                        this_delta_dB_powerEv2=zeros(sum(trials_in_eventEv2&mask),1);
                                        this_delta_dB_powerEv2=mean(this_dB_powerEv2(:,this_band)-this_dB_powerrefEv2(:,this_band),2);
                                        roc_data(sum(trials_in_eventEv1&mask)+1:total_trials,1)=this_delta_dB_powerEv2;
                                        roc_data(sum(trials_in_eventEv1&mask)+1:total_trials,2)=ones(sum(trials_in_eventEv2&mask),1);
                                        
                                        
                                        %Find  ROC
                                        ROCout(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                        ROCout(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNo_ref).fileNo;
                                        ROCgroupNo(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNo_ref).fileNo);
                                        ROCout(no_ROCs).timeWindow=winNo;
                                        ROCbandwidth(no_ROCs)=bwii;
                                        auROC(no_ROCs)=ROCout(no_ROCs).roc.AUC-0.5;
                                        p_valROC(no_ROCs)=ROCout(no_ROCs).roc.p;
                                        
                                        p_vals_ROC=[p_vals_ROC ROCout(no_ROCs).roc.p];
                                        
                                        
                                        delta_dB_powerEv1(no_ROCs)=mean(this_delta_dB_powerEv1);
                                        delta_dB_powerEv2(no_ROCs)=mean(this_delta_dB_powerEv2);
                                        
                                        
                                        %Plot this point
                                        figure(bwii+1)
                                        pos2=[0.8 0.1 0.1 0.8];
                                        subplot('Position',pos2)
                                        hold on
                                        plot([1 0],[delta_dB_powerEv1(no_ROCs) delta_dB_powerEv2(no_ROCs)],'-o', 'Color',[0.7 0.7 0.7])
                                        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
                                        
                                        
                                    end
                                    
                                    
                                    
                                else
                                    
                                    if (sum(trials_in_eventEv1)<min_trials_per_event)
                                        fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_eventEv1),event1, min_trials_per_event,files(fileNo),elec);
                                    end
                                    
                                    if (sum(trials_in_eventEv2)<min_trials_per_event)
                                        fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_eventEv2),event2, min_trials_per_event,files(fileNo),elec);
                                    end
                                    
                                end
                                
                            else
                                
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(1,:)),trials_to_process,files(fileNo),elec);
                                
                            end
                        else
                            
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],files(fileNo),elec);
                            
                        end
                        
                        
                    else
                        fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],files(fileNo),elec);
                        
                        
                    end
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        
        %Now plot the bounded line for
        
        %Calculate the mean and 95% CI for Ev1
        dB_Ev1_ci=zeros(length(frequency),2);
        for ifreq=1:length(frequency)
            %             pd=fitdist(delta_dB_powerEv1WB(:,ifreq),'Normal');
            %             ci=paramci(pd);
            %             dB_Ev1_ci(ifreq)=pd.mu-ci(1,1);
            dB_Ev1_mean(ifreq)=mean(delta_dB_powerEv1WB(:,ifreq));
            CI = bootci(1000, @mean, delta_dB_powerEv1WB(:,ifreq));
            dB_Ev1_ci(ifreq,1)=CI(2)-dB_Ev1_mean(ifreq);
            dB_Ev1_ci(ifreq,2)=-(CI(1)-dB_Ev1_mean(ifreq));
        end
        
        figure(1)
        [hl1, hp1] = boundedline(frequency,dB_Ev1_mean, dB_Ev1_ci, 'r');
        
        %Calculate the mean and 95% CI for Ev2
        dB_Ev2_ci=zeros(length(frequency),2);
        for ifreq=1:length(frequency)
            dB_Ev2_mean(ifreq)=mean(delta_dB_powerEv2WB(:,ifreq));
            CI = bootci(1000, @mean, delta_dB_powerEv2WB(:,ifreq));
            dB_Ev2_ci(ifreq,1)=CI(2)-dB_Ev2_mean(ifreq);
            dB_Ev2_ci(ifreq,2)=-(CI(1)-dB_Ev2_mean(ifreq));
        end
        
        hold on
        [hl2, hp2] = boundedline(frequency,dB_Ev2_mean, dB_Ev2_ci, 'b');
        xlabel('Frequency (Hz)')
        ylabel('delta Power (dB)')
        legend([hl1 hl2],'S+','S-')
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
        
        %Now plot the histograms and the average
        for bwii=1:4
            %Plot the average
            figure(bwii+1)
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            hold on
            plot([1 0],[mean(delta_dB_powerEv1(ROCbandwidth==bwii)) mean(delta_dB_powerEv2(ROCbandwidth==bwii))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, delta_dB_powerEv1(ROCbandwidth==bwii));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(delta_dB_powerEv1(ROCbandwidth==bwii)),'or','MarkerSize', 10,'MarkerFace','r')
            CI = bootci(1000, @mean, delta_dB_powerEv2(ROCbandwidth==bwii));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(delta_dB_powerEv2(ROCbandwidth==bwii)),'ob','MarkerSize', 10,'MarkerFace','b')
            ylabel('delta Power (dB)')
            ylim([-10 15])
            
            %Plot the histograms
            
            maxdB=max([max(delta_dB_powerEv1(ROCbandwidth==bwii)) max(delta_dB_powerEv2(ROCbandwidth==bwii))]);
            mindB=min([min(delta_dB_powerEv1(ROCbandwidth==bwii)) min(delta_dB_powerEv2(ROCbandwidth==bwii))]);
            edges=[-15:1:15];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h1=histogram(delta_dB_powerEv2(ROCbandwidth==bwii),edges);
            h1.FaceColor='b';
            h2=histogram(delta_dB_powerEv1(ROCbandwidth==bwii),edges);
            h2.FaceColor='r';
            xlabel('delta Power (dB)')
            ylabel('# of electrodes')
            legend('S-','S+')
            xlim([-12 12])
            ylim([0 70])
            title(freq_names{bwii})
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            
            
            a={ delta_dB_powerEv1(ROCbandwidth==bwii)' delta_dB_powerEv2(ROCbandwidth==bwii)'};
            mode_statcond='perm';
            [F df pvals_perm(bwii)] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for premuted anovan dB delta power S+ vs S- ' freq_names{bwii} '= %d\n'],  pvals_perm(bwii));
            
        end
        
        pFDRanovan=drsFDRpval(pvals_perm);
        fprintf(1, ['pFDR for premuted anovan p value  = %d\n\n'],pFDRanovan);
        
        
        
        fprintf(1, '\n\n')
        
        
        pFDRauROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for auROC  = %d\n\n'],pFDRauROC);
        %Plot cumulative histos for auROCs
        
        figNo=5;
        p_val_ROC=[];
        edges=-0.5:0.05:0.5;
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            hold on
            n_cum=0;
            this_legend=[];
            
            histogram(auROC(( p_valROC>pFDRauROC)&(ROCbandwidth==bwii)),edges)
            histogram(auROC(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii)),edges)
            legend('auROC not singificant','auROC significant')
            title(['Histogram for ' freq_names{bwii} ' auROC for LFPs'])
            xlim([-0.2 0.6])
            ylim([0 30])
        end
        
         
        
        %Plot percent significant ROC
        figNo=figNo+1;
        try
            close(figNo)
        catch
        end
        figure(figNo)
        
        hold on
        
        for bwii=1:4
            bar(bwii,100*sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii))/sum((ROCbandwidth==bwii)))
            auROC_sig.sig(bwii)=sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii));
            auROC_sig.not_sig(bwii)=sum((ROCbandwidth==bwii))-sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii));
        end
        title('Percent auROC significantly different from zero')
        ylim([0 100])
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
        pffft=1;
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) output_suffix],'auROC_sig');
        
        
    case 4
        %Compare auROC in the last few trials of the last session file with
        %first few trials of the first session
        %Generates Fig. 3 for Daniel's paper. first vs last.
        no_dBs=1;
        delta_dB_power_fp1=[];
        no_ROCs=0;
        ROCoutfp1=[];
        ROCoutfp2=[];
        p_vals_ROC=[];
        delta_dB_powerfp1Ev1=[];
        no_Ev1=0;
        pvals_auROCperm=[];
        pvals_dBperm=[];
        perCorr_fp1=[];
        perCorr_fp2=[];
        
        fprintf(1, ['Pairwise auROC analysis for ' evTypeLabels{1} ' and ' evTypeLabels{2} ' LFP power\n\n'])
        p_vals=[];
        
        if exist('which_electrodes')==0
            which_electrodes=[1:16];
        end
        
        sz_fp=size(file_pairs);
        no_file_pairs=sz_fp(1);
        
        for fps=1:no_file_pairs
            
            
            for elec=1:16
                if sum(which_electrodes==elec)>0
                    lfpodNofp1_ref=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                    lfpodNofp2_ref=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                    
                    if elec==1
                        %Find percent correct for fp1 block
                        perCorr_fp1(fps)=handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).perCorrLFPPower(end);
                        
                        %Find percent correct for fp2 block
                        perCorr_fp2(fps)=handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).perCorrLFPPower(1);
                        
                        fprintf(1, '\nPercent correct for session pair %d last= %d, first= %d\n',fps,perCorr_fp1(fps),perCorr_fp2(fps));
                        
                    end
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref)))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref)))
                        
                        
                        if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).allPower))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).allPower))
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(1,:))>=trials_to_process) &...
                                    (length(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(1,:))>=trials_to_process)
                                
                                length_fp1=length(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(1,:));
                                if front_mask(1)==1
                                    fp1_mask=logical([ones(1,trials_to_process) zeros(1,length_fp1-trials_to_process)]);
                                else
                                    fp1_mask=logical([zeros(1,length_fp1-trials_to_process) ones(1,trials_to_process)]);
                                end
                                trials_in_event_fp1Ev1=(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(event1,:)==1);
                                trials_in_event_fp1Ev2=(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(event2,:)==1);
                                
                                length_fp2=length(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(1,:));
                                if front_mask(2)==1
                                    fp2_mask=logical([ones(1,trials_to_process) zeros(1,length_fp2-trials_to_process)]);
                                else
                                    fp2_mask=logical([zeros(1,length_fp2-trials_to_process) ones(1,trials_to_process)]);
                                end
                                trials_in_event_fp2Ev1=(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(event1,:)==1);
                                trials_in_event_fp2Ev2=(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(event2,:)==1);
                                
                                
                                if (sum(trials_in_event_fp1Ev1)>=min_trials_per_event) & (sum( trials_in_event_fp1Ev2)>=min_trials_per_event) & ...
                                        (sum(trials_in_event_fp2Ev1)>=min_trials_per_event) & (sum(trials_in_event_fp2Ev2)>=min_trials_per_event)
                                    
                                    lfpodNofp1=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                    lfpodNofp2=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                    
                                    %fp1 Ev1
                                    this_dB_powerfp1refEv1=zeros(sum(trials_in_event_fp1Ev1&fp1_mask),length(frequency));
                                    this_dB_powerfp1refEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).allPower(trials_in_event_fp1Ev1&fp1_mask,:));
                                    
                                    this_dB_powerfp1Ev1=zeros(sum(trials_in_event_fp1Ev1&fp1_mask),length(frequency));
                                    this_dB_powerfp1Ev1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp1).allPower(trials_in_event_fp1Ev1&fp1_mask,:));
                                    
                                    %fp1 Ev2
                                    this_dB_powerfp1refEv2=zeros(sum(trials_in_event_fp1Ev2&fp1_mask),length(frequency));
                                    this_dB_powerfp1refEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).allPower(trials_in_event_fp1Ev2&fp1_mask,:));
                                    
                                    this_dB_powerfp1Ev2=zeros(sum(trials_in_event_fp1Ev2&fp1_mask),length(frequency));
                                    this_dB_powerfp1Ev2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp1).allPower(trials_in_event_fp1Ev2&fp1_mask,:));
                                    
                                    
                                    %fp2 Ev1
                                    this_dB_powerfp2refEv1=zeros(sum(trials_in_event_fp2Ev1&fp2_mask),length(frequency));
                                    this_dB_powerfp2refEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).allPower(trials_in_event_fp2Ev1&fp2_mask,:));
                                    
                                    this_dB_powerfp2Ev1=zeros(sum(trials_in_event_fp2Ev1&fp2_mask),length(frequency));
                                    this_dB_powerfp2Ev1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp2).allPower(trials_in_event_fp2Ev1&fp2_mask,:));
                                    
                                    %fp2 Ev2
                                    this_dB_powerfp2refEv2=zeros(sum(trials_in_event_fp2Ev2&fp2_mask),length(frequency));
                                    this_dB_powerfp2refEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).allPower(trials_in_event_fp2Ev2&fp2_mask,:));
                                    
                                    this_dB_powerfp2Ev2=zeros(sum(trials_in_event_fp2Ev2&fp2_mask),length(frequency));
                                    this_dB_powerfp2Ev2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNofp2).allPower(trials_in_event_fp2Ev2&fp2_mask,:));
                                    
                                    for bwii=1:no_bandwidths
                                        
                                        no_ROCs=no_ROCs+1;
                                        this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                        
                                        %Enter the fp1 Ev1
                                        this_delta_dB_powerfp1Ev1=zeros(sum(trials_in_event_fp1Ev1&fp1_mask),1);
                                        this_delta_dB_powerfp1Ev1=mean(this_dB_powerfp1Ev1(:,this_band)-this_dB_powerfp1refEv1(:,this_band),2);
                                        roc_data=[];
                                        roc_data(1:sum(trials_in_event_fp1Ev1&fp1_mask),1)=this_delta_dB_powerfp1Ev1;
                                        roc_data(1:sum(trials_in_event_fp1Ev1&fp1_mask),2)=zeros(sum(trials_in_event_fp1Ev1&fp1_mask),1);
                                        
                                        %Enter fp1 Ev2
                                        total_trials=sum(trials_in_event_fp1Ev1&fp1_mask)+sum(trials_in_event_fp1Ev2&fp1_mask);
                                        this_delta_dB_powerfp1Ev2=zeros(sum(trials_in_event_fp1Ev2&fp1_mask),1);
                                        this_delta_dB_powerfp1Ev2=mean(this_dB_powerfp1Ev2(:,this_band)-this_dB_powerfp1refEv2(:,this_band),2);
                                        roc_data(sum(trials_in_event_fp1Ev1&fp1_mask)+1:total_trials,1)=this_delta_dB_powerfp1Ev2;
                                        roc_data(sum(trials_in_event_fp1Ev1&fp1_mask)+1:total_trials,2)=ones(sum(trials_in_event_fp1Ev2&fp1_mask),1);
                                        
                                        
                                        %Find fp1 ROC
                                        ROCoutfp1(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                        ROCoutfp1(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).fileNo;
                                        ROCgroupNofp1(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).fileNo);
                                        ROCoutfp1(no_ROCs).timeWindow=winNo;
                                        ROCbandwidthfp1(no_ROCs)=bwii;
                                        auROCfp1(no_ROCs)=ROCoutfp1(no_ROCs).roc.AUC-0.5;
                                        p_valROCfp1(no_ROCs)=ROCoutfp1(no_ROCs).roc.p;
                                        
                                        p_vals_ROC=[p_vals_ROC ROCoutfp1(no_ROCs).roc.p];
                                        
                                        %Enter the fp2 Ev1
                                        this_delta_dB_powerfp2Ev1=zeros(sum(trials_in_event_fp2Ev1&fp2_mask),1);
                                        this_delta_dB_powerfp2Ev1=mean(this_dB_powerfp2Ev1(:,this_band)-this_dB_powerfp2refEv1(:,this_band),2);
                                        roc_data=[];
                                        roc_data(1:sum(trials_in_event_fp2Ev1&fp2_mask),1)=this_delta_dB_powerfp2Ev1;
                                        roc_data(1:sum(trials_in_event_fp2Ev1&fp2_mask),2)=zeros(sum(trials_in_event_fp2Ev1&fp2_mask),1);
                                        
                                        %Enter fp2 Ev2
                                        total_trials=sum(trials_in_event_fp2Ev1&fp2_mask)+sum(trials_in_event_fp2Ev2&fp2_mask);
                                        this_delta_dB_powerfp2Ev2=zeros(sum(trials_in_event_fp2Ev2&fp2_mask),1);
                                        this_delta_dB_powerfp2Ev2=mean(this_dB_powerfp2Ev2(:,this_band)-this_dB_powerfp2refEv2(:,this_band),2);
                                        roc_data(sum(trials_in_event_fp2Ev1&fp2_mask)+1:total_trials,1)=this_delta_dB_powerfp2Ev2;
                                        roc_data(sum(trials_in_event_fp2Ev1&fp2_mask)+1:total_trials,2)=ones(sum(trials_in_event_fp2Ev2&fp2_mask),1);
                                        
                                        
                                        %Find fp2 ROC
                                        ROCoutfp2(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                        ROCoutfp2(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).fileNo;
                                        ROCgroupNofp2(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).fileNo);
                                        ROCoutfp2(no_ROCs).timeWindow=winNo;
                                        ROCbandwidthfp2(no_ROCs)=bwii;
                                        auROCfp2(no_ROCs)=ROCoutfp2(no_ROCs).roc.AUC-0.5;
                                        p_valROCfp2(no_ROCs)=ROCoutfp2(no_ROCs).roc.p;
                                        
                                        p_vals_ROC=[p_vals_ROC ROCoutfp2(no_ROCs).roc.p];
                                        
                                        
                                        %Are the delta dB LFP's different?
                                        
                                        %Ev1
                                        
                                        p_val(no_dBs,bwii)=ranksum(this_delta_dB_powerfp1Ev1,this_delta_dB_powerfp2Ev1);
                                        p_vals=[p_vals p_val(no_dBs,bwii)];
                                        groupNofp1(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                        groupNofp2(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                        events(no_dBs)=1;
                                        
                                        
                                        %Ev2
                                        p_val(no_dBs+1,bwii)=ranksum(this_delta_dB_powerfp1Ev2,this_delta_dB_powerfp2Ev2);
                                        p_vals=[p_vals p_val(no_dBs+1,bwii)];
                                        groupNofp1(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                        groupNofp2(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                        events(no_dBs+1)=2;
                                        
                                        if p_val(no_dBs,bwii)<0.05
                                            dB_power_changeEv1(no_ROCs)=1;
                                        else
                                            dB_power_changeEv1(no_ROCs)=0;
                                        end
                                        
                                        if p_val(no_dBs+1,bwii)<0.05
                                            dB_power_changeEv2(no_ROCs)=1;
                                        else
                                            dB_power_changeEv2(no_ROCs)=0;
                                        end
                                        
                                        
                                        
                                        %Ev1, all points
                                        delta_dB_powerfp1Ev1(no_ROCs)=mean(this_delta_dB_powerfp1Ev1);
                                        delta_dB_powerfp2Ev1(no_ROCs)=mean(this_delta_dB_powerfp2Ev1);
                                        
                                        %Ev2, all points
                                        delta_dB_powerfp1Ev2(no_ROCs)=mean(this_delta_dB_powerfp1Ev2);
                                        delta_dB_powerfp2Ev2(no_ROCs)=mean(this_delta_dB_powerfp2Ev2);
                                        
                                        
                                    end
                                    
                                    no_dBs=no_dBs+2;
                                    
                                else
                                    
                                    if (sum(trials_in_event_fp1Ev1)<min_trials_per_event)
                                        fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp1Ev1),event1, min_trials_per_event,file_pairs(fps,1),elec);
                                    end
                                    
                                    if (sum(trials_in_event_fp1Ev2)<min_trials_per_event)
                                        fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp1Ev2),event2, min_trials_per_event,file_pairs(fps,1),elec);
                                    end
                                    
                                    if (sum(trials_in_event_fp2Ev1)<min_trials_per_event)
                                        fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp2Ev1),event1, min_trials_per_event,file_pairs(fps,2),elec);
                                    end
                                    
                                    if (sum(trials_in_event_fp2Ev2)<min_trials_per_event)
                                        fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp2Ev2),event2, min_trials_per_event,file_pairs(fps,2),elec);
                                    end
                                    
                                end
                                
                            else
                                
                                if (length(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(1,:))<trials_to_process)
                                    fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).which_eventLFPPower(1,:)),trials_to_process,file_pairs(fps,1),elec);
                                end
                                
                                if (length(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(1,:))<trials_to_process)
                                    fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).which_eventLFPPower(1,:)),trials_to_process,file_pairs(fps,1),elec);
                                end
                                
                            end
                        else
                            
                            if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref).allPower)
                                fprintf(1, ['Empty allPower for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                            end
                            
                            if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref).allPower)
                                fprintf(1, ['Empty allPower for file No %d electrode %d\n'],file_pairs(fps,2),elec);
                            end
                            
                        end
                        
                    else
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1_ref))
                            fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                        end
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2_ref))
                            fprintf(1, ['Empty lfpevpairfor file No %d electrode %d\n'],file_pairs(fps,2),elec);
                        end
                        
                    end
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        pFDRROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for significant difference of auROC p value from 0.5  = %d\n\n'],pFDRROC);
        
        
        
        fprintf(1, '\n\n')
        
        
        %Plot cumulative histos for auROCs
        dB_power_change=logical(dB_power_changeEv1+dB_power_changeEv2);
        figNo=0;
        p_val_ROC=[];
        
        try
            close(5)
        catch
        end
        figure(5)
        hold on
        x=0;
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            
            %Plot the histograms
            edges=[-0.5:0.05:0.5];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h2=histogram(auROCfp2(ROCbandwidthfp1==bwii),edges);
            h2.FaceColor='b';
            h1=histogram(auROCfp1(ROCbandwidthfp1==bwii),edges);
            h1.FaceColor='r';
            
            xlabel('auROC')
            ylabel('# of electrodes')
            legend(file_label{2},file_label{1})
            title(['auROC for ' freq_names{bwii}])
            xlim([-0.3 0.6])
            ylim([0 30])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the single electrodes
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            hold on
            for ii=1:length(auROCfp1)
                if ROCbandwidthfp1(ii)==bwii
                    plot([0 1],[auROCfp2(ii) auROCfp1(ii)],'-o', 'Color',[0.7 0.7 0.7])
                end
            end
            
            %PLot the mean and 95% CI
            plot([0 1],[mean(auROCfp2(ROCbandwidthfp1==bwii)) mean(auROCfp1(ROCbandwidthfp1==bwii))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, auROCfp2(ROCbandwidthfp1==bwii));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(auROCfp2(ROCbandwidthfp1==bwii)),'ob','MarkerSize', 10,'MarkerFace','b')
            CI = bootci(1000, @mean, auROCfp1(ROCbandwidthfp1==bwii));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(auROCfp1(ROCbandwidthfp1==bwii)),'or','MarkerSize', 10,'MarkerFace','r')
            ylabel('auROC')
            ylim([-0.2 0.5])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Do the statistics for auROC differences
            a={auROCfp2(ROCbandwidthfp1==bwii)' auROCfp1(ROCbandwidthfp1==bwii)'};
            mode_statcond='perm';
            [F df pval_auROCperm] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for permuted anovan for auROC S+ vs S- ' freq_names{bwii} '= %d\n\n'],  pval_auROCperm);
            pvals_auROCperm=[pvals_auROCperm pval_auROCperm];
            
            %Figure 5
            figure(5)
            
            percent_auROCfp2=100*sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC)/sum(ROCbandwidthfp1==bwii);
            bar(x,percent_auROCfp2,'b')
            
            learn_sig(bwii)=sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC);
            learn_not_sig(bwii)=sum(ROCbandwidthfp1==bwii)-sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC);
            
            percent_auROCfp1=100*sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC)/sum(ROCbandwidthfp1==bwii);
            bar(x+1,percent_auROCfp1,'r')
            
            prof_sig(bwii)=sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC);
            prof_not_sig(bwii)=sum(ROCbandwidthfp1==bwii)-sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC);
            
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            x=x+3;
            
        end
        
        figure(5)
        title('Percent singificant auROC')
        legend(file_label{2},file_label{1})
        ylim([0 100])
        
        pFDRanovanauROC=drsFDRpval(pval_auROCperm);
        fprintf(1, ['\npFDR for premuted anovan p value for difference between ' file_label{1} ' and ' file_label{2} ' for auROC = %d\n\n'],pFDRanovanauROC);
        
        
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) output_suffix],'learn_sig','learn_not_sig','prof_sig','prof_not_sig');
        
        pffft=1;
        
    case 5
        %Compare auROC in the last few trials of pre with first few trials of post
        %Used for Fig. 5 of Daniel's paper
        no_dBs=1;
        delta_dB_power_pre=[];
        no_ROCs=0;
        ROCoutpre=[];
        ROCoutpost=[];
        p_vals_ROC=[];
        delta_dB_powerpreHit=[];
        no_hits=0;
        perCorr_pre=[];
        perCorr_post=[];
        group_pre=[];
        group_post=[];
        
        fprintf(1, ['Pairwise auROC analysis for ', evTypeLabels{1} ' and ' evTypeLabels{2} ' LFP power\n\n'])
        p_vals=[];
        for fps=1:no_file_pairs
            for elec=1:16
                
                lfpodNopre_ref=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                lfpodNopost_ref=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                
             
                
                if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNopre_ref)))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNopost_ref)))
                    
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).allPower))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).allPower))
                        
                        if (length(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).which_eventLFPPower(1,:))>=trials_to_process) &...
                                (length(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).which_eventLFPPower(1,:))>=trials_to_process)
                            
                            length_pre=length(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).which_eventLFPPower(1,:));
                            pre_mask=logical([zeros(1,length_pre-trials_to_process) ones(1,trials_to_process)]);
                            trials_in_event_preHit=(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).which_eventLFPPower(event1,:)==1);
                            trials_in_event_preCR=(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).which_eventLFPPower(event2,:)==1);
                            
                            length_post=length(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).which_eventLFPPower(1,:));
                            post_mask=logical([ones(1,trials_to_process) zeros(1,length_post-trials_to_process)]);
                            trials_in_event_postHit=(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).which_eventLFPPower(event1,:)==1);
                            trials_in_event_postCR=(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).which_eventLFPPower(event2,:)==1);
                            
                            if (sum(trials_in_event_preHit)>=min_trials_per_event) & (sum(trials_in_event_preCR)>=min_trials_per_event) & ...
                                    (sum(trials_in_event_postHit)>=min_trials_per_event) & (sum(trials_in_event_postCR)>=min_trials_per_event)
                                
                                
                                lfpodNopre=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                lfpodNopost=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                
                                %pre Hits
                                this_dB_powerprerefHit=zeros(sum(trials_in_event_preHit&pre_mask),length(handles_drgb.drgb.freq_for_LFPpower));
                                this_dB_powerprerefHit(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).allPower(trials_in_event_preHit&pre_mask,:));
                                
                                this_dB_powerpreHit=zeros(sum(trials_in_event_preHit&pre_mask),length(handles_drgb.drgb.freq_for_LFPpower));
                                this_dB_powerpreHit(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNopre).allPower(trials_in_event_preHit&pre_mask,:));
                                
                                
                                %pre CRs
                                this_dB_powerprerefCR=zeros(sum(trials_in_event_preCR&pre_mask),length(handles_drgb.drgb.freq_for_LFPpower));
                                this_dB_powerprerefCR(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).allPower(trials_in_event_preCR&pre_mask,:));
                                
                                this_dB_powerpreCR=zeros(sum(trials_in_event_preCR&pre_mask),length(handles_drgb.drgb.freq_for_LFPpower));
                                this_dB_powerpreCR(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNopre).allPower(trials_in_event_preCR&pre_mask,:));
                                
                                %post Hits
                                this_dB_powerpostrefHit=zeros(sum(trials_in_event_postHit&post_mask),length(handles_drgb.drgb.freq_for_LFPpower));
                                this_dB_powerpostrefHit(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).allPower(trials_in_event_postHit&post_mask,:));
                                
                                this_dB_powerpostHit=zeros(sum(trials_in_event_postHit&post_mask),length(handles_drgb.drgb.freq_for_LFPpower));
                                this_dB_powerpostHit(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNopost).allPower(trials_in_event_postHit&post_mask,:));
                                
                                
                                %post CRs
                                this_dB_powerpostrefCR=zeros(sum(trials_in_event_postCR&post_mask),length(handles_drgb.drgb.freq_for_LFPpower));
                                this_dB_powerpostrefCR(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).allPower(trials_in_event_postCR&post_mask,:));
                                
                                this_dB_powerpostCR=zeros(sum(trials_in_event_postCR&post_mask),length(handles_drgb.drgb.freq_for_LFPpower));
                                this_dB_powerpostCR(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNopost).allPower(trials_in_event_postCR&post_mask,:));
                                
                                for bwii=1:no_bandwidths
                                    
                                    no_ROCs=no_ROCs+1;
                                    this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                    
                                    %Enter the pre Hits
                                    this_delta_dB_powerpreHit=zeros(sum(trials_in_event_preHit&pre_mask),1);
                                    this_delta_dB_powerpreHit=mean(this_dB_powerpreHit(:,this_band)-this_dB_powerprerefHit(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_preHit&pre_mask),1)=this_delta_dB_powerpreHit;
                                    roc_data(1:sum(trials_in_event_preHit&pre_mask),2)=zeros(sum(trials_in_event_preHit&pre_mask),1);
                                    
                                    %Enter pre CR
                                    total_trials=sum(trials_in_event_preHit&pre_mask)+sum(trials_in_event_preCR&pre_mask);
                                    this_delta_dB_powerpreCR=zeros(sum(trials_in_event_preCR&pre_mask),1);
                                    this_delta_dB_powerpreCR=mean(this_dB_powerpreCR(:,this_band)-this_dB_powerprerefCR(:,this_band),2);
                                    roc_data(sum(trials_in_event_preHit&pre_mask)+1:total_trials,1)=this_delta_dB_powerpreCR;
                                    roc_data(sum(trials_in_event_preHit&pre_mask)+1:total_trials,2)=ones(sum(trials_in_event_preCR&pre_mask),1);
                                    
                                    
                                    %Find pre ROC
                                    ROCoutpre(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCoutpre(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNopre_ref).fileNo;
                                    ROCgroupNopre(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).fileNo);
                                    ROCoutpre(no_ROCs).timeWindow=winNo;
                                    ROCbandwidthpre(no_ROCs)=bwii;
                                    auROCpre(no_ROCs)=ROCoutpre(no_ROCs).roc.AUC-0.5;
                                    p_valROCpre(no_ROCs)=ROCoutpre(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCoutpre(no_ROCs).roc.p];
                                    
                                    %Enter the post Hits
                                    this_delta_dB_powerpostHit=zeros(sum(trials_in_event_postHit&post_mask),1);
                                    this_delta_dB_powerpostHit=mean(this_dB_powerpostHit(:,this_band)-this_dB_powerpostrefHit(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_postHit&post_mask),1)=this_delta_dB_powerpostHit;
                                    roc_data(1:sum(trials_in_event_postHit&post_mask),2)=zeros(sum(trials_in_event_postHit&post_mask),1);
                                    
                                    %Enter post CR
                                    total_trials=sum(trials_in_event_postHit&post_mask)+sum(trials_in_event_postCR&post_mask);
                                    this_delta_dB_powerpostCR=zeros(sum(trials_in_event_postCR&post_mask),1);
                                    this_delta_dB_powerpostCR=mean(this_dB_powerpostCR(:,this_band)-this_dB_powerpostrefCR(:,this_band),2);
                                    roc_data(sum(trials_in_event_postHit&post_mask)+1:total_trials,1)=this_delta_dB_powerpostCR;
                                    roc_data(sum(trials_in_event_postHit&post_mask)+1:total_trials,2)=ones(sum(trials_in_event_postCR&post_mask),1);
                                    
                                    
                                    %Find post ROC
                                    ROCoutpost(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCoutpost(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNopost_ref).fileNo;
                                    ROCgroupNopost(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).fileNo);
                                    ROCoutpost(no_ROCs).timeWindow=winNo;
                                    ROCbandwidthpost(no_ROCs)=bwii;
                                    auROCpost(no_ROCs)=ROCoutpost(no_ROCs).roc.AUC-0.5;
                                    p_valROCpost(no_ROCs)=ROCoutpost(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCoutpost(no_ROCs).roc.p];
                                    
                                    if (auROCpost(no_ROCs)<0.3)&(auROCpre(no_ROCs)>0.4)&(ROCgroupNopre(no_ROCs)==1)&(ROCbandwidthpre(no_ROCs)==2)
                                        fprintf(1, ['Decrease in auROC for file No %d vs file No %d electrode %d bandwidth No: %d\n'],file_pairs(fps,1),file_pairs(fps,2),elec,bwii);
                                    end
                                    
                                    %Are the delta dB LFP's different?
                                    
                                    %Hit
                                    
                                    p_val(no_dBs,bwii)=ranksum(this_delta_dB_powerpreHit,this_delta_dB_powerpostHit);
                                    p_vals=[p_vals p_val(no_dBs,bwii)];
                                    groupNopre(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                    groupNopost(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                    events(no_dBs)=1;
                                    
                                    
                                    %CR
                                    p_val(no_dBs+1,bwii)=ranksum(this_delta_dB_powerpreCR,this_delta_dB_powerpostCR);
                                    p_vals=[p_vals p_val(no_dBs+1,bwii)];
                                    groupNopre(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                    groupNopost(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                    events(no_dBs+1)=2;
                                    
                                    if p_val(no_dBs,bwii)<0.05
                                        dB_power_changeHit(no_ROCs)=1;
                                    else
                                        dB_power_changeHit(no_ROCs)=0;
                                    end
                                    
                                    if p_val(no_dBs+1,bwii)<0.05
                                        dB_power_changeCR(no_ROCs)=1;
                                    else
                                        dB_power_changeCR(no_ROCs)=0;
                                    end
                                    
                                    %Plot the points and save the data
                                    if groupNopre(no_dBs)==1
                                        
                                        
                                        %Hit, all points
                                        delta_dB_powerpreHit(no_ROCs)=mean(this_delta_dB_powerpreHit);
                                        delta_dB_powerpostHit(no_ROCs)=mean(this_delta_dB_powerpostHit);
                                        
                                        
                                        %CR, all points
                                        delta_dB_powerpreCR(no_ROCs)=mean(this_delta_dB_powerpreCR);
                                        delta_dB_powerpostCR(no_ROCs)=mean(this_delta_dB_powerpostCR);
                                        
                                    else
                                        if groupNopre(no_dBs)==3
                                            
                                            %Hit, all points
                                            delta_dB_powerpreHit(no_ROCs)=mean(this_delta_dB_powerpreHit);
                                            delta_dB_powerpostHit(no_ROCs)=mean(this_delta_dB_powerpostHit);
                                            
                                            
                                            %CR, all points
                                            delta_dB_powerpreCR(no_ROCs)=mean(this_delta_dB_powerpreCR);
                                            delta_dB_powerpostCR(no_ROCs)=mean(this_delta_dB_powerpostCR);
                                            %                                             figure(bwii+4+12)
                                            %                                             hold on
                                            %                                             plot([3 4],[delta_dB_powerpreCR(no_ROCs) delta_dB_powerpostCR(no_ROCs)],'-o', 'Color',[0.7 0.7 0.7])
                                        end
                                    end
                                end
                                
                                no_dBs=no_dBs+2;
                                
                            else
                                
                                if (sum(trials_in_event_preHit)<min_trials_per_event)
                                    fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_preHit),event1, min_trials_per_event,file_pairs(fps,1),elec);
                                end
                                
                                if (sum(trials_in_event_preCR)<min_trials_per_event)
                                    fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_preCR),event2, min_trials_per_event,file_pairs(fps,1),elec);
                                end
                                
                                if (sum(trials_in_event_postHit)<min_trials_per_event)
                                    fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_postHit),event1, min_trials_per_event,file_pairs(fps,2),elec);
                                end
                                
                                if (sum(trials_in_event_postCR)<min_trials_per_event)
                                    fprintf(1, ['%d trials in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_postCR),event2, min_trials_per_event,file_pairs(fps,2),elec);
                                end
                                
                            end
                            
                        else
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventLFPPower(1,:))<trials_to_process)
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventLFPPower(1,:)),trials_to_process,file_pairs(fps,1),elec);
                            end
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventLFPPower(1,:))<trials_to_process)
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventLFPPower(1,:)),trials_to_process,file_pairs(fps,1),elec);
                            end
                            
                            
                        end
                    else
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNopre_ref).allPower)
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                        end
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNopost_ref).allPower)
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],file_pairs(fps,2),elec);
                        end
                        
                    end
                    
                else
                    
                    if isempty(handles_drgb.drgb.lfpevpair(lfpodNopre_ref))
                        fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                    end
                    
                    if isempty(handles_drgb.drgb.lfpevpair(lfpodNopost_ref))
                        fprintf(1, ['Empty lfpevpairfor file No %d electrode %d\n'],file_pairs(fps,2),elec);
                    end
                    
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        
        pFDRROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for significant difference of auROC p value from 0.5  = %d\n\n'],pFDRROC);
        
        
        %Now plot the bar graphs and do anovan for LFP power
        p_vals_anovan=[];
        pvals_ancova=[];
        pvals_auROCancova=[];
        for bwii=1:4
            
            
            %Do ancova for auROC auROCpre
            this_auROCpre=[];
            this_auROCpre=auROCpre((ROCgroupNopre==1)&(ROCbandwidthpre==bwii))';
            this_auROCpre=[this_auROCpre; auROCpre((ROCgroupNopre==3)&(ROCbandwidthpre==bwii))'];
            
            
            this_auROCpost=[];
            this_auROCpost=auROCpost((ROCgroupNopre==1)&(ROCbandwidthpost==bwii))';
            this_auROCpost=[this_auROCpost; auROCpost((ROCgroupNopre==3)&(ROCbandwidthpost==bwii))'];
            
            pre_post=[];
            pre_post=[zeros(sum((ROCgroupNopre==1)&(ROCbandwidthpre==bwii)),1); ones(sum((ROCgroupNopre==3)&(ROCbandwidthpre==bwii)),1)];
            
            
            [h,atab,ctab,stats] = aoctool(this_auROCpre,this_auROCpost,pre_post,0.05,'','','','off');
            
            
            pvals_auROCancova=[pvals_auROCancova atab{4,6}];
            fprintf(1, ['ancova auROC p value ' freq_names{bwii} ' = %d\n\n'],atab{4,6});
            
            %Do ancova figure for auROC
            figure(10+bwii)
            h1=plot(auROCpre((ROCgroupNopre==1)&(ROCbandwidthpre==bwii)),auROCpost((ROCgroupNopre==1)&(ROCbandwidthpost==bwii)),'or','MarkerFace','r');
            hold on
            h2=plot(auROCpre((ROCgroupNopre==3)&(ROCbandwidthpre==bwii)),auROCpost((ROCgroupNopre==3)&(ROCbandwidthpost==bwii)),'ob','MarkerFace','b');
            
            slope_pre=ctab{5,2}+ctab{6,2};
            int_pre=ctab{2,2}+ctab{3,2};
            min_x=min([min(auROCpre((ROCgroupNopre==1)&(ROCbandwidthpre==bwii))) min(auROCpre((ROCgroupNopre==3)&(ROCbandwidthpre==bwii)))]);
            max_x=max([max(auROCpre((ROCgroupNopre==1)&(ROCbandwidthpre==bwii))) max(auROCpre((ROCgroupNopre==3)&(ROCbandwidthpre==bwii)))]);
            x=[-0.2 0.5];
            plot(x,slope_pre*x+int_pre,'-r','LineWidth',2)
            
            slope_post=ctab{5,2}+ctab{7,2};
            int_post=ctab{2,2}+ctab{4,2};
            x=[-0.2 0.5];
            plot(x,slope_post*x+int_post,'-b','LineWidth',2)
            
            plot([-0.2 0.5],[-0.2 0.5],'-k','LineWidth',2)
            
            title(['post vs pre auROC for ' freq_names{bwii} ])
            xlabel('pre auROC')
            ylabel('post auROC')
            legend([h1 h2],'halo','no halo')
            xlim([-0.2 0.5])
            ylim([-0.2 0.5])
            ax=gca;
            ax.LineWidth=3;
        end
        
        %         pFDRanovan=drsFDRpval(p_vals_anovan);
        %         fprintf(1, ['pFDR for anovan p value  = %d\n\n'],pFDRanovan);
        %
        %         pFDRancova=drsFDRpval(pvals_ancova);
        %         fprintf(1, ['pFDR for power dB ancova p value  = %d\n\n'], pFDRancova);
        
        pFDRauROCancova=drsFDRpval(pvals_auROCancova);
        fprintf(1, ['pFDR for auROC ancova p value  = %d\n\n'], pFDRauROCancova);
        
        fprintf(1, '\n\n')
        
        %         p_chi=[];
        %         for evTN1=1:length(eventType)
        %             fprintf(1, ['Significant changes in pairwise LFP power analysis for event: ' evTypeLabels{evTN1} '\n\n'])
        %             for bwii=1:4
        %                 for grs=grpre
        %                     num_sig(grs)=sum(p_val((events==evTN1)&(groupNopre==grs),bwii)<=0.05);
        %                     tot_num(grs)=sum((events==evTN1)&(grs==groupNopre));
        %                     fprintf(1, ['Number significant for ' freq_names{bwii} ' and ' handles_drgb.drgbchoices.group_no_names{grs} ' = %d of %d\n'],num_sig(grs),tot_num(grs));
        %                 end
        %                 [p, Q]= chi2test([num_sig(grpre(1)), tot_num(grpre(1))-num_sig(grpre(1)); num_sig(grpre(2)), tot_num(grpre(2))-num_sig(grpre(2))]);
        %                 fprintf(1, ['Chi squared p value  = %d\n\n'],p);
        %                 p_chi=[p_chi p];
        %             end
        %             fprintf(1, '\n\n\n')
        %         end
        %
        %         pFDRchi=drsFDRpval(p_chi);
        %         fprintf(1, ['pFDR for Chi squared p value  = %d\n\n'],pFDRchi);
        
        %Plot cumulative histos for auROCs
        dB_power_change=logical(dB_power_changeHit+dB_power_changeCR);
        figNo=0;
        p_val_ROC=[];
        pvals_auROCperm=[];
        
        x=0
        for bwii=1:4
            n_cum=0;
            this_legend=[];
            data_auROC=[];
            pre_post_auROC=[];
            gr_auROC=[];
            for grs=1:2
                if grs==1
                    try
                        close(figNo+1)
                    catch
                    end
                    figure(figNo+1)
                else
                    try
                        close(figNo+2)
                    catch
                    end
                    figure(figNo+2)
                end
                hold on
                
                %Plot the histograms
                maxauROC=max([max(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))) max(auROCpost((ROCgroupNopost==grpost(grs))&(ROCbandwidthpost==bwii)))]);
                minauROC=min([min(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))) min(auROCpost((ROCgroupNopost==grpost(grs))&(ROCbandwidthpost==bwii)))]);
                edges=[-0.5:0.05:0.5];
                pos2=[0.1 0.1 0.6 0.8];
                subplot('Position',pos2)
                hold on
                
                h2=histogram(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)),edges);
                h2.FaceColor='b';
                h1=histogram(auROCpost((ROCgroupNopost==grpost(grs))&(ROCbandwidthpost==bwii)),edges);
                h1.FaceColor='r';
                
                xlabel('auROC')
                ylabel('# of electrodes')
                legend('Pre','Laser')
                if grs==1
                    title(['auROC DBh Cre x halo for ' freq_names{bwii}])
                else
                    title(['auROC DBh Cre for ' freq_names{bwii}])
                end
                xlim([-0.3 0.6])
                ylim([0 45])
                ax=gca;
                ax.LineWidth=3;
                %                 if grs==1
                %                     ylim([0 30])
                %                 else
                %                     ylim([0 40])
                %                 end
                
                %Plot the single electrodes
                pos2=[0.8 0.1 0.1 0.8];
                subplot('Position',pos2)
                hold on
                for ii=1:length(auROCpre)
                    if (ROCgroupNopre(ii)==grpre(grs))&(ROCbandwidthpre(ii)==bwii)
                        plot([0 1],[auROCpre(ii) auROCpost(ii)],'-o', 'Color',[0.7 0.7 0.7])
                    end
                end
                
                
                plot([0 1],[mean(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))) mean(auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))],'-k','LineWidth', 3)
                CI = bootci(1000, @mean, auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                plot([0 0],CI,'-b','LineWidth',3)
                plot(0,mean(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))),'ob','MarkerSize', 10,'MarkerFace','b')
                CI = bootci(1000, @mean, auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                plot([1 1],CI,'-r','LineWidth',3)
                plot(1,mean(auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))),'or','MarkerSize', 10,'MarkerFace','r')
                ylabel('auROC')
                ylim([-0.2 0.5])
                ax=gca;
                ax.LineWidth=3;
                %Do the statistics for auROC differences
                %                 a={auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))' auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))'};
                %                 mode_statcond='perm';
                %                 [F df pval_auROCperm] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
                %
                pval_auROCperm=ranksum(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)), auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                
                if grs==1
                    fprintf(1, ['p value for premuted anovan for auROC DBH Cre x halo pre vs laser ' freq_names{bwii} '= %d\n'],  pval_auROCperm);
                else
                    fprintf(1, ['p value for premuted anovan for auROC DBH Cre pre vs laser ' freq_names{bwii} '= %d\n'],  pval_auROCperm);
                end
                pvals_auROCperm=[pvals_auROCperm pval_auROCperm];
                
                %Save the data for anovan interaction
                %Pre
                data_auROC=[data_auROC auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))];
                gr_auROC=[gr_auROC grs*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                pre_post_auROC=[pre_post_auROC ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                
                %Post
                data_auROC=[data_auROC auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))];
                gr_auROC=[gr_auROC grs*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                pre_post_auROC=[pre_post_auROC 2*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
            end
            figNo=figNo+2;
            x=x+3;
            
            %Calculate anovan for inteaction
            [p,tbl,stats]=anovan(data_auROC,{pre_post_auROC gr_auROC},'model','interaction','varnames',{'pre_vs_post','halo_vs_no_halo'},'display','off');
            fprintf(1, ['p value for anovan auROC interaction for ' freq_names{bwii} '= %d\n'],  p(3));
            p_aovan_int(bwii)=p(3);
            
        end
        
        pFDRauROC=drsFDRpval(pvals_auROCperm);
        fprintf(1, ['pFDR for auROC  = %d\n\n'],pFDRauROC);
        
        pFDRauROCint=drsFDRpval(p_aovan_int);
        fprintf(1, ['pFDR for auROC anovan interaction  = %d\n\n'],pFDRauROCint);
        
        
        
        %         p_perCorr=ranksum(perCorr_pre,perCorr_post);
        %         fprintf(1, '\np value for ranksum test for percent correct= %d\n\n',p_perCorr);
        %
        
        
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) '_out.mat'],'perCorr_pre','perCorr_post','group_pre', 'group_post');
        pfft=1;
        
    case 6
        %For the proficient mice in the first and last sessions
        %plot the ERP LFP spectrum for S+ vs S-, plot ERP LFP power for S+ vs S- for each electrode and plot ERP LFP auROCs
        %NOTE: This does the analysis in all the files and DOES not distinguish between groups!!!
        no_dBs=1;
        delta_dB_power=[];
        no_ROCs=0;
        ROCout=[];
        p_vals_ROC=[];
        delta_dB_powerEv1=[];
        no_Ev1=0;
        noWB=0;
        delta_dB_powerEv1WB=[];
        delta_dB_powerEv2WB=[];
        shift_ii=floor(length(handles_drgb.drgb.lfpevpair(1).out_times)/2)+1+shift_from_event;
        
        NoLicksEv1=[];
        NoLicksEv2=[];
        lickTimesEv1=[];
        lickTimesEv2=[];
        lickTrialsEv1=0;
        lickTrialsEv2=0;
        
        
        
        fprintf(1, ['Pairwise auROC analysis for Fig 1 of Daniel''s paper\n\n'])
        p_vals=[];
        for fileNo=1:length(files)
            %Analyze the licks
            elec=1;
            lfpodNo=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
            
            trials=length(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(1,:));
            mask=logical([zeros(1,trials-trials_to_process) ones(1,trials_to_process)]);
            trials_in_eventEv1=(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(event1,:)==1);
            trials_in_eventEv2=(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(event2,:)==1);
            
            NoLicksEv1=[NoLicksEv1 handles_drgb.drgb.lfpevpair(lfpodNo).no_events_per_trial(trials_in_eventEv1&mask)];
            NoLicksEv2=[NoLicksEv2 handles_drgb.drgb.lfpevpair(lfpodNo).no_events_per_trial(trials_in_eventEv2&mask)];
            
            %Get times for Ev1
            for trialNo=1:length(trials_in_eventEv1)
                if trials_in_eventEv1(trialNo)==1
                    lickTimesEv1=[lickTimesEv1 handles_drgb.drgb.lfpevpair(lfpodNo).t_per_event_per_trial(trialNo,1:handles_drgb.drgb.lfpevpair(lfpodNo).no_events_per_trial(trialNo))];
                    lickTrialsEv1=lickTrialsEv1+1;
                end
                if trials_in_eventEv2(trialNo)==1
                    lickTimesEv2=[lickTimesEv2 handles_drgb.drgb.lfpevpair(lfpodNo).t_per_event_per_trial(trialNo,1:handles_drgb.drgb.lfpevpair(lfpodNo).no_events_per_trial(trialNo))];
                    lickTrialsEv2=lickTrialsEv2+1;
                end
            end
            
            pffft=1;
            
            for elec=1:16
                
                lfpodNo=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                
                if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNo)))
                    
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNo).log_P_tERP))
                        
                        if (length(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(1,:))>=trials_to_process)
                            
                            trials=length(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(1,:));
                            if front_mask==1
                                mask=logical([ones(1,trials_to_process) zeros(1,trials-trials_to_process)]);
                            else
                                mask=logical([zeros(1,trials-trials_to_process) ones(1,trials_to_process)]);
                            end
                            trials_in_eventEv1=(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(event1,:)==1);
                            trials_in_eventEv2=(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(event2,:)==1);
                            %Make sure there is at least one lick event
                            %within each trial
                            trials_with_event=(handles_drgb.drgb.lfpevpair(lfpodNo).no_events_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNo).no_events_per_trial<=max_events_per_sec)...
                                &(handles_drgb.drgb.lfpevpair(lfpodNo).no_ref_evs_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNo).no_ref_evs_per_trial<=max_events_per_sec);
                            
                            if (sum(trials_in_eventEv1&trials_with_event&mask)>=min_trials_per_event) & (sum(trials_in_eventEv2&trials_with_event&mask)>=min_trials_per_event)
                                
                                
                                
                                
                                this_dB_powerEv1=zeros(sum(trials_in_eventEv1&trials_with_event&mask),length(frequency));
                                this_dB_powerEv1(:,:)=handles_drgb.drgb.lfpevpair(lfpodNo).log_P_tERP(trials_in_eventEv1&trials_with_event&mask,:,shift_ii);
                                
                                % Ev2
                                this_dB_powerEv2=zeros(sum(trials_in_eventEv2&trials_with_event&mask),length(frequency));
                                this_dB_powerEv2(:,:)=handles_drgb.drgb.lfpevpair(lfpodNo).log_P_tERP(trials_in_eventEv2&trials_with_event&mask,:,shift_ii);
                                
                                
                                %Wide band spectrum
                                noWB=noWB+1;
                                
                                delta_dB_powerEv1WB(noWB,:)=mean(this_dB_powerEv1,1);
                                delta_dB_powerEv2WB(noWB,:)=mean(this_dB_powerEv2,1);
                                
                                
                                %Do per badwidth analysis
                                for bwii=1:no_bandwidths
                                    
                                    no_ROCs=no_ROCs+1;
                                    this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                    
                                    %Enter the  Ev1
                                    this_delta_dB_powerEv1=zeros(sum(trials_in_eventEv1&trials_with_event&mask),1);
                                    this_delta_dB_powerEv1=mean(this_dB_powerEv1(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_eventEv1&trials_with_event&mask),1)=this_delta_dB_powerEv1;
                                    roc_data(1:sum(trials_in_eventEv1&trials_with_event&mask),2)=zeros(sum(trials_in_eventEv1&trials_with_event&mask),1);
                                    
                                    %Enter  Ev2
                                    total_trials=sum(trials_in_eventEv1&trials_with_event&mask)+sum(trials_in_eventEv2&trials_with_event&mask);
                                    this_delta_dB_powerEv2=zeros(sum(trials_in_eventEv2&trials_with_event&mask),1);
                                    this_delta_dB_powerEv2=mean(this_dB_powerEv2(:,this_band),2);
                                    roc_data(sum(trials_in_eventEv1&trials_with_event&mask)+1:total_trials,1)=this_delta_dB_powerEv2;
                                    roc_data(sum(trials_in_eventEv1&trials_with_event&mask)+1:total_trials,2)=ones(sum(trials_in_eventEv2&trials_with_event&mask),1);
                                    
                                    
                                    %Find  ROC
                                    ROCout(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCout(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNo).fileNo;
                                    ROCgroupNo(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNo).fileNo);
                                    ROCout(no_ROCs).timeWindow=winNo;
                                    ROCbandwidth(no_ROCs)=bwii;
                                    auROC(no_ROCs)=ROCout(no_ROCs).roc.AUC-0.5;
                                    p_valROC(no_ROCs)=ROCout(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCout(no_ROCs).roc.p];
                                    
                                    
                                    delta_dB_powerEv1(no_ROCs)=mean(this_delta_dB_powerEv1);
                                    delta_dB_powerEv2(no_ROCs)=mean(this_delta_dB_powerEv2);
                                    
                                    
                                    %Plot this point
                                    figure(bwii+1)
                                    pos2=[0.8 0.1 0.1 0.8];
                                    subplot('Position',pos2)
                                    hold on
                                    plot([1 0],[delta_dB_powerEv1(no_ROCs) delta_dB_powerEv2(no_ROCs)],'-o', 'Color',[0.7 0.7 0.7])
                                    set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
                                    
                                    
                                end
                                
                                
                                
                            else
                                
                                if sum(trials_in_eventEv1&trials_with_event&mask)<min_trials_per_event
                                    fprintf(1, ['%d trials with lick events in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_eventEv1&trials_with_event&mask),event1, min_trials_per_event,files(fileNo),elec);
                                end
                                
                                if sum(trials_in_eventEv2&trials_with_event&mask)<min_trials_per_event
                                    fprintf(1, ['%d trials with lick events in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_eventEv2&trials_with_event&mask),event2, min_trials_per_event,files(fileNo),elec);
                                end
                                
                            end
                            
                        else
                            
                            fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(1,:)),trials_to_process,files(fileNo),elec);
                            
                        end
                    else
                        
                        fprintf(1, ['Empty allPower for file No %d electrode %d\n'],files(fileNo),elec);
                        
                    end
                    
                    
                else
                    fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],files(fileNo),elec);
                    
                    
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        
        %Now plot the bounded line for
        
        %Calculate the mean and 95% CI for Ev1
        dB_Ev1_ci=zeros(length(frequency),2);
        for ifreq=1:length(frequency)
            %             pd=fitdist(delta_dB_powerEv1WB(:,ifreq),'Normal');
            %             ci=paramci(pd);
            %             dB_Ev1_ci(ifreq)=pd.mu-ci(1,1);
            dB_Ev1_mean(ifreq)=mean(delta_dB_powerEv1WB(:,ifreq));
            CI = bootci(1000, @mean, delta_dB_powerEv1WB(:,ifreq));
            dB_Ev1_ci(ifreq,1)=CI(2)-dB_Ev1_mean(ifreq);
            dB_Ev1_ci(ifreq,2)=-(CI(1)-dB_Ev1_mean(ifreq));
        end
        
        figure(1)
        [hl1, hp1] = boundedline(frequency,dB_Ev1_mean, dB_Ev1_ci, 'r');
        
        %Calculate the mean and 95% CI for Ev2
        dB_Ev2_ci=zeros(length(frequency),2);
        for ifreq=1:length(frequency)
            dB_Ev2_mean(ifreq)=mean(delta_dB_powerEv2WB(:,ifreq));
            CI = bootci(1000, @mean, delta_dB_powerEv2WB(:,ifreq));
            dB_Ev2_ci(ifreq,1)=CI(2)-dB_Ev2_mean(ifreq);
            dB_Ev2_ci(ifreq,2)=-(CI(1)-dB_Ev2_mean(ifreq));
        end
        
        hold on
        [hl2, hp2] = boundedline(frequency,dB_Ev2_mean, dB_Ev2_ci, 'b');
        xlabel('Frequency (Hz)')
        ylabel('delta Power (dB)')
        legend([hl1 hl2],'S+','S-')
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
        
        %Now plot the histograms and the average
        for bwii=1:4
            %Plot the average
            figure(bwii+1)
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            hold on
            plot([1 0],[mean(delta_dB_powerEv1(ROCbandwidth==bwii)) mean(delta_dB_powerEv2(ROCbandwidth==bwii))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, delta_dB_powerEv1(ROCbandwidth==bwii));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(delta_dB_powerEv1(ROCbandwidth==bwii)),'or','MarkerSize', 10,'MarkerFace','r')
            CI = bootci(1000, @mean, delta_dB_powerEv2(ROCbandwidth==bwii));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(delta_dB_powerEv2(ROCbandwidth==bwii)),'ob','MarkerSize', 10,'MarkerFace','b')
            ylabel('delta Power (dB)')
            ylim([-10 15])
            
            %Plot the histograms
            
            maxdB=max([max(delta_dB_powerEv1(ROCbandwidth==bwii)) max(delta_dB_powerEv2(ROCbandwidth==bwii))]);
            mindB=min([min(delta_dB_powerEv1(ROCbandwidth==bwii)) min(delta_dB_powerEv2(ROCbandwidth==bwii))]);
            edges=[-15:1:15];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h1=histogram(delta_dB_powerEv2(ROCbandwidth==bwii),edges);
            h1.FaceColor='b';
            h2=histogram(delta_dB_powerEv1(ROCbandwidth==bwii),edges);
            h2.FaceColor='r';
            xlabel('delta Power (dB)')
            ylabel('# of electrodes')
            legend('S-','S+')
            xlim([-12 12])
            ylim([0 70])
            title(freq_names{bwii})
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            
            
            a={ delta_dB_powerEv1(ROCbandwidth==bwii)' delta_dB_powerEv2(ROCbandwidth==bwii)'};
            mode_statcond='perm';
            [F df pvals_perm(bwii)] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for premuted anovan dB delta power S+ vs S- ' freq_names{bwii} '= %d\n'],  pvals_perm(bwii));
            
        end
        
        pFDRanovan=drsFDRpval(pvals_perm);
        fprintf(1, ['pFDR for premuted anovan p value  = %d\n\n'],pFDRanovan);
        
        
        
        fprintf(1, '\n\n')
        
        
        pFDRauROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for auROC  = %d\n\n'],pFDRauROC);
        %Plot cumulative histos for auROCs
        
        figNo=5;
        p_val_ROC=[];
        edges=-0.5:0.05:0.5;
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            hold on
            n_cum=0;
            this_legend=[];
            
            histogram(auROC(( p_valROC>pFDRauROC)&(ROCbandwidth==bwii)),edges)
            histogram(auROC(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii)),edges)
            legend('auROC not singificant','auROC significant')
            title(['Histogram for ' freq_names{bwii} ' auROC for LFPs'])
            xlim([-0.2 0.6])
            ylim([0 30])
        end
        
        
        
        %Plot percent significant ROC
        figNo=figNo+1;
        try
            close(figNo)
        catch
        end
        figure(figNo)
        
        hold on
        
        for bwii=1:4
            bar(bwii,100*sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii))/sum((ROCbandwidth==bwii)))
            auROC_sig.sig(bwii)=sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii));
            auROC_sig.not_sig(bwii)=sum((ROCbandwidth==bwii))-sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii));
        end
        title('Percent auROC significantly different from zero')
        ylim([0 100])
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
        
        
        %Plot the lick time histogram
        figNo=figNo+1;
        try
            close(figNo)
        catch
        end
        figure(figNo)
        
        hold on
        edges=[handles_drgb.drgb.lfpevpair(lfpodNo).timeStart:0.1:handles_drgb.drgb.lfpevpair(lfpodNo).timeEnd];
        h1=histogram(lickTimesEv1);
        h1.FaceColor='r';
        h2=histogram(lickTimesEv2);
        h2.FaceColor='b';
        xlabel('Time(sec)')
        ylabel('# of licks')
        legend(evTypeLabels{1},evTypeLabels{2})
        xlim([handles_drgb.drgb.lfpevpair(lfpodNo).timeStart handles_drgb.drgb.lfpevpair(lfpodNo).timeEnd])
        title('Lick time histogram')
        
        fprintf(1, ['Mean number of licks per trial for ' evTypeLabels{1} '= %d\n'],mean(NoLicksEv1))
        fprintf(1, ['Mean number of licks per trial for ' evTypeLabels{2} '= %d\n'],mean(NoLicksEv2))
        
        pffft=1;
        
    case 7
        %Compare auROC in the last few trials of the last session file with
        %first few trials of the first session
        %Generates Fig. 3 for Daniel's paper. first vs last.
        no_dBs=1;
        delta_dB_power_fp1=[];
        no_ROCs=0;
        ROCoutfp1=[];
        ROCoutfp2=[];
        p_vals_ROC=[];
        delta_dB_powerfp1Ev1=[];
        no_Ev1=0;
        pvals_auROCperm=[];
        pvals_dBperm=[];
        perCorr_fp1=[];
        perCorr_fp2=[];
        shift_ii=floor(length(handles_drgb.drgb.lfpevpair(1).out_times)/2)+1+shift_from_event;
        
        
        fprintf(1, ['Pairwise auROC log power LFP ERP analysis for ' evTypeLabels{1} ' and ' evTypeLabels{2} ' LFP power\n\n'])
        p_vals=[];
        
        no_file_pairs=length(file_pairs);
        
        for fps=1:no_file_pairs
            
            
            for elec=1:16
                
                lfpodNofp1=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                lfpodNofp2=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                
                
                if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1)))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2)))
                    
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1).log_P_tERP))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2).log_P_tERP))
                        
                        if (length(handles_drgb.drgb.lfpevpair(lfpodNofp1).which_eventERP(1,:))>=trials_to_process) &...
                                (length(handles_drgb.drgb.lfpevpair(lfpodNofp2).which_eventERP(1,:))>=trials_to_process)
                            
                            length_fp1=length(handles_drgb.drgb.lfpevpair(lfpodNofp1).which_eventERP(1,:));
                            if front_mask(1)==1
                                fp1_mask=logical([ones(1,trials_to_process) zeros(1,length_fp1-trials_to_process)]);
                            else
                                fp1_mask=logical([zeros(1,length_fp1-trials_to_process) ones(1,trials_to_process)]);
                            end
                            trials_in_event_fp1Ev1=(handles_drgb.drgb.lfpevpair(lfpodNofp1).which_eventERP(event1,:)==1);
                            trials_in_event_fp1Ev2=(handles_drgb.drgb.lfpevpair(lfpodNofp1).which_eventERP(event2,:)==1);
                            
                            trials_with_eventfp1=(handles_drgb.drgb.lfpevpair(lfpodNofp1).no_events_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNofp1).no_events_per_trial<=max_events_per_sec)...
                                &(handles_drgb.drgb.lfpevpair(lfpodNofp1).no_ref_evs_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNofp1).no_ref_evs_per_trial<=max_events_per_sec);
                            
                            
                            
                            length_fp2=length(handles_drgb.drgb.lfpevpair(lfpodNofp2).which_eventERP(1,:));
                            if front_mask(2)==1
                                fp2_mask=logical([ones(1,trials_to_process) zeros(1,length_fp2-trials_to_process)]);
                            else
                                fp2_mask=logical([zeros(1,length_fp2-trials_to_process) ones(1,trials_to_process)]);
                            end
                            trials_in_event_fp2Ev1=(handles_drgb.drgb.lfpevpair(lfpodNofp2).which_eventERP(event1,:)==1);
                            trials_in_event_fp2Ev2=(handles_drgb.drgb.lfpevpair(lfpodNofp2).which_eventERP(event2,:)==1);
                            
                            
                            trials_with_eventfp2=(handles_drgb.drgb.lfpevpair(lfpodNofp2).no_events_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNofp2).no_events_per_trial<=max_events_per_sec)...
                                &(handles_drgb.drgb.lfpevpair(lfpodNofp2).no_ref_evs_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNofp2).no_ref_evs_per_trial<=max_events_per_sec);
                            
                            if (sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1)>=min_trials_per_event) & (sum(trials_in_event_fp1Ev2&fp1_mask&trials_with_eventfp1)>=min_trials_per_event) & ...
                                    (sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2)>=min_trials_per_event) & (sum(trials_in_event_fp2Ev2&fp2_mask&trials_with_eventfp2)>=min_trials_per_event)
                            
                                
                                %fp1 Ev1
                                this_dB_powerfp1Ev1=zeros(sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1),length(frequency));
                                this_dB_powerfp1Ev1(:,:)=handles_drgb.drgb.lfpevpair(lfpodNofp1).log_P_tERP(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1,:,shift_ii);
                                
                                %fp1 Ev2
                                this_dB_powerfp1Ev2=zeros(sum(trials_in_event_fp1Ev2&fp1_mask&trials_with_eventfp1),length(frequency));
                                this_dB_powerfp1Ev2(:,:)=handles_drgb.drgb.lfpevpair(lfpodNofp1).log_P_tERP(trials_in_event_fp1Ev2&fp1_mask&trials_with_eventfp1,:,shift_ii);
                                
                                
                                %fp2 Ev1
                                this_dB_powerfp2Ev1=zeros(sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2),length(frequency));
                                this_dB_powerfp2Ev1(:,:)=handles_drgb.drgb.lfpevpair(lfpodNofp2).log_P_tERP(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2,:,shift_ii);
                                
                                %fp2 Ev2
                                this_dB_powerfp2Ev2=zeros(sum(trials_in_event_fp2Ev2&fp2_mask&trials_with_eventfp2),length(frequency));
                                this_dB_powerfp2Ev2(:,:)=handles_drgb.drgb.lfpevpair(lfpodNofp2).log_P_tERP(trials_in_event_fp2Ev2&fp2_mask&trials_with_eventfp2,:,shift_ii);
                                
                                for bwii=1:no_bandwidths
                                    
                                    no_ROCs=no_ROCs+1;
                                    this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));

                                    %Enter the fp1 Ev1
                                    this_delta_dB_powerfp1Ev1=zeros(sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1),1);
                                    this_delta_dB_powerfp1Ev1=mean(this_dB_powerfp1Ev1(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1),1)=this_delta_dB_powerfp1Ev1;
                                    roc_data(1:sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1),2)=zeros(sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1),1);
                                    
                                    %Enter fp1 Ev2
                                    total_trials=sum(trials_in_event_fp1Ev2&fp1_mask&trials_with_eventfp1)+sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1);
                                    this_delta_dB_powerfp1Ev2=zeros(sum(trials_in_event_fp1Ev2&fp1_mask&trials_with_eventfp1),1);
                                    this_delta_dB_powerfp1Ev2=mean(this_dB_powerfp1Ev2(:,this_band),2);
                                    roc_data(sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1)+1:total_trials,1)=this_delta_dB_powerfp1Ev2;
                                    roc_data(sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1)+1:total_trials,2)=ones(sum(trials_in_event_fp1Ev2&fp1_mask&trials_with_eventfp1),1);
                                    
                                    
                                    %Find fp1 ROC
                                    ROCoutfp1(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCoutfp1(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNofp1).fileNo;
                                    ROCgroupNofp1(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNofp1).fileNo);
                                    ROCoutfp1(no_ROCs).timeWindow=winNo;
                                    ROCbandwidthfp1(no_ROCs)=bwii;
                                    auROCfp1(no_ROCs)=ROCoutfp1(no_ROCs).roc.AUC-0.5;
                                    p_valROCfp1(no_ROCs)=ROCoutfp1(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCoutfp1(no_ROCs).roc.p];
                                    
                                    %Enter the fp2 Ev1
                                    this_delta_dB_powerfp2Ev1=zeros(sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2),1);
                                    this_delta_dB_powerfp2Ev1=mean(this_dB_powerfp2Ev1(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2),1)=this_delta_dB_powerfp2Ev1;
                                    roc_data(1:sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2),2)=zeros(sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2),1);
                                    
                                    %Enter fp2 Ev2
                                    total_trials=sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2)+sum(trials_in_event_fp2Ev2&fp2_mask&trials_with_eventfp2);
                                    this_delta_dB_powerfp2Ev2=zeros(sum(trials_in_event_fp2Ev2&fp2_mask&trials_with_eventfp2),1);
                                    this_delta_dB_powerfp2Ev2=mean(this_dB_powerfp2Ev2(:,this_band),2);
                                    roc_data(sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2)+1:total_trials,1)=this_delta_dB_powerfp2Ev2;
                                    roc_data(sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2)+1:total_trials,2)=ones(sum(trials_in_event_fp2Ev2&fp2_mask&trials_with_eventfp2),1);
                                    
                                    
                                    %Find fp2 ROC
                                    ROCoutfp2(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCoutfp2(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNofp2).fileNo;
                                    ROCgroupNofp2(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNofp2).fileNo);
                                    ROCoutfp2(no_ROCs).timeWindow=winNo;
                                    ROCbandwidthfp2(no_ROCs)=bwii;
                                    auROCfp2(no_ROCs)=ROCoutfp2(no_ROCs).roc.AUC-0.5;
                                    p_valROCfp2(no_ROCs)=ROCoutfp2(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCoutfp2(no_ROCs).roc.p];
                                    
                                    
                                    %Are the delta dB LFP's different?
                                    
                                    %Ev1
                                    
                                    p_val(no_dBs,bwii)=ranksum(this_delta_dB_powerfp1Ev1,this_delta_dB_powerfp2Ev1);
                                    p_vals=[p_vals p_val(no_dBs,bwii)];
                                    groupNofp1(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                    groupNofp2(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                    events(no_dBs)=1;
                                    
                                    
                                    %Ev2
                                    p_val(no_dBs+1,bwii)=ranksum(this_delta_dB_powerfp1Ev2,this_delta_dB_powerfp2Ev2);
                                    p_vals=[p_vals p_val(no_dBs+1,bwii)];
                                    groupNofp1(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                    groupNofp2(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                    events(no_dBs+1)=2;
                                    
                                    if p_val(no_dBs,bwii)<0.05
                                        dB_power_changeEv1(no_ROCs)=1;
                                    else
                                        dB_power_changeEv1(no_ROCs)=0;
                                    end
                                    
                                    if p_val(no_dBs+1,bwii)<0.05
                                        dB_power_changeEv2(no_ROCs)=1;
                                    else
                                        dB_power_changeEv2(no_ROCs)=0;
                                    end
                                    
                                    
                                    
                                    %Ev1, all points
                                    delta_dB_powerfp1Ev1(no_ROCs)=mean(this_delta_dB_powerfp1Ev1);
                                    delta_dB_powerfp2Ev1(no_ROCs)=mean(this_delta_dB_powerfp2Ev1);
                                    
                                    %Ev2, all points
                                    delta_dB_powerfp1Ev2(no_ROCs)=mean(this_delta_dB_powerfp1Ev2);
                                    delta_dB_powerfp2Ev2(no_ROCs)=mean(this_delta_dB_powerfp2Ev2);
                                    
                                    
                                end
                                
                                no_dBs=no_dBs+2;
                                
                            else
                                
                                if (sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1)<min_trials_per_event)
                                    fprintf(1, ['%d trials with lick events in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp1Ev1&fp1_mask&trials_with_eventfp1),event1, min_trials_per_event,file_pairs(fps,1),elec);
                                end
                                
                                if (sum(trials_in_event_fp1Ev2&fp1_mask&trials_with_eventfp1)<min_trials_per_event)
                                    fprintf(1, ['%d trials with lick events in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp1Ev2&fp1_mask&trials_with_eventfp1),event2, min_trials_per_event,file_pairs(fps,1),elec);
                                end
                                
                                if (sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2)<min_trials_per_event)
                                    fprintf(1, ['%d trials with lick events in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp2Ev1&fp2_mask&trials_with_eventfp2),event1, min_trials_per_event,file_pairs(fps,2),elec);
                                end
                                
                                if (sum(trials_in_event_fp2Ev2&fp2_mask&trials_with_eventfp2)<min_trials_per_event)
                                    fprintf(1, ['%d trials with lick events in event No %d fewer than minimum trials per event %d for file No %d electrode %d\n'],sum(trials_in_event_fp2Ev2&fp2_mask&trials_with_eventfp2),event2, min_trials_per_event,file_pairs(fps,2),elec);
                                end
                                
                            end
                            
                        else
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNofp1).which_eventERP(1,:))<trials_to_process)
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNofp1).which_eventERP(1,:)),trials_to_process,file_pairs(fps,1),elec);
                            end
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNofp2).which_eventERP(1,:))<trials_to_process)
                                fprintf(1, ['%d trials fewer than %d trials to process for file No %d electrode %d\n'],length(handles_drgb.drgb.lfpevpair(lfpodNofp2).which_eventERP(1,:)),trials_to_process,file_pairs(fps,1),elec);
                            end
                            
                        end
                    else
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1).allPower)
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                        end
                        
                        if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2).allPower)
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],file_pairs(fps,2),elec);
                        end
                        
                    end
                    
                else
                    
                    if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp1))
                        fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],file_pairs(fps,1),elec);
                    end
                    
                    if isempty(handles_drgb.drgb.lfpevpair(lfpodNofp2))
                        fprintf(1, ['Empty lfpevpairfor file No %d electrode %d\n'],file_pairs(fps,2),elec);
                    end
                    
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        pFDRROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for significant difference of auROC p value from 0.5  = %d\n\n'],pFDRROC);
        
        
        
        fprintf(1, '\n\n')
        
        
        %Plot cumulative histos for auROCs
        dB_power_change=logical(dB_power_changeEv1+dB_power_changeEv2);
        figNo=0;
        p_val_ROC=[];
        
        try
            close(5)
        catch
        end
        figure(5)
        hold on
        x=0;
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            
            %Plot the histograms
            edges=[-0.5:0.05:0.5];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h2=histogram(auROCfp2(ROCbandwidthfp1==bwii),edges);
            h2.FaceColor='b';
            h1=histogram(auROCfp1(ROCbandwidthfp1==bwii),edges);
            h1.FaceColor='r';
            
            xlabel('auROC')
            ylabel('# of electrodes')
            legend(file_label{2},file_label{1})
            title(['auROC for ' freq_names{bwii}])
            xlim([-0.3 0.6])
            ylim([0 45])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the single electrodes
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            hold on
            for ii=1:length(auROCfp1)
                if ROCbandwidthfp1(ii)==bwii
                    plot([0 1],[auROCfp2(ii) auROCfp1(ii)],'-o', 'Color',[0.7 0.7 0.7])
                end
            end
            
            %PLot the mean and 95% CI
            plot([0 1],[mean(auROCfp2(ROCbandwidthfp1==bwii)) mean(auROCfp1(ROCbandwidthfp1==bwii))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, auROCfp2(ROCbandwidthfp1==bwii));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(auROCfp2(ROCbandwidthfp1==bwii)),'ob','MarkerSize', 10,'MarkerFace','b')
            CI = bootci(1000, @mean, auROCfp1(ROCbandwidthfp1==bwii));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(auROCfp1(ROCbandwidthfp1==bwii)),'or','MarkerSize', 10,'MarkerFace','r')
            ylabel('auROC')
            ylim([-0.2 0.5])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Do the statistics for auROC differences
            a={auROCfp2(ROCbandwidthfp1==bwii)' auROCfp1(ROCbandwidthfp1==bwii)'};
            mode_statcond='perm';
            [F df pval_auROCperm] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for permuted anovan for auROC S+ vs S- ' freq_names{bwii} '= %d\n\n'],  pval_auROCperm);
            pvals_auROCperm=[pvals_auROCperm pval_auROCperm];
            
            %Figure 5
            figure(5)
            
            percent_auROCfp2=100*sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC)/sum(ROCbandwidthfp1==bwii);
            bar(x,percent_auROCfp2,'b')
            
            learn_sig(bwii)=sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC);
            learn_not_sig(bwii)=sum(ROCbandwidthfp1==bwii)-sum(p_valROCfp2(ROCbandwidthfp1==bwii)<=pFDRROC);
            
            percent_auROCfp1=100*sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC)/sum(ROCbandwidthfp1==bwii);
            bar(x+1,percent_auROCfp1,'r')
            
            prof_sig(bwii)=sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC);
            prof_not_sig(bwii)=sum(ROCbandwidthfp1==bwii)-sum(p_valROCfp1(ROCbandwidthfp1==bwii)<=pFDRROC);
            
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            x=x+3;
            
        end
        
        figure(5)
        title('Percent singificant auROC')
        legend(file_label{2},file_label{1})
        ylim([0 100])
        
        pFDRanovanauROC=drsFDRpval(pval_auROCperm);
        fprintf(1, ['\npFDR for premuted anovan p value for difference between ' file_label{1} ' and ' file_label{2} ' for auROC = %d\n\n'],pFDRanovanauROC);
        
        
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) output_suffix],'learn_sig','learn_not_sig','prof_sig','prof_not_sig');
        
        pffft=1;
        
        
    case 8
        
        %Compare auROC for ERP LFP in the last few trials of pre with first few trials of post
        %Used for New Fig. 7 of Daniel's paper
        
        fprintf(1, ['Pairwise auROC analysis for different shift times for ' evTypeLabels{1} ' and ' evTypeLabels{2} ' for ERP LFP power\n\n'],'perCorr_pre','perCorr_post')
        
        shift_ii=[1:4:41];
        
        delta_meanauROC=[];
        delta_meanauROCM=[];
        CIauROCpreLowM=[];
        CIauROCpreUppM=[];
        CIauROCpostLowM=[];
        CIauROCpostUppM=[];
        
        CIauROCdeltaLow=[];
        CIauROCdeltaUpp=[];
        
        for ii_shift=1:length(shift_ii)
            
            fprintf(1, '\nDelta t from event %d of %d\n',ii_shift, length(shift_ii));
            
            
            no_dBs=1;
            delta_dB_power_pre=[];
            no_ROCs=0;
            ROCoutpre=[];
            ROCoutpost=[];
            p_vals_ROC=[];
            delta_dB_powerpreHit=[];
            no_hits=0;
            perCorr_pre=[];
            perCorr_post=[];
            group_pre=[];
            group_post=[];
            sz_fps=size(file_pairs);
            no_file_pairs=sz_fps(1);
            
            p_vals=[];
            for fps=1:no_file_pairs
                for elec=1:16
                    
                    lfpodNopre=find((files_per_lfp==file_pairs(fps,1))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                    lfpodNopost=find((files_per_lfp==file_pairs(fps,2))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                    
          
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNopre)))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNopost)))
                        
                        
                        if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNopre).log_P_tERP))&(~isempty(handles_drgb.drgb.lfpevpair(lfpodNopost).log_P_tERP))
                            
                            if (length(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(1,:))>=trials_to_process) &...
                                    (length(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(1,:))>=trials_to_process)
                                
                                length_pre=length(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(1,:));
                                pre_mask=logical([zeros(1,length_pre-trials_to_process) ones(1,trials_to_process)]);
                                trials_in_event_preHit=(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(event1,:)==1);
                                trials_in_event_preCR=(handles_drgb.drgb.lfpevpair(lfpodNopre).which_eventERP(event2,:)==1);
                                
                                trials_with_event_pre=(handles_drgb.drgb.lfpevpair(lfpodNopre).no_events_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNopre).no_events_per_trial<=max_events_per_sec)...
                                    &(handles_drgb.drgb.lfpevpair(lfpodNopre).no_ref_evs_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNopre).no_ref_evs_per_trial<=max_events_per_sec);
                                
                                
                                length_post=length(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(1,:));
                                post_mask=logical([ones(1,trials_to_process) zeros(1,length_post-trials_to_process)]);
                                trials_in_event_postHit=(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(event1,:)==1);
                                trials_in_event_postCR=(handles_drgb.drgb.lfpevpair(lfpodNopost).which_eventERP(event2,:)==1);
                                
                                trials_with_event_post=(handles_drgb.drgb.lfpevpair(lfpodNopost).no_events_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNopost).no_events_per_trial<=max_events_per_sec)...
                                    &(handles_drgb.drgb.lfpevpair(lfpodNopost).no_ref_evs_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNopost).no_ref_evs_per_trial<=max_events_per_sec);
                                
                                
                                if (sum(trials_in_event_preHit&trials_with_event_pre&pre_mask)>=min_trials_per_event) & (sum(trials_in_event_preCR&trials_with_event_pre&pre_mask)>=min_trials_per_event) & ...
                                        (sum(trials_in_event_postHit&trials_with_event_post&post_mask)>=min_trials_per_event) & (sum(trials_in_event_postCR&trials_with_event_post&post_mask)>=min_trials_per_event)
                                    
                                    
                                    %pre Hits
                                    this_dB_powerpreHit=zeros(sum(trials_in_event_preHit&pre_mask),length(frequency));
                                    this_dB_powerpreHit(:,:)=handles_drgb.drgb.lfpevpair(lfpodNopre).log_P_tERP(trials_in_event_preHit&pre_mask,:,shift_ii(ii_shift));
                                    
                                    
                                    %pre CRs
                                    this_dB_powerpreCR=zeros(sum(trials_in_event_preCR&pre_mask),length(frequency));
                                    this_dB_powerpreCR(:,:)=handles_drgb.drgb.lfpevpair(lfpodNopre).log_P_tERP(trials_in_event_preCR&pre_mask,:,shift_ii(ii_shift));
                                    
                                    
                                    %post Hits
                                    this_dB_powerpostHit=zeros(sum(trials_in_event_postHit&post_mask),length(frequency));
                                    this_dB_powerpostHit(:,:)=handles_drgb.drgb.lfpevpair(lfpodNopost).log_P_tERP(trials_in_event_postHit&post_mask,:,shift_ii(ii_shift));
                                    
                                    
                                    %post CRs
                                    this_dB_powerpostCR=zeros(sum(trials_in_event_postCR&post_mask),length(frequency));
                                    this_dB_powerpostCR(:,:)=handles_drgb.drgb.lfpevpair(lfpodNopost).log_P_tERP(trials_in_event_postCR&post_mask,:,shift_ii(ii_shift));
                                    
                                    for bwii=1:no_bandwidths
                                        
                                        no_ROCs=no_ROCs+1;
                                        this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                        
                                        %Enter the pre Hits
                                        this_delta_dB_powerpreHit=zeros(sum(trials_in_event_preHit&pre_mask),1);
                                        this_delta_dB_powerpreHit=mean(this_dB_powerpreHit(:,this_band),2);
                                        roc_data=[];
                                        roc_data(1:sum(trials_in_event_preHit&pre_mask),1)=this_delta_dB_powerpreHit;
                                        roc_data(1:sum(trials_in_event_preHit&pre_mask),2)=zeros(sum(trials_in_event_preHit&pre_mask),1);
                                        
                                        %Enter pre CR
                                        total_trials=sum(trials_in_event_preHit&pre_mask)+sum(trials_in_event_preCR&pre_mask);
                                        this_delta_dB_powerpreCR=zeros(sum(trials_in_event_preCR&pre_mask),1);
                                        this_delta_dB_powerpreCR=mean(this_dB_powerpreCR(:,this_band),2);
                                        roc_data(sum(trials_in_event_preHit&pre_mask)+1:total_trials,1)=this_delta_dB_powerpreCR;
                                        roc_data(sum(trials_in_event_preHit&pre_mask)+1:total_trials,2)=ones(sum(trials_in_event_preCR&pre_mask),1);
                                        
                                        
                                        %Find pre ROC
                                        ROCoutpre(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                        ROCoutpre(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNopre).fileNo;
                                        ROCgroupNopre(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNopre).fileNo);
                                        ROCoutpre(no_ROCs).timeWindow=winNo;
                                        ROCbandwidthpre(no_ROCs)=bwii;
                                        auROCpre(no_ROCs)=ROCoutpre(no_ROCs).roc.AUC-0.5;
                                        p_valROCpre(no_ROCs)=ROCoutpre(no_ROCs).roc.p;
                                        
                                        p_vals_ROC=[p_vals_ROC ROCoutpre(no_ROCs).roc.p];
                                        
                                        %Enter the post Hits
                                        this_delta_dB_powerpostHit=zeros(sum(trials_in_event_postHit&post_mask),1);
                                        this_delta_dB_powerpostHit=mean(this_dB_powerpostHit(:,this_band),2);
                                        roc_data=[];
                                        roc_data(1:sum(trials_in_event_postHit&post_mask),1)=this_delta_dB_powerpostHit;
                                        roc_data(1:sum(trials_in_event_postHit&post_mask),2)=zeros(sum(trials_in_event_postHit&post_mask),1);
                                        
                                        %Enter post CR
                                        total_trials=sum(trials_in_event_postHit&post_mask)+sum(trials_in_event_postCR&post_mask);
                                        this_delta_dB_powerpostCR=zeros(sum(trials_in_event_postCR&post_mask),1);
                                        this_delta_dB_powerpostCR=mean(this_dB_powerpostCR(:,this_band),2);
                                        roc_data(sum(trials_in_event_postHit&post_mask)+1:total_trials,1)=this_delta_dB_powerpostCR;
                                        roc_data(sum(trials_in_event_postHit&post_mask)+1:total_trials,2)=ones(sum(trials_in_event_postCR&post_mask),1);
                                        
                                        
                                        %Find post ROC
                                        ROCoutpost(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                        ROCoutpost(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNopost).fileNo;
                                        ROCgroupNopost(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNopost).fileNo);
                                        ROCoutpost(no_ROCs).timeWindow=winNo;
                                        ROCbandwidthpost(no_ROCs)=bwii;
                                        auROCpost(no_ROCs)=ROCoutpost(no_ROCs).roc.AUC-0.5;
                                        p_valROCpost(no_ROCs)=ROCoutpost(no_ROCs).roc.p;
                                        
                                        p_vals_ROC=[p_vals_ROC ROCoutpost(no_ROCs).roc.p];
                                        
                                        
                                        %Are the delta dB LFP's different?
                                        
                                        %Hit
                                        p_val(no_dBs,bwii)=ranksum(this_delta_dB_powerpreHit,this_delta_dB_powerpostHit);
                                        p_vals=[p_vals p_val(no_dBs,bwii)];
                                        groupNopre(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                        groupNopost(no_dBs)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                        events(no_dBs)=1;
                                        
                                        
                                        %CR
                                        p_val(no_dBs+1,bwii)=ranksum(this_delta_dB_powerpreCR,this_delta_dB_powerpostCR);
                                        p_vals=[p_vals p_val(no_dBs+1,bwii)];
                                        groupNopre(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,1));
                                        groupNopost(no_dBs+1)=handles_drgb.drgbchoices.group_no(file_pairs(fps,2));
                                        events(no_dBs+1)=2;
                                        
                                        if p_val(no_dBs,bwii)<0.05
                                            dB_power_changeHit(no_ROCs)=1;
                                        else
                                            dB_power_changeHit(no_ROCs)=0;
                                        end
                                        
                                        if p_val(no_dBs+1,bwii)<0.05
                                            dB_power_changeCR(no_ROCs)=1;
                                        else
                                            dB_power_changeCR(no_ROCs)=0;
                                        end
                                        
                                        %Plot the points and save the data
                                        if groupNopre(no_dBs)==1
                                            
                                            
                                            %Hit, all points
                                            delta_dB_powerpreHit(no_ROCs)=mean(this_delta_dB_powerpreHit);
                                            delta_dB_powerpostHit(no_ROCs)=mean(this_delta_dB_powerpostHit);
                                            
                                            
                                            %CR, all points
                                            delta_dB_powerpreCR(no_ROCs)=mean(this_delta_dB_powerpreCR);
                                            delta_dB_powerpostCR(no_ROCs)=mean(this_delta_dB_powerpostCR);
                                            
                                        else
                                            if groupNopre(no_dBs)==3
                                                
                                                %Hit, all points
                                                delta_dB_powerpreHit(no_ROCs)=mean(this_delta_dB_powerpreHit);
                                                delta_dB_powerpostHit(no_ROCs)=mean(this_delta_dB_powerpostHit);
                                                
                                                
                                                %CR, all points
                                                delta_dB_powerpreCR(no_ROCs)=mean(this_delta_dB_powerpreCR);
                                                delta_dB_powerpostCR(no_ROCs)=mean(this_delta_dB_powerpostCR);
                                                %                                             figure(bwii+4+12)
                                                %                                             hold on
                                                %                                             plot([3 4],[delta_dB_powerpreCR(no_ROCs) delta_dB_powerpostCR(no_ROCs)],'-o', 'Color',[0.7 0.7 0.7])
                                            end
                                        end
                                    end
                                    
                                    no_dBs=no_dBs+2;
                                    
                                    
                                end
                                
                                
                                
                            end
                            
                            
                            
                        end
                        
                        
                        
                    end
                end
                
            end
            
            
            
            pFDRROC=drsFDRpval(p_vals_ROC);
            
            %Now plot the bar graphs and do anovan for LFP power
            p_vals_anovan=[];
            
            
            %Plot cumulative histos for auROCs
            dB_power_change=logical(dB_power_changeHit+dB_power_changeCR);
            figNo=0;
            p_val_ROC=[];
            pvals_auROCperm=[];
            
            
            for bwii=1:4
                n_cum=0;
                this_legend=[];
                data_auROC=[];
                pre_post_auROC=[];
                gr_auROC=[];
                for grs=1:2
                    
                    this_deltaauROC=[];
                    this_deltaauROC=auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))-auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii));
                    delta_meanauROC(ii_shift,grs,bwii)=mean(this_deltaauROC);
                    CI= bootci(1000, @mean, this_deltaauROC);
                    CIauROCdeltaLow(ii_shift,grs,bwii)=mean(this_deltaauROC)-CI(1);
                    CIauROCdeltaUpp(ii_shift,grs,bwii)=CI(2)-mean(this_deltaauROC);
                    
                    
                    meanauROCpre(ii_shift,grs,bwii)=mean(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                    CI= bootci(1000, @mean, auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                    CIauROCpreLowM(ii_shift,grs,bwii)=mean(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))-CI(1);
                    CIauROCpreUppM(ii_shift,grs,bwii)=CI(2)-mean(auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                    
                    
                    meanauROCpost(ii_shift,grs,bwii)=mean(auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                    CI = bootci(1000, @mean, auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                    CIauROCpostLowM(ii_shift,grs,bwii)=mean(auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))-CI(1);
                    CIauROCpostUppM(ii_shift,grs,bwii)=CI(2)-mean(auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)));
                    
                    delta_meanauROCM(ii_shift,grs,bwii)=meanauROCpost(ii_shift,grs,bwii)-meanauROCpre(ii_shift,grs,bwii);
                    
                    
                    %Save the data for anovan interaction
                    %Pre
                    data_auROC=[data_auROC auROCpre((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))];
                    gr_auROC=[gr_auROC grs*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                    pre_post_auROC=[pre_post_auROC ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                    
                    %Post
                    data_auROC=[data_auROC auROCpost((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii))];
                    gr_auROC=[gr_auROC grs*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                    pre_post_auROC=[pre_post_auROC 2*ones(1,sum((ROCgroupNopre==grpre(grs))&(ROCbandwidthpre==bwii)))];
                end
                %             figNo=figNo+2;
                %             x=x+3;
                
                %Calculate anovan for inteaction
                [p,tbl,stats]=anovan(data_auROC,{pre_post_auROC gr_auROC},'model','interaction','varnames',{'pre_vs_post','halo_vs_no_halo'},'display','off');
                fprintf(1, ['p value for anovan auROC interaction for ii_shift= %d ' freq_names{bwii} '= %d\n'],  ii_shift,p(3));
                p_aovan_int(ii_shift,bwii)=p(3);
                
            end
            
        end
        
        pFDRauROCint=drsFDRpval(p_aovan_int(:));
        fprintf(1, ['pFDR for auROC anovan interaction  = %d\n\n'],pFDRauROCint);
        
        %Plot the effect of silencing NA fibers with halorhodopsin
        figure(1)
        hold on 
         plot([-0.6 0.6],[0 0],'-','LineWidth',3,'Color',[0.7 0.7 0.7])
        plot([0 0],[-0.25 0.25],'-','LineWidth',3,'Color',[0.7 0.7 0.7])
        delta_time=([0:10]*0.1-0.5);
        for bwii=1:4
            delta_auROC=zeros(1,length(shift_ii));
            delta_auROC=delta_meanauROC(:,1,bwii)-delta_meanauROC(:,2,bwii);
            delta_CIlow=sqrt(CIauROCdeltaLow(:,1,bwii).^2+CIauROCdeltaLow(:,2,bwii).^2);
            delta_CIupp=sqrt(CIauROCdeltaUpp(:,1,bwii).^2+CIauROCdeltaUpp(:,2,bwii).^2);
           
            for ii=1:length(delta_time)
                plot([delta_time(ii)+0.02*(bwii-2.5) delta_time(ii)+0.02*(bwii-2.5)],[delta_auROC(ii) delta_auROC(ii)+delta_CIupp(ii)],these_lines{bwii},'LineWidth',1)
                plot([delta_time(ii)+0.02*(bwii-2.5) delta_time(ii)+0.02*(bwii-2.5)],[delta_auROC(ii) delta_auROC(ii)-delta_CIlow(ii)],these_lines{bwii},'LineWidth',1)
            end
            plot(delta_time+0.02*(bwii-2.5),delta_auROC,'-','LineWidth',2,'Color',these_colors{bwii})
            plot(delta_time(p_aovan_int(:,bwii)<=pFDRauROCint)+0.02*(bwii-2.5),delta_auROC(p_aovan_int(:,bwii)<pFDRauROCint),'*','Color',these_colors{bwii},'MarkerSize',10)
            plot(delta_time(p_aovan_int(:,bwii)>pFDRauROCint)+0.02*(bwii-2.5),delta_auROC(p_aovan_int(:,bwii)>pFDRauROCint),'o','Color',these_colors{bwii},'MarkerFace',these_colors{bwii})
            
        end
       
        ylim([-0.25 0.25])
        xlim([-0.6 0.6])
        xlabel('dt to event (ms)')
        ylabel('delta auROC')
        title('Effect of silencing NA on auROC')
        legend('Theta','Beta','Low gamma','High gamma')
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2, 'Box', 'off')
        
case 9
    %Compare LFP power auROC in two percent windows for all of the files 
    no_dBs=1;
    delta_dB_power_fp1=[];
    no_ROCs=0;
    ROCoutfp1=[];
    ROCoutfp2=[];
    p_vals_ROC=[];
    delta_dB_powerfp1Ev1=[];
    no_Ev1=0;
    pvals_auROCperm=[];
    pvals_dBperm=[];
    perCorr_fp1=[];
    perCorr_fp2=[];
    
    fprintf(1, ['Pairwise auROC analysis for ' evTypeLabels{1} ' and ' evTypeLabels{2} ' LFP power\n\n'])
    p_vals=[];
    
    if exist('which_electrodes')==0
        which_electrodes=[1:16];
    end
    
    no_files=length(files);
    
    
    for fileNo=1:no_files
        
        
        for elec=1:16
            if sum(which_electrodes==elec)>0
                
                
                lfpodNo_ref=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                
                if ~isempty(handles_drgb.drgb.lfpevpair(lfpodNo_ref))
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower))
                        
                        for per_ii=1:2
                            
                            percent_mask=[];
                            trials_in_event_Ev1=[];
                            trials_in_event_Ev2=[];
                            percent_mask=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).perCorrLFPPower>=percent_windows(per_ii,1))...
                                &(handles_drgb.drgb.lfpevpair(lfpodNo_ref).perCorrLFPPower<=percent_windows(per_ii,2));
                            trials_in_event_Ev1=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(event1,:)==1)&percent_mask;
                            trials_in_event_Ev2=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(event2,:)==1)&percent_mask;
                             

                            if (sum(trials_in_event_Ev1)>=min_trials_per_event) & (sum( trials_in_event_Ev2)>=min_trials_per_event)
                                
                                fprintf(1, ['File no %d electrode %d for percent window No %d was processed succesfully\n'],files(fileNo),elec,per_ii)
                                lfpodNo=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                
                                %Ev1
                                this_dB_powerrefEv1=zeros(sum(trials_in_event_Ev1),length(frequency));
                                this_dB_powerrefEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower(trials_in_event_Ev1,:));
                                
                                this_dB_powerEv1=zeros(sum(trials_in_event_Ev1),length(frequency));
                                this_dB_powerEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo).allPower(trials_in_event_Ev1,:));
                              
                                
                                %Ev2
                                this_dB_powerrefEv2=zeros(sum(trials_in_event_Ev2),length(frequency));
                                this_dB_powerrefEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower(trials_in_event_Ev2,:));
                                
                                this_dB_powerEv2=zeros(sum(trials_in_event_Ev2),length(frequency));
                                this_dB_powerEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo).allPower(trials_in_event_Ev2,:));
                                
                                for bwii=1:no_bandwidths
                                    
                                    no_ROCs=no_ROCs+1;
                                    this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                    
                                    %Enter Ev1
                                    this_delta_dB_powerEv1=zeros(sum(trials_in_event_Ev1),1);
                                    this_delta_dB_powerEv1=mean(this_dB_powerEv1(:,this_band)-this_dB_powerrefEv1(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_Ev1),1)=this_delta_dB_powerEv1;
                                    roc_data(1:sum(trials_in_event_Ev1),2)=zeros(sum(trials_in_event_Ev1),1);
                                    
                                    %Enter Ev2
                                    total_trials=sum(trials_in_event_Ev1)+sum(trials_in_event_Ev2);
                                    this_delta_dB_powerEv2=zeros(sum(trials_in_event_Ev2),1);
                                    this_delta_dB_powerEv2=mean(this_dB_powerEv2(:,this_band)-this_dB_powerrefEv2(:,this_band),2);
                                    roc_data(sum(trials_in_event_Ev1)+1:total_trials,1)=this_delta_dB_powerEv2;
                                    roc_data(sum(trials_in_event_Ev1)+1:total_trials,2)=ones(sum(trials_in_event_Ev2),1);
                                    
                                    
                                    %Find  ROC
                                    ROCout(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCout(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNo_ref).fileNo;
                                    ROCgroupNo(no_ROCs)=handles_drgb.drgbchoices.group_no(handles_drgb.drgb.lfpevpair(lfpodNo_ref).fileNo);
                                    ROCout(no_ROCs).timeWindow=winNo;
                                    ROCbandwidth(no_ROCs)=bwii;
                                    ROCper_ii(no_ROCs)=per_ii;
                                    auROC(no_ROCs)=ROCout(no_ROCs).roc.AUC-0.5;
                                    p_valROC(no_ROCs)=ROCout(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCout(no_ROCs).roc.p];
                                    
                                    
                                    
                                end
                                
                                
                            else
                                
                                if (sum(trials_in_event_Ev1)<min_trials_per_event)
                                    fprintf(1, ['%d trials for ' evTypeLabels{1} ' fewer than minimum trials per event =%d for file No %d electrode %d\n'],sum(trials_in_event_Ev1), min_trials_per_event,files(fileNo),elec);
                                end
                                
                                if (sum(trials_in_event_Ev2)<min_trials_per_event)
                                    fprintf(1, ['%d trials for ' evTypeLabels{2} ' fewer than minimum trials per event =%d for file No %d electrode %d\n'],sum(trials_in_event_Ev2), min_trials_per_event,files(fileNo),elec);
                                end
                                
                                
                            end
                            
                        end
                        
                    else
                        fprintf(1, ['Empty allPower for file No %d electrode %d\n'],files(fileNo),elec);
                    end
                    
                else
                    fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],files(fileNo),elec);
                end
            end
        end
        
    end
    fprintf(1, '\n\n')
        
        pFDRROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for significant difference of auROC p value from 0.5  = %d\n\n'],pFDRROC);
        
        
        
        fprintf(1, '\n\n')
        
        
        %Plot cumulative histos for auROCs

        figNo=0;
        x=0;
        
        try
            close(5)
        catch
        end
        figure(5)
        hold on
        
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            
            %Plot the histograms
            edges=[-0.5:0.05:0.5];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h2=histogram(auROC((ROCbandwidth==bwii)&(ROCper_ii==1)),edges);
            h2.FaceColor='r';
            h1=histogram(auROC((ROCbandwidth==bwii)&(ROCper_ii==2)),edges);
            h1.FaceColor='b';
            
            xlabel('auROC')
            ylabel('# of electrodes')
            legend(file_label{2},file_label{1})
            title(['auROC for ' freq_names{bwii}])
            xlim([-0.3 0.6])
            ylim([0 80])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the single electrodes
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            hold on
            
            plot(ones(1,sum((ROCbandwidth==bwii)&(ROCper_ii==1))),auROC((ROCbandwidth==bwii)&(ROCper_ii==1)),'o', 'Color',[0.7 0.7 0.7])
            plot(zeros(1,sum((ROCbandwidth==bwii)&(ROCper_ii==2))),auROC((ROCbandwidth==bwii)&(ROCper_ii==2)),'o', 'Color',[0.7 0.7 0.7])
       
            
            %PLot the mean and 95% CI
            plot([0 1],[mean(auROC((ROCbandwidth==bwii)&(ROCper_ii==2))) mean(auROC((ROCbandwidth==bwii)&(ROCper_ii==1)))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, auROC((ROCbandwidth==bwii)&(ROCper_ii==2)));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(auROC((ROCbandwidth==bwii)&(ROCper_ii==2))),'ob','MarkerSize', 10,'MarkerFace','b')
            CI = bootci(1000, @mean, auROC((ROCbandwidth==bwii)&(ROCper_ii==1)));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(auROC((ROCbandwidth==bwii)&(ROCper_ii==1))),'or','MarkerSize', 10,'MarkerFace','r')
            ylabel('auROC')
            ylim([-0.2 0.5])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Do the statistics for auROC differences
            a={auROC((ROCbandwidth==bwii)&(ROCper_ii==1)) auROC((ROCbandwidth==bwii)&(ROCper_ii==2))};
            mode_statcond='perm';
            [F df pval_auROCperm] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for permuted anovan for auROC S+ vs S- ' freq_names{bwii} '= %d\n\n'],  pval_auROCperm);
            pvals_auROCperm=[pvals_auROCperm pval_auROCperm];
            
            %Figure 5
            figure(5)
            
            percent_auROCper2=100*sum(p_valROC((ROCbandwidth==bwii)&(ROCper_ii==2))<=pFDRROC)/sum((ROCbandwidth==bwii)&(ROCper_ii==2));
            bar(x,percent_auROCper2,'b')
            
            learn_sig(bwii)=sum(p_valROC((ROCbandwidth==bwii)&(ROCper_ii==2))<=pFDRROC);
            learn_not_sig(bwii)=sum((ROCbandwidth==bwii)&(ROCper_ii==2))-sum(p_valROC((ROCbandwidth==bwii)&(ROCper_ii==2))<=pFDRROC);
            
            percent_auROCper1=100*sum(p_valROC((ROCbandwidth==bwii)&(ROCper_ii==1))<=pFDRROC)/sum((ROCbandwidth==bwii)&(ROCper_ii==1));
            bar(x+1,percent_auROCper1,'r')
            
            prof_sig(bwii)=sum(p_valROC((ROCbandwidth==bwii)&(ROCper_ii==1))<=pFDRROC);
            prof_not_sig(bwii)=sum((ROCbandwidth==bwii)&(ROCper_ii==1))-sum(p_valROC((ROCbandwidth==bwii)&(ROCper_ii==1))<=pFDRROC);
            
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            x=x+3;
            
        end
        
        figure(5)
        title('Percent singificant auROC')
        legend(file_label{2},file_label{1})
        ylim([0 100])
        
        pFDRanovanauROC=drsFDRpval(pval_auROCperm);
        fprintf(1, ['\npFDR for premuted anovan p value for difference between ' file_label{1} ' and ' file_label{2} ' for auROC = %d\n\n'],pFDRanovanauROC);
        
        
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) output_suffix],'learn_sig','learn_not_sig','prof_sig','prof_not_sig');
        
        
        pffft=1
        
        
    case 10
        %Compare LFP power auROC for two groups (i.e. NRG1 vs control) for a percent window
        no_dBs=1;
        delta_dB_power_fp1=[];
        no_ROCs=0;
        ROCoutfp1=[];
        ROCoutfp2=[];
        p_vals_ROC=[];
        delta_dB_powerfp1Ev1=[];
        no_Ev1=0;
        pvals_auROCperm=[];
        pvals_dBperm=[];
        perCorr_fp1=[];
        perCorr_fp2=[];
        
        fprintf(1, ['Pairwise auROC analysis for ' evTypeLabels{1} ' and ' evTypeLabels{2} ' LFP power\n\n'])
        p_vals=[];
        
        if exist('which_electrodes')==0
            which_electrodes=[1:16];
        end
        
        no_files=length(files);
        
        
        for fileNo=1:no_files
            
            
            for elec=1:16
                if sum(which_electrodes==elec)>0
                    
                    
                    lfpodNo_ref=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                    
                    if ~isempty(handles_drgb.drgb.lfpevpair(lfpodNo_ref))
                        
                        if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower))
                            
                            per_ii=1;
                            
                            percent_mask=[];
                            trials_in_event_Ev1=[];
                            trials_in_event_Ev2=[];
                            percent_mask=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).perCorrLFPPower>=percent_windows(per_ii,1))...
                                &(handles_drgb.drgb.lfpevpair(lfpodNo_ref).perCorrLFPPower<=percent_windows(per_ii,2));
                            trials_in_event_Ev1=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(event1,:)==1)&percent_mask;
                            trials_in_event_Ev2=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(event2,:)==1)&percent_mask;
                            if (files(fileNo)==7)&(elec==5)
                                pffft=1
                            end
                            if (sum(trials_in_event_Ev1)>=min_trials_per_event) & (sum( trials_in_event_Ev2)>=min_trials_per_event)
                                
                                fprintf(1, ['File no %d electrode %d for percent window No %d was processed succesfully\n'],files(fileNo),elec,per_ii)
                                lfpodNo=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                
                                %Ev1
                                this_dB_powerrefEv1=zeros(sum(trials_in_event_Ev1),length(frequency));
                                this_dB_powerrefEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower(trials_in_event_Ev1,:));
                                
                                this_dB_powerEv1=zeros(sum(trials_in_event_Ev1),length(frequency));
                                this_dB_powerEv1(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo).allPower(trials_in_event_Ev1,:));
                                
                                %Ev2
                                this_dB_powerrefEv2=zeros(sum(trials_in_event_Ev2),length(frequency));
                                this_dB_powerrefEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower(trials_in_event_Ev2,:));
                                
                                this_dB_powerEv2=zeros(sum(trials_in_event_Ev2),length(frequency));
                                this_dB_powerEv2(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo).allPower(trials_in_event_Ev2,:));
                                
                                for bwii=1:no_bandwidths
                                    
                                    no_ROCs=no_ROCs+1;
                                    this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                    
                                    %Enter Ev1
                                    this_delta_dB_powerEv1=zeros(sum(trials_in_event_Ev1),1);
                                    this_delta_dB_powerEv1=mean(this_dB_powerEv1(:,this_band)-this_dB_powerrefEv1(:,this_band),2);
                                    roc_data=[];
                                    roc_data(1:sum(trials_in_event_Ev1),1)=this_delta_dB_powerEv1;
                                    roc_data(1:sum(trials_in_event_Ev1),2)=zeros(sum(trials_in_event_Ev1),1);
                                    
                                    %Enter Ev2
                                    total_trials=sum(trials_in_event_Ev1)+sum(trials_in_event_Ev2);
                                    this_delta_dB_powerEv2=zeros(sum(trials_in_event_Ev2),1);
                                    this_delta_dB_powerEv2=mean(this_dB_powerEv2(:,this_band)-this_dB_powerrefEv2(:,this_band),2);
                                    roc_data(sum(trials_in_event_Ev1)+1:total_trials,1)=this_delta_dB_powerEv2;
                                    roc_data(sum(trials_in_event_Ev1)+1:total_trials,2)=ones(sum(trials_in_event_Ev2),1);
                                    
                                    
                                    %Find  ROC
                                    ROCout(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                    ROCout(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNo_ref).fileNo;
                                    ROCgroupNo(no_ROCs)=groups(fileNo);
                                    ROCout(no_ROCs).timeWindow=winNo;
                                    ROCbandwidth(no_ROCs)=bwii;
                                    ROCper_ii(no_ROCs)=per_ii;
                                    auROC(no_ROCs)=ROCout(no_ROCs).roc.AUC-0.5;
                                    p_valROC(no_ROCs)=ROCout(no_ROCs).roc.p;
                                    
                                    p_vals_ROC=[p_vals_ROC ROCout(no_ROCs).roc.p];
                                    
                                    
                                    
                                end
                                
                                
                            else
                                
                                if (sum(trials_in_event_Ev1)<min_trials_per_event)
                                    fprintf(1, ['%d trials for ' evTypeLabels{1} ' fewer than minimum trials per event =%d for file No %d electrode %d\n'],sum(trials_in_event_Ev1), min_trials_per_event,fileNo,elec);
                                end
                                
                                if (sum(trials_in_event_Ev2)<min_trials_per_event)
                                    fprintf(1, ['%d trials for ' evTypeLabels{2} ' fewer than minimum trials per event =%d for file No %d electrode %d\n'],sum(trials_in_event_Ev2), min_trials_per_event,fileNo,elec);
                                end
                                
                                
                            end
                            
                            
                            
                        else
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],fileNo,elec);
                        end
                        
                    else
                        fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],fileNo,elec);
                    end
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        pFDRROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for significant difference of auROC p value from 0.5  = %d\n\n'],pFDRROC);
        
        
        
        fprintf(1, '\n\n')
        
        
        %Plot cumulative histos for auROCs
        
        figNo=0;
        x=0;
        
        try
            close(5)
        catch
        end
        figure(5)
        hold on
        
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            
            %Plot the histograms
            edges=[-0.5:0.05:0.5];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
            
            h2=histogram(auROC((ROCbandwidth==bwii)&(ROCgroupNo==1)),edges);
            h2.FaceColor='r';
            h1=histogram(auROC((ROCbandwidth==bwii)&(ROCgroupNo==2)),edges);
            h1.FaceColor='b';
            
            
            xlabel('auROC')
            ylabel('# of electrodes')
            legend(group_names{1},group_names{2})
            title(['auROC for ' freq_names{bwii}])
            xlim([-0.3 0.6])
            ylim([0 80])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the single electrodes
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            hold on
            
            plot(ones(1,sum((ROCbandwidth==bwii)&(ROCgroupNo==1))),auROC((ROCbandwidth==bwii)&(ROCgroupNo==1)),'o', 'Color',[0.7 0.7 0.7])
            plot(zeros(1,sum((ROCbandwidth==bwii)&(ROCgroupNo==2))),auROC((ROCbandwidth==bwii)&(ROCgroupNo==2)),'o', 'Color',[0.7 0.7 0.7])
            
            
            %PLot the mean and 95% CI
            plot([0 1],[mean(auROC((ROCbandwidth==bwii)&(ROCgroupNo==2))) mean(auROC((ROCbandwidth==bwii)&(ROCgroupNo==1)))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, auROC((ROCbandwidth==bwii)&(ROCgroupNo==2)));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(auROC((ROCbandwidth==bwii)&(ROCgroupNo==2))),'ob','MarkerSize', 10,'MarkerFace','b')
            CI = bootci(1000, @mean, auROC((ROCbandwidth==bwii)&(ROCgroupNo==1)));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(auROC((ROCbandwidth==bwii)&(ROCgroupNo==1))),'or','MarkerSize', 10,'MarkerFace','r')
            ylabel('auROC')
            ylim([-0.2 0.5])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Do the statistics for auROC differences
            a={auROC((ROCbandwidth==bwii)&(ROCgroupNo==1)) auROC((ROCbandwidth==bwii)&(ROCgroupNo==2))};
            mode_statcond='perm';
            [F df pval_auROCperm] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for permuted anovan for auROC S+ vs S- ' freq_names{bwii} '= %d\n\n'],  pval_auROCperm);
            pvals_auROCperm=[pvals_auROCperm pval_auROCperm];
            
            %Figure 5
            figure(5)
            
            percent_auROCper1=100*sum(p_valROC((ROCbandwidth==bwii)&(ROCgroupNo==1))<=pFDRROC)/sum((ROCbandwidth==bwii)&(ROCgroupNo==1));
            bar(x+1,percent_auROCper1,'r')
            
            percent_auROCper2=100*sum(p_valROC((ROCbandwidth==bwii)&(ROCgroupNo==2))<=pFDRROC)/sum((ROCbandwidth==bwii)&(ROCgroupNo==2));
            bar(x,percent_auROCper2,'b')
            
            learn_sig(bwii)=sum(p_valROC((ROCbandwidth==bwii)&(ROCgroupNo==2))<=pFDRROC);
            learn_not_sig(bwii)=sum((ROCbandwidth==bwii)&(ROCgroupNo==2))-sum(p_valROC((ROCbandwidth==bwii)&(ROCgroupNo==2))<=pFDRROC);
            
            prof_sig(bwii)=sum(p_valROC((ROCbandwidth==bwii)&(ROCgroupNo==1))<=pFDRROC);
            prof_not_sig(bwii)=sum((ROCbandwidth==bwii)&(ROCgroupNo==1))-sum(p_valROC((ROCbandwidth==bwii)&(ROCgroupNo==1))<=pFDRROC);
            
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            x=x+3;
            
        end
        
        figure(5)
        title('Percent singificant auROC')
        legend(group_names{1},group_names{2})
        ylim([0 100])
        
        pFDRanovanauROC=drsFDRpval(pval_auROCperm);
        fprintf(1, ['\npFDR for premuted anovan p value for difference between\n ' group_names{1} ' and ' group_names{2} ' for auROC = %d\n\n'],pFDRanovanauROC);
        
        
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) output_suffix],'learn_sig','learn_not_sig','prof_sig','prof_not_sig');
        
        
        pffft=1
        
    case 11
        
        %Compare auROC for ERP LFP powerin between two percent correct windows
        no_dBs=1;
        delta_dB_power_fp1=[];
        no_ROCs=0;
        ROCoutfp1=[];
        ROCoutfp2=[];
        p_vals_ROC=[];
        delta_dB_powerfp1Ev1=[];
        no_Ev1=0;
        pvals_auROCperm=[];
        pvals_dBperm=[];
        perCorr_fp1=[];
        perCorr_fp2=[];
        shift_ii=floor(length(handles_drgb.drgb.lfpevpair(1).out_times)/2)+1+shift_from_event;
        
        
        
        if exist('which_electrodes')==0
            which_electrodes=[1:16];
        end
        
        sz_per=size(percent_windows);
        no_per_win=sz_per(1);
        
        
        
        fprintf(1, ['Pairwise auROC log power LFP ERP analysis for ' evTypeLabels{1} ' and ' evTypeLabels{2} ' LFP power\n\n'])
        p_vals=[];
        
        no_files=length(files);
        
        for fileNo=1:no_files
            
            
            for elec=1:16
                if sum(which_electrodes==elec)>0
                    lfpodNo=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                    
                    if ~isempty(handles_drgb.drgb.lfpevpair(lfpodNo))
                        
                        if ~isempty(handles_drgb.drgb.lfpevpair(lfpodNo).log_P_tERP)
                            
                            
                            for per_corr_ii=1:no_per_win
                                
                                these_per_corr=(handles_drgb.drgb.lfpevpair(lfpodNo).perCorrERP>=percent_windows(per_corr_ii,1))&...
                                    (handles_drgb.drgb.lfpevpair(lfpodNo).perCorrERP<=percent_windows(per_corr_ii,2));
                                
                                %Which trials have events (i.e. licks)?
                                trials_with_event=(handles_drgb.drgb.lfpevpair(lfpodNo).no_events_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNo).no_events_per_trial<=max_events_per_sec)...
                                    &(handles_drgb.drgb.lfpevpair(lfpodNo).no_ref_evs_per_trial>0)&(handles_drgb.drgb.lfpevpair(lfpodNo).no_ref_evs_per_trial<=max_events_per_sec);
                                
 
                                trials_in_Ev1=(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(event1,:)==1)&these_per_corr&trials_with_event;
                                trials_in_Ev2=(handles_drgb.drgb.lfpevpair(lfpodNo).which_eventERP(event2,:)==1)&these_per_corr&trials_with_event;
                                
                                if (sum(trials_in_Ev1)>=min_trials_per_event)&(sum(trials_in_Ev2)>=min_trials_per_event)
                                    
                                    %Ev1
                                    this_dB_powerEv1=zeros(sum(trials_in_Ev1),length(frequency));
                                    this_dB_powerEv1(:,:)=handles_drgb.drgb.lfpevpair(lfpodNo).log_P_tERP(trials_in_Ev1,:,shift_ii);
                                    
                                    %Ev2
                                    this_dB_powerEv2=zeros(sum(trials_in_Ev2),length(frequency));
                                    this_dB_powerEv2(:,:)=handles_drgb.drgb.lfpevpair(lfpodNo).log_P_tERP(trials_in_Ev2,:,shift_ii);
                                    
                                    for bwii=1:no_bandwidths
                                        
                                        no_ROCs=no_ROCs+1;
                                        this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                        
                                        %Enter Ev1
                                        this_delta_dB_powerEv1=zeros(sum(trials_in_Ev1),1);
                                        this_delta_dB_powerEv1=mean(this_dB_powerEv1(:,this_band),2);
                                        roc_data=[];
                                        roc_data(1:sum(trials_in_Ev1),1)=this_delta_dB_powerEv1;
                                        roc_data(1:sum(trials_in_Ev1),2)=zeros(sum(trials_in_Ev1),1);
                                        
                                        %Enter Ev2
                                        total_trials=sum(trials_in_Ev1)+sum(trials_in_Ev2);
                                        this_delta_dB_powerEv2=zeros(sum(trials_in_Ev2),1);
                                        this_delta_dB_powerEv2=mean(this_dB_powerEv2(:,this_band),2);
                                        roc_data(sum(trials_in_Ev1)+1:total_trials,1)=this_delta_dB_powerEv2;
                                        roc_data(sum(trials_in_Ev1)+1:total_trials,2)=ones(sum(trials_in_Ev2),1);
                                        
                                        
                                        %Find ROC
                                        ROCout(no_ROCs).roc=roc_calc(roc_data,0,0.05,0);
                                        ROCout(no_ROCs).fileNo=handles_drgb.drgb.lfpevpair(lfpodNo).fileNo;
                                        ROCper_corr_ii(no_ROCs)=per_corr_ii;
                                        ROCoutwin(no_ROCs)=winNo;
                                        ROCbandwidth(no_ROCs)=bwii;
                                        auROC(no_ROCs)=ROCout(no_ROCs).roc.AUC-0.5;
                                        p_valROC(no_ROCs)=ROCout(no_ROCs).roc.p;
                                        
                                        p_vals_ROC=[p_vals_ROC ROCout(no_ROCs).roc.p];
                                        
    
                                    end                            
                                    
                                else
                                    
                                    if (sum(trials_in_Ev1)<min_trials_per_event)
                                        fprintf(1, ['%d trials in ' evTypeLabels{1} ' percent window #%d fewer than minimum trials per event= %d for file No %d electrode %d\n'],sum(trials_in_Ev1), per_corr_ii, min_trials_per_event,fileNo,elec);
                                    end
                                    
                                    if (sum(trials_in_Ev2)<min_trials_per_event)
                                        fprintf(1, ['%d trials in ' evTypeLabels{2} ' percent window #%d fewer than minimum trials per event= %d for file No %d electrode %d\n'],sum(trials_in_Ev2), per_corr_ii, min_trials_per_event,fileNo,elec);
                                    end
                                    
                                end
                            end
                        else
                            fprintf(1, ['Empty allPower ERP for file No %d electrode %d\n'],files(fileNo),elec);
                        end
                        
                    else
                        fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],files(fileNo),elec);
                    end
                end
            end
        end
        fprintf(1, '\n\n')
        
        pFDRROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for significant difference of auROC p value from 0.5  = %d\n\n'],pFDRROC);
        
        
        
        fprintf(1, '\n\n')
        
        
        %Plot cumulative histos for auROCs
        %Initialize figure counter
        figNo=0;
        
        
         %Initializethe percent significant auROC graph
        try
            close(5)
        catch
        end
        figure(5)
        hold on
        x=0;
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            
            %Plot the histograms
            edges=[-0.5:0.05:0.5];
            pos2=[0.1 0.1 0.6 0.8];
            subplot('Position',pos2)
            hold on
                                        
            h2=histogram(auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1)),edges);
            h2.FaceColor='b';
            h1=histogram(auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2)),edges);
            h1.FaceColor='r';
            
            xlabel('auROC')
            ylabel('# of electrodes')
            legend(file_label{1},file_label{2})
            title(['auROC for ' freq_names{bwii}])
            xlim([-0.3 0.6])
            ylim([0 45])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Plot the single electrodes
            pos2=[0.8 0.1 0.1 0.8];
            subplot('Position',pos2)
            hold on
            plot(zeros(1,sum((ROCbandwidth==bwii)&(ROCper_corr_ii==1))),auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1)),'o', 'Color',[0.7 0.7 0.7])
            plot(ones(1,sum((ROCbandwidth==bwii)&(ROCper_corr_ii==2))),auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2)),'o', 'Color',[0.7 0.7 0.7])
   
            
            %PLot the mean and 95% CI
            plot([0 1],[mean(auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1))) mean(auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2)))],'-k','LineWidth', 3)
            CI = bootci(1000, @mean, auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1)));
            plot([0 0],CI,'-b','LineWidth',3)
            plot(0,mean(auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1))),'ob','MarkerSize', 10,'MarkerFace','b')
            CI = bootci(1000, @mean, auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2)));
            plot([1 1],CI,'-r','LineWidth',3)
            plot(1,mean(auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2))),'or','MarkerSize', 10,'MarkerFace','r')
            ylabel('auROC')
            ylim([-0.2 0.5])
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            %Do the statistics for auROC differences
            a={auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1)) auROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2))};
            mode_statcond='perm';
            [F df pval_auROCperm] = statcond(a,'mode',mode_statcond,'naccu', 1000); % perform an unpaired ANOVA
            fprintf(1, ['p value for permuted anovan for auROC S+ vs S- ' freq_names{bwii} '= %d\n\n'],  pval_auROCperm);
            pvals_auROCperm=[pvals_auROCperm pval_auROCperm];
            
          
            %Plot the bars in the percent significant auROC graph
            figure(5)
            percent_auROCper1=100*sum(p_valROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1))<=pFDRROC)/sum((ROCbandwidth==bwii)&(ROCper_corr_ii==1));
            bar(x,percent_auROCper1,'b')
            
            learn_sig(bwii)=sum(p_valROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1))<=pFDRROC);
            learn_not_sig(bwii)=sum((ROCbandwidth==bwii)&(ROCper_corr_ii==1)-sum(p_valROC((ROCbandwidth==bwii)&(ROCper_corr_ii==1))<=pFDRROC));

            percent_auROCper2=100*sum(p_valROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2))<=pFDRROC)/sum((ROCbandwidth==bwii)&(ROCper_corr_ii==2));
            bar(x+1,percent_auROCper2,'r')
            
            prof_sig(bwii)=sum(p_valROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2))<=pFDRROC);
            prof_not_sig(bwii)=sum((ROCbandwidth==bwii)&(ROCper_corr_ii==2)-sum(p_valROC((ROCbandwidth==bwii)&(ROCper_corr_ii==2))<=pFDRROC));
            
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            
            x=x+3;
            
        end
        
        figure(5)
        title('Percent singificant auROC')
        legend(file_label{1},file_label{2})
        ylim([0 100])
        
        pFDRanovanauROC=drsFDRpval(pval_auROCperm);
        fprintf(1, ['\npFDR for premuted anovan p value for difference between ' file_label{1} ' and ' file_label{2} ' for auROC = %d\n\n'],pFDRanovanauROC);
        
        
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) output_suffix],'learn_sig','learn_not_sig','prof_sig','prof_not_sig');
        
        pffft=1;
        
    case 12  
    %Justin
        %Generate Fig. 2  for Daniels' LFP power paper. For the proficient mice in the first and last sessions
        %plot the LFP spectrum for S+ vs S-, plot LFP power for S+ vs S- for each electrode and plot auROCs
        %NOTE: This does the analysis in all the files and DOES not distinguish between groups!!!
        no_dBs=1;
        delta_dB_power=[];
        no_ROCs=0;
        ROCout=[];
        p_vals_ROC=[];
        delta_dB_powerEv1=[];
        no_Ev1=0;
        for evNo=1:length(eventType)
            evNo_out(evNo).noWB=0;
        end
        delta_dB_powerEv1WB=[];
        delta_dB_powerEv2WB=[];

        
        fprintf(1, ['Pairwise auROC analysis for Fig 1 of Daniel''s paper\n\n'])
        p_vals=[];
        no_files=length(files);
        
        if exist('which_electrodes')==0
            which_electrodes=[1:16];
        end
        
        for fileNo=1:no_files
            for elec=1:16
                if sum(which_electrodes==elec)>0
                    lfpodNo_ref=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==refWin));
                    
                    if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNo_ref)))
                        
                        
                        if (~isempty(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower))
                            szpc=size(percent_windows);
                            for per_ii=1:szpc(1)
                                percent_mask=[];
                                percent_mask=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).perCorrLFPPower>=percent_windows(per_ii,1))...
                                    &(handles_drgb.drgb.lfpevpair(lfpodNo_ref).perCorrLFPPower<=percent_windows(per_ii,2));
                                
                                for evNo=1:length(eventType)
                                    
                                    
                                    trials_in_event_Ev=[];
                                    trials_in_event_Ev=(handles_drgb.drgb.lfpevpair(lfpodNo_ref).which_eventLFPPower(eventType(evNo),:)==1)&percent_mask;
                                    
                                    if (sum(trials_in_event_Ev)>=min_trials_per_event)
                                        
                                        lfpodNo=find((files_per_lfp==files(fileNo))&(elec_per_lfp==elec)&(window_per_lfp==winNo));
                                        
                                        % Ev1
                                        this_dB_powerref=zeros(sum(trials_in_event_Ev),length(frequency));
                                        this_dB_powerref(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo_ref).allPower(trials_in_event_Ev,:));
                                        
                                        
                                        this_dB_power=zeros(sum(trials_in_event_Ev),length(frequency));
                                        this_dB_power(:,:)=10*log10(handles_drgb.drgb.lfpevpair(lfpodNo).allPower(trials_in_event_Ev,:));
                                        
                                        %Wide band spectrum
                                        evNo_out(evNo).noWB=evNo_out(evNo).noWB+1;
                                        evNo_out(evNo).delta_dB_powerEvWB(evNo_out(evNo).noWB,1:length(frequency))=mean(this_dB_power-this_dB_powerref,1);
                                        evNo_out(evNo).per_ii(evNo_out(evNo).noWB)=per_ii;
                                        
                                        %Do per badwidth analysis
                                        for bwii=1:no_bandwidths
                                            
                                            this_band=(frequency>=low_freq(bwii))&(frequency<=high_freq(bwii));
                                            
                                            %Enter the  Ev1
                                            this_delta_dB_powerEv=zeros(sum(trials_in_event_Ev),1);
                                            this_delta_dB_powerEv=mean(this_dB_power(:,this_band)-this_dB_powerref(:,this_band),2);
                                            evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).noWB,bwii)=mean(this_delta_dB_powerEv);
                                            
                                        end
                                        
                                        
                                        fprintf(1, ['%d trials in event No %d succesfully processed for file No %d electrode %d\n'],sum(trials_in_event_Ev), min_trials_per_event,files(fileNo),elec);
                                        
                                    else
                                        
                                        
                                        fprintf(1, ['%d trials in event No %d fewer than minimum trials per event ' evTypeLabels{evNo} ' for file No %d electrode %d\n'],sum(trials_in_event_Ev), min_trials_per_event,files(fileNo),elec);
                                        
                                        
                                    end
                                    
                                    
                                end
                            end
                        else
                            
                            fprintf(1, ['Empty allPower for file No %d electrode %d\n'],files(fileNo),elec);
                            
                        end
                        
                        
                    else
                        fprintf(1, ['Empty lfpevpair for file No %d electrode %d\n'],files(fileNo),elec);
                        
                        
                    end
                end
            end
            
        end
        fprintf(1, '\n\n')
        
        
        %Now plot the bounded line for
        
        %Calculate and plot the mean and 95% CI for each event
        figure(1)
        for evNo=1:length(eventType)
            dB_Ev_ci=zeros(length(frequency),2);
            dB_Ev_mean=[];
            CI=[];
            dB_Ev_mean=mean(evNo_out(evNo).delta_dB_powerEvWB(evNo_out(evNo).per_ii==1,:));
            CI = bootci(1000, @mean, evNo_out(evNo).delta_dB_powerEvWB(evNo_out(evNo).per_ii==1,:));
            [hl1, hp1] = boundedline(frequency,dB_Ev_mean', CI', these_colors{evNo});
        end
        
        
        xlabel('Frequency (Hz)')
        ylabel('delta Power (dB)')
        ylim([-20 20]);
        title('Wideband spectrum proficient mice')
        %         legend('Hi1','', 'Hi2', '','Hi3','', 'Low4', '', 'Low5', '','Low6', '')
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
        
        %Calculate and plot the mean and 95% CI for each event
        figure(2)
        for evNo=1:length(eventType)
            dB_Ev_ci=zeros(length(frequency),2);
            dB_Ev_mean=[];
            dB_Ev_mean=mean(evNo_out(evNo).delta_dB_powerEvWB(evNo_out(evNo).per_ii==2,:));
            CI = bootci(1000, @mean, evNo_out(evNo).delta_dB_powerEvWB(evNo_out(evNo).per_ii==2,:));
            [hl1, hp1] = boundedline(frequency,dB_Ev_mean', CI', these_colors{evNo});
        end
        
        
        xlabel('Frequency (Hz)')
        ylabel('delta Power (dB)')
           ylim([-5 10]);
        title('Wideband spectrum naive mice')
        legend('Hi1','', 'Hi2', '','Hi3','', 'Low4', '', 'Low5', '','Low6', '')
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
        ylim([-20 20])
        
        %Now plot the histograms and the average
        for bwii=1:4
            %Plot the average
            figure(bwii+2)
            
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            hold on
            
            data_dB=[];
            spm=[];
            conc=[];
            
            for evNo=1:length(eventType)
                
                for per_ii=1:2
                    if per_ii==1
                        bar_offset=14-evNo*2+1;
                        bar(bar_offset,mean(evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==2,bwii)),'r','LineWidth', 3)
                        plot(bar_offset,mean(evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==2,bwii)),'ok','LineWidth', 3)
                        CI = bootci(1000, @mean, evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==2,bwii));
                        plot([bar_offset bar_offset],CI,'-k','LineWidth',3)
                        plot((bar_offset)*ones(1,sum(evNo_out(evNo).per_ii==2)),evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==2,bwii),'o',...
                            'MarkerFaceColor',[0.7 0.7 0.7],'MarkerEdgeColor',[0.7 0.7 0.7])
                        data_dB=[data_dB evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==2,bwii)'];
                        switch evNo
                            case {1,2,3}
                                spm=[spm zeros(1,evNo_out(evNo).noWB)];
                                
                            case {4,5,6}
                                spm=[spm ones(1,evNo_out(evNo).noWB)];
                        end
                        conc=[conc evNo*ones(1,evNo_out(evNo).noWB)];
                    else
                        bar_offset=14-evNo*2;
                        bar(bar_offset,mean(evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==1,bwii)),'b','LineWidth', 3)
                        plot(bar_offset,mean(evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==1,bwii)),'ok','LineWidth', 3)
                        CI = bootci(1000, @mean, evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==1,bwii));
                        plot([bar_offset bar_offset],CI,'-k','LineWidth',3)
                        plot((bar_offset)*ones(1,sum(evNo_out(evNo).per_ii==1)),evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==1,bwii),'o',...
                            'MarkerFaceColor',[0.7 0.7 0.7],'MarkerEdgeColor',[0.7 0.7 0.7])
                        data_dB=[data_dB evNo_out(evNo).mean_delta_dB_powerEvperBW(evNo_out(evNo).per_ii==1,bwii)'];
                        switch evNo
                            case {1,2,3}
                                spm=[spm zeros(1,evNo_out(evNo).noWB)];
                                
                            case {4,5,6}
                                spm=[spm ones(1,evNo_out(evNo).noWB)];
                        end
                        conc=[conc evNo*ones(1,evNo_out(evNo).noWB)];
                    end
                end
            end
            
            p=anovan(data_dB,{spm});
        end
        
        
        pFDRanovan=drsFDRpval(pvals_perm);
        fprintf(1, ['pFDR for premuted anovan p value  = %d\n\n'],pFDRanovan);
        
        
        
        fprintf(1, '\n\n')
        
        
        pFDRauROC=drsFDRpval(p_vals_ROC);
        fprintf(1, ['pFDR for auROC  = %d\n\n'],pFDRauROC);
        %Plot cumulative histos for auROCs
        
        figNo=5;
        p_val_ROC=[];
        edges=-0.5:0.05:0.5;
        
        for bwii=1:4
            figNo=figNo+1;
            try
                close(figNo)
            catch
            end
            figure(figNo)
            set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
            hold on
            n_cum=0;
            this_legend=[];
            
            histogram(auROC(( p_valROC>pFDRauROC)&(ROCbandwidth==bwii)),edges)
            histogram(auROC(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii)),edges)
            legend('auROC not singificant','auROC significant')
            title(['Histogram for ' freq_names{bwii} ' auROC for LFPs'])
            xlim([-0.2 0.6])
            ylim([0 30])
        end
        
        
        
        %Plot percent significant ROC
        figNo=figNo+1;
        try
            close(figNo)
        catch
        end
        figure(figNo)
        
        hold on
        
        for bwii=1:4
            bar(bwii,100*sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii))/sum((ROCbandwidth==bwii)))
            auROC_sig.sig(bwii)=sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii));
            auROC_sig.not_sig(bwii)=sum((ROCbandwidth==bwii))-sum(( p_valROC<=pFDRauROC)&(ROCbandwidth==bwii));
        end
        title('Percent auROC significantly different from zero')
        ylim([0 100])
        set(gca,'FontName','Arial','FontSize',12,'FontWeight','Bold',  'LineWidth', 2)
        pffft=1;
        
        save([handles.PathName handles.drgb.outFileName(1:end-4) output_suffix],'auROC_sig');
end

