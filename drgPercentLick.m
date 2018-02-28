function drgPercentLick(handles)

% it calls Problick.m (that calculates probability values associated with the
% animal's behaviour) and Simrand.m (that generates simulations of randomly
% behaving animals), then plots the probability curves.

% A= [ 1 1 1 1 0 1 0 1 1 0 1 0 1 1 1 1 1 0 0 1 1 1 0 0 1 0 1 0 1 0 1 1 0 1 0 0 1 ]
% B= [ 1 0 0 1 0 1 1 0 1 0 0 0 1 1 0 1 0 0 1 1 0 1 0 1 1 1 0 0 1 0 1 1 0 1 0 0 1 ]
% times=1:10:370;

handles=drgPercentLickPerTrial(handles);

odorOn=2;
splus=5;
hit=3;
miss=7;
CR=9;
FA=13;
sminus=11;

sessionNo=handles.drg.unit(handles.unitNo).sessionNo;

splus_or_minus=[];
animal_licked=[];

for ii=1:handles.drg.session(sessionNo).events(odorOn).noTimes
    times(ii)=handles.drg.session(sessionNo).events(odorOn).times(ii);
    if sum(handles.drg.session(sessionNo).events(odorOn).times(ii)==handles.drg.session(sessionNo).events(splus).times)>0
        %This is S+
        splus_or_minus(ii)=1;
        if sum(handles.drg.session(sessionNo).events(odorOn).times(ii)==handles.drg.session(sessionNo).events(hit).times)>0
            %Animal licked
            animal_licked(ii)=1;
        else
            animal_licked(ii)=0;
        end
    else
        %This is S-
        splus_or_minus(ii)=0;
        if sum(handles.drg.session(sessionNo).events(odorOn).times(ii)==handles.drg.session(sessionNo).events(FA).times)>0
            %Animal licked
            animal_licked(ii)=1;
        else
            animal_licked(ii)=0;
        end
    end
end
   
Behavior.lick = animal_licked;
Behavior.avail =  splus_or_minus;
Behavior.time = times;
blocktimes=[];
blocklabels=[];
lenlick = length(Behavior.lick);
for u=1:(lenlick/20)
    blocktimes(end+1) = times(20*u);
    blocklabels(end+1) = u;
    u=u+1;
end

% creates the gonogo structure

gonogo.lick = animal_licked;
gonogo.avail = splus_or_minus;
gonogo.time =times;
gonogo.proba = [];
gonogo.avesim =[];
gonogo.prctile5 =[];
gonogo.graphHit =[];
gonogo.graphFA =[];
gonogo.graphCR = [];
gonogo.graphMiss =[];
gonogo.criterion =[];
gonogo.blocktimes =[];
gonogo.progress=[];
gonogo.graphlick = [];
gonogo.graphhit = [];
gonogo.graphFA = [];

gonogo.wilcoxon=[];
gonogo.wilcoxon(1:20)=ones;


% if Behavior.time(end)<= Behavior.time(end-1)
%     Behavior.time(end) = Behavior.time(end-1)+ 1;
% end
% 
% gonogo.cumulick=[];
% gonogo.cumulFA=[];
% gonogo.cumulHit=[];
% gonogo.ratiolick=[];   
% n_lick = 0;
% n_hits = 0;
% n_FA = 0;
% for i = 1:lenlick
%     gonogo.time(end+1)= Behavior.time(i);
%     if (gonogo.lick(i) == 1)
%         n_lick=n_lick + 1;
%         if gonogo.avail(i) == 1
%             n_hits=n_hits +1;
%         else n_FA=n_FA+1;
%         end
%     end
%     gonogo.cumulick(i)=n_lick;
%     gonogo.cumulHit(i)=n_hits;
%     gonogo.cumulFA(i)=n_FA;
%   gonogo.ratiolick(i) = (n_hits/n_lick) * 100;
% end

%creates data for histograms of Hits and False Alarms

% gonogo.histohit=[];
% gonogo.histoFA=[];
% gonogo.histohit(1)=gonogo.cumulHit(20);
% gonogo.histoFA(1)=gonogo.cumulFA(20);
% for u=2:(lenlick/20)
%     gonogo.histohit(u) = gonogo.cumulHit(20*u) - gonogo.cumulHit((20*u)-20);
%     gonogo.histoFA(u) = gonogo.cumulFA(20*u) - gonogo.cumulFA((20*u)-20);
% end
% 
% % computes a wilcoxon test comparing licks on s+ and s- for all the trials
% lickswilcoxon=[];
% lickswilcoxon=ranksum(gonogo.histohit,gonogo.histoFA);
% str1 = lickswilcoxon;


%% 
%calculates probabilities associated with the behavior (calling probLick)
%and with the random simulations generated by calling Simrand

gonogo.proba = drgProbLick(gonogo.lick, gonogo.avail);
[gonogo.avesim,gonogo.prctile5] = drgSimRand(gonogo.lick,gonogo.avail);
gonogo.graphHit = gonogo.lick & gonogo.avail;
gonogo.graphFA =gonogo.lick & ~gonogo.avail;
gonogo.graphCR = ~gonogo.lick & ~gonogo.avail;
gonogo.graphMiss = ~gonogo.lick & gonogo.avail;
%gonogo.criterion = perCor;
gonogo.blocktimes = blocktimes;
gonogo.progress = ((35.*(gonogo.avesim - gonogo.proba))./(gonogo.avesim - gonogo.prctile5))+50;
% 
% for o=1:lenlick-20
% %     if sum(gonogo.proba(o:o+20)) <= sum(gonogo.prctile5(o:o+20))
%     gonogo.wilcoxon(o+20) = ranksum(gonogo.prctile5(o:o+20),gonogo.proba(o:o+20)) 
% %     else gonogo.wilcoxon(o+20) = 0.5
% %     end
% end

%%
gonogo.graphproba=[];
for p=1:lenlick/20
   gonogo.graphproba(p)= gonogo.proba(20*p);
end
str = num2str(gonogo.graphproba,3);
%%
%calculates intertrial intervals and build the distribution by 5 sec
%increments
% 
gonogo.intertrial=[];
for j=2:lenlick
    gonogo.intertrial(j)=gonogo.time(j)-gonogo.time(j-1);
    j=j+1;
end
hist_intertrial= histc(gonogo.intertrial,[5 10 15 20 25 30 35 40 45 50 100]);
% 
% dimensions = size(gonogo.lick);
gonogo.deltaP=[];

for k=2:lenlick
    gonogo.deltaP(k)=gonogo.proba(k)-gonogo.proba(k-1);
    k=k+1;
end




%creates figure for probability vs time  
try
    close 1
catch
end

hFig1 = figure(1);
set(hFig1, 'units','normalized','position',[.05 .15 .85 .3])



hold('all');

%Plot the percent lick
yyaxis right
li_ii=0;
legendInfo=[];
p1=plot(gonogo.time(gonogo.graphHit==1),handles.drg.session(sessionNo).percent_lick(gonogo.graphHit==1),' vr', 'MarkerFaceColor','r', 'MarkerSize',7);
if ~isempty(p1)
    li_ii=li_ii+1;
    legendInfo{li_ii} = 'Hit';
end
p2=plot(gonogo.time(gonogo.graphMiss==1),handles.drg.session(sessionNo).percent_lick(gonogo.graphMiss==1),' vr','MarkerFaceColor','r', 'MarkerSize',3);
if ~isempty(p2)
    li_ii=li_ii+1;
    legendInfo{li_ii} = 'Miss';
end
p3=plot(gonogo.time(gonogo.graphFA==1),handles.drg.session(sessionNo).percent_lick(gonogo.graphFA==1),' vb','MarkerFaceColor','b', 'MarkerSize',3);
if ~isempty(p3)
    li_ii=li_ii+1;
    legendInfo{li_ii} = 'FA';
end
p4=plot(gonogo.time(gonogo.graphCR==1),handles.drg.session(sessionNo).percent_lick(gonogo.graphCR==1),' vb', 'MarkerFaceColor','b', 'MarkerSize',7);
if ~isempty(p4)
    li_ii=li_ii+1;
    legendInfo{li_ii} = 'CR';
end
legend(legendInfo)
ax=gca;
set(ax,'YTick',[0 50 100]);
ylim([0 125])
ylabel('Percent lick')



%Plot Busquet's probability
yyaxis left
plot(gonogo.time,gonogo.proba,'-r','LineWidth',2);
plot(gonogo.time,gonogo.avesim,'-k','LineWidth',1);
plot(gonogo.time,gonogo.prctile5,'--k','LineWidth',1);
ax=gca;
set(ax,'YTick',[0.05 .5 1]);
xlim([0 gonogo.time(end)])
ylim([0 1.25])
ylabel('Probability')
xlabel('Time (sec)')
plot([gonogo.time(1) gonogo.time(end)],[0.05 0.05],'--k');
plot([gonogo.time(1) gonogo.time(end)],[0.5 0.5],'--k');
title 'Left: probability (red) average sim(black) 5 prctile sim (dotted), Right: Percent lick' 



%creates figure for probability vs trial number 
try
    close 2
catch
end

hFig2 = figure(2);
set(hFig2, 'units','normalized','position',[.05 .55 .85 .3])




hold('all');
trials=[1:length(gonogo.time)];

%Plot the percent lick
yyaxis right
li_ii=0;
legendInfo=[];
p1=plot(trials(gonogo.graphHit==1),handles.drg.session(sessionNo).percent_lick(gonogo.graphHit==1),' vr', 'MarkerFaceColor','r', 'MarkerSize',7);
if ~isempty(p1)
    li_ii=li_ii+1;
    legendInfo{li_ii} = 'Hit';
end
p2=plot(trials(gonogo.graphMiss==1),handles.drg.session(sessionNo).percent_lick(gonogo.graphMiss==1),' vr','MarkerFaceColor','r', 'MarkerSize',3);
if ~isempty(p2)
    li_ii=li_ii+1;
    legendInfo{li_ii} = 'Miss';
end
p3=plot(trials(gonogo.graphFA==1),handles.drg.session(sessionNo).percent_lick(gonogo.graphFA==1),' vb','MarkerFaceColor','b', 'MarkerSize',3);
if ~isempty(p3)
    li_ii=li_ii+1;
    legendInfo{li_ii} = 'FA';
end
p4=plot(trials(gonogo.graphCR==1),handles.drg.session(sessionNo).percent_lick(gonogo.graphCR==1),' vb', 'MarkerFaceColor','b', 'MarkerSize',7);
if ~isempty(p4)
    li_ii=li_ii+1;
    legendInfo{li_ii} = 'CR';
end
legend(legendInfo)
ax=gca;
set(ax,'YTick',[0 50 100]);
ylim([0 125])
ylabel('Percent lick')



%Plot Busquet's probability
yyaxis left
plot(trials,gonogo.proba,'-r','LineWidth',2);
plot(trials,gonogo.avesim,'-k','LineWidth',1);
plot(trials,gonogo.prctile5,'--k','LineWidth',1);
ax=gca;
set(ax,'YTick',[0.05 .5 1]);
xlim([0 trials(end)])
ylim([0 1.25])
ylabel('Probability')
xlabel('Trial No')
plot([trials(1) trials(end)],[0.05 0.05],'--k');
plot([trials(1) trials(end)],[0.5 0.5],'--k');
title 'Left: probability (red) average sim(black) 5 prctile sim (dotted), Right: Percent lick'


% 
% hold('all');
% trials=[1:length(gonogo.time)];
% plot(trials,gonogo.proba,'-r','LineWidth',2);
% plot(trials,gonogo.avesim,'-k','LineWidth',1);
% plot(trials,gonogo.prctile5,'--k','LineWidth',1);
% plot(trials(gonogo.graphHit==1),gonogo.graphHit(gonogo.graphHit==1)+.05,' vg', 'MarkerFaceColor','g', 'MarkerSize',5);
% plot(trials(gonogo.graphMiss==1),gonogo.graphMiss(gonogo.graphMiss==1)+.05,' vr','MarkerFaceColor','r', 'MarkerSize',2);
% plot(trials(gonogo.graphFA==1),gonogo.graphFA(gonogo.graphFA==1)+.15,' vr','MarkerFaceColor','r', 'MarkerSize',5);
% plot(trials(gonogo.graphCR==1),gonogo.graphCR(gonogo.graphCR==1)+.15,' vg', 'MarkerFaceColor','g', 'MarkerSize',2);
% ax=gca;
% set(ax,'YTick',[0.05 .5 1]);
% xlim([0 trials(end)])
% ylim([0 1.25])
% ylabel('Probability')
% xlabel('Trial No')
% plot([0 trials(end)],[0.05 0.05],'--k');
% plot([0 trials(end)],[0.5 0.5],'--k');
% title 'probability associated with the observed behavior(thick red line) average(black line) and 5th percentile(dotted black line) random behavior' 


