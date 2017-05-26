function handles=drgBusquetAnalysis(handles)

% it calls Problick.m (that calculates probability values associated with the
% animal's behaviour) and Simrand.m (that generates simulations of randomly
% behaving animals)

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

handles.gonogo.lick = animal_licked;
handles.gonogo.avail = splus_or_minus;
handles.gonogo.time =times;
handles.gonogo.proba = [];
handles.gonogo.avesim =[];
handles.gonogo.prctile5 =[];
handles.gonogo.graphHit =[];
handles.gonogo.graphFA =[];
handles.gonogo.graphCR = [];
handles.gonogo.graphMiss =[];
handles.gonogo.criterion =[];
handles.gonogo.blocktimes =[];
handles.gonogo.progress=[];
handles.gonogo.graphlick = [];
handles.gonogo.graphhit = [];
handles.gonogo.graphFA = [];

handles.gonogo.wilcoxon=[];
handles.gonogo.wilcoxon(1:20)=ones;



%% 
%calculates probabilities associated with the behavior (calling probLick)
%and with the random simulations generated by calling Simrand

handles.gonogo.proba = drgProbLick(handles.gonogo.lick, handles.gonogo.avail);
[handles.gonogo.avesim,handles.gonogo.prctile5] = drgSimRand(handles.gonogo.lick,handles.gonogo.avail);
handles.gonogo.graphHit = handles.gonogo.lick & handles.gonogo.avail;
handles.gonogo.graphFA =handles.gonogo.lick & ~handles.gonogo.avail;
handles.gonogo.graphCR = ~handles.gonogo.lick & ~handles.gonogo.avail;
handles.gonogo.graphMiss = ~handles.gonogo.lick & handles.gonogo.avail;
%handles.gonogo.criterion = perCor;
handles.gonogo.blocktimes = blocktimes;
handles.gonogo.progress = ((35.*(handles.gonogo.avesim - handles.gonogo.proba))./(handles.gonogo.avesim - handles.gonogo.prctile5))+50;


%%
handles.gonogo.graphproba=[];
for p=1:lenlick/20
   handles.gonogo.graphproba(p)= handles.gonogo.proba(20*p);
end

%%
%calculates intertrial intervals and build the distribution by 5 sec
%increments
% 
handles.gonogo.intertrial=[];
for j=2:lenlick
    handles.gonogo.intertrial(j)=handles.gonogo.time(j)-handles.gonogo.time(j-1);
    j=j+1;
end
handles.gonogo.hist_intertrial= histc(handles.gonogo.intertrial,[5 10 15 20 25 30 35 40 45 50 100])
% 
% dimensions = size(handles.gonogo.lick);
handles.gonogo.deltaP=[];

for k=2:lenlick
    handles.gonogo.deltaP(k)=handles.gonogo.proba(k)-handles.gonogo.proba(k-1);
    k=k+1;
end
