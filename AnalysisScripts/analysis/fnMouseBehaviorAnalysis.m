function fnMouseBehaviorAnalysis(strctKofiko, strOutputFolder)
%

% Copied from Touch Force Choice Behavior Analysis
strSubject = strctKofiko.g_strctAppConfig.m_strctSubject.m_strName;
strTimeDate = strctKofiko.g_strctAppConfig.m_strTimeDate;
strTimeDate(strTimeDate == ':') = '-';
strTimeDate(strTimeDate == ' ') = '_';

acParadigms = fnCellStructToArray(strctKofiko.g_astrctAllParadigms,'m_strName');
iParadigmIndex = find(ismember(acParadigms,'Touch Force Choice'),1,'first');
if isempty(iParadigmIndex)
    fnWorkerLog('Session : %s does not contain force choice. Aborting!',strSession);
    return;
end;

strctParadigm = strctKofiko.g_astrctAllParadigms{iParadigmIndex};

iNumDesigns = length(strctParadigm.ExperimentDesigns.Buffer);
acAllDesigns = {};
for iIter=1:iNumDesigns
    if ~isempty(strctParadigm.ExperimentDesigns.Buffer{iIter})
        acAllDesigns{iIter} = strctParadigm.ExperimentDesigns.Buffer{iIter}.m_strDesignFileName;
    else
        acAllDesigns{iIter} = '';
    end
end
acUniqueDesigns = unique(setdiff(acAllDesigns,{''}));
iNumUniqueDesigns = length(acUniqueDesigns);
fnWorkerLog('%d unique designs were loaded',iNumUniqueDesigns);

afDesignOnsetTimeStampsAug=  [strctParadigm.ExperimentDesigns.TimeStamp,Inf];

iNumTrials = length(strctParadigm.acTrials.TimeStamp);

iCounter = 1;
for iUniqueDesignIter=1:iNumUniqueDesigns
    strDesignName = acUniqueDesigns{iUniqueDesignIter};
    [strPath,strShortDesignName]=fileparts(strDesignName);
    fnWorkerLog('* Design: %s (%s)',strShortDesignName,strDesignName)
    
    % Find the relevant design onset and offset
    aiInd = find(ismember(acAllDesigns, strDesignName));
    strctDesign = strctParadigm.ExperimentDesigns.Buffer{aiInd(1)};
    
    abRelevantTrials = zeros(1,iNumTrials)>0;
    for iIter=1:length(aiInd)
        fOnset_TS_Kofiko = afDesignOnsetTimeStampsAug(aiInd(iIter));
        fOffset_TS_Kofiko = afDesignOnsetTimeStampsAug(aiInd(iIter)+1);
        % Find relevant trials
        abRelevantTrials(strctParadigm.acTrials.TimeStamp >=fOnset_TS_Kofiko & strctParadigm.acTrials.TimeStamp <=fOffset_TS_Kofiko) = true;
    end
    if sum(abRelevantTrials) == 0
        fnWorkerLog(' - Skipping. no trials found for this design');
        continue;
    end;
    
    % OK, now that we have collected all relevant trials, how many
    % different trial types do we have for this design?
    aiRelevantTrials = find(abRelevantTrials);
    acTrials = strctParadigm.acTrials.Buffer(abRelevantTrials);
    
    aiTrialTypes = fnCellStructToArray(strctParadigm.acTrials.Buffer(abRelevantTrials),'m_iTrialType');
    [aiUniqueTrialTypes, Dummy, aiTrialTypeToUniqueTrialType] = unique(aiTrialTypes);
%   acTrials=fnReanalyzeSaccadeTrials(acTrials,strRawFolder,strSession,strctSync,strctKofiko);
   
    
    iNumUniqueTrialTypes = length(aiUniqueTrialTypes);
    aiNumTrialRep = histc(aiTrialTypeToUniqueTrialType,1:iNumUniqueTrialTypes);
    fnWorkerLog('Found %d trials, which belong to %d unique trial types', length(aiTrialTypes), iNumUniqueTrialTypes);
    
    acAllOutcomes = cell(1, length(aiRelevantTrials));
    for j=1:length(aiRelevantTrials)
        acAllOutcomes{j}=strctParadigm.acTrials.Buffer{aiRelevantTrials(j)}.m_strctTrialOutcome.m_strResult;
    end
    [acUniqueOutcomes,Dummy, aiOutcomeToUnique] = unique(acAllOutcomes);
    iNumUniqueOutcomes = length(acUniqueOutcomes);

    
    
    
    % now iterate over each trial type and compute histogram of outcomes.
    
    a2cTrialInd = cell(iNumUniqueTrialTypes, iNumUniqueOutcomes);
    a2fNumTrials = zeros(iNumUniqueTrialTypes, iNumUniqueOutcomes);
    acUniqueTrialNames = cell(1,iNumUniqueTrialTypes);
    for iUniqueTrialIter=1:iNumUniqueTrialTypes
        iTrialType = aiUniqueTrialTypes(iUniqueTrialIter);
        strctTrialType = strctDesign.m_acTrialTypes{iTrialType};
        strTrialName = strctTrialType.TrialParams.Name;
        
        acUniqueTrialNames{iUniqueTrialIter} =strTrialName;
        aiLocalInd = find(aiTrialTypes == iTrialType);
        aiSameTrialTypeInd = aiRelevantTrials(aiLocalInd);
        
        % Add saccade information to trial?
        acTrialsOfSameType = strctParadigm.acTrials.Buffer(aiSameTrialTypeInd);
 
        %acTrialsOfSameType = fnAnalyzeMemorySaccadeTrials(acTrialsOfSameType,strctKofiko,strctSync,strRawFolder,strSession);
           
        iNumSameTrialType = length(acTrialsOfSameType);
        fnWorkerLog('%d trials of  Trial Type : %s',iNumSameTrialType,strTrialName);drawnow
        acTrialOutcome = cell(1,iNumSameTrialType);
        for k=1:iNumSameTrialType
            acTrialOutcome{k} = acTrialsOfSameType{k}.m_strctTrialOutcome.m_strResult;
        end
        for iUniqueOutcomeIter=1:iNumUniqueOutcomes
            aiInd2 = find(ismember(acTrialOutcome, acUniqueOutcomes{iUniqueOutcomeIter}));
            %aiGlobalTrialInd = aiSameTrialTypeInd(aiInd2);
            %acSameTrialsSameOutcome = acTrialsOfSameType(aiInd2);
            a2cTrialInd{iUniqueTrialIter,iUniqueOutcomeIter} = aiLocalInd(aiInd2);
            %fprintf('Processing outcome %s (%d trials) \n',acUniqueOutcomes{iUniqueOutcomeIter}, length(acSameTrialsSameOutcome));
            a2fNumTrials(iUniqueTrialIter, iUniqueOutcomeIter) =sum(ismember(acTrialOutcome, acUniqueOutcomes{iUniqueOutcomeIter}));
        end
    end
    
    a2fNumTrialsNormalized = a2fNumTrials ./ repmat(sum(a2fNumTrials,2),1, length(acUniqueOutcomes));
   clear strctDesignStat
   strctDesignStat.m_strDisplayFunction = 'fnDefaultForceChoiceBehaviorStatistics';
   strctDesignStat.m_acTrials = acTrials;
   %strctDesignStat.m_astrctTrialsPostProc = fnExtractPostProcessingData(acTrials, strctKofiko, strctSync, strRawFolder,strSession);
   
   strctDesignStat.m_strDesignName = strDesignName;
   strctDesignStat.m_strctDesign = strctDesign;
   strctDesignStat.m_acUniqueOutcomes = acUniqueOutcomes;
   strctDesignStat.m_acUniqueTrialNames = acUniqueTrialNames;
   strctDesignStat.m_aiUniqueTrialTypes = aiUniqueTrialTypes;
   strctDesignStat.m_a2cTrialsIndicesSorted = a2cTrialInd;
   strctDesignStat.m_a2fNumTrials = a2fNumTrials;
   strctDesignStat.m_a2fNumTrialsNormalized = a2fNumTrialsNormalized;
   strctDesignStat.m_aiTrialTypeMappedToUnique = aiTrialTypeToUniqueTrialType;
   strctDesignStat.m_aiTrialOutcomeMappedToUnique = aiOutcomeToUnique;

    strctDesignStat = fnAddAttribute(strctDesignStat,'Subject', strSubject);
    strctDesignStat = fnAddAttribute(strctDesignStat,'TimeDate', strctKofiko.g_strctAppConfig.m_strTimeDate);
    strctDesignStat = fnAddAttribute(strctDesignStat,'Type','Behavior Statistics');
    strctDesignStat = fnAddAttribute(strctDesignStat,'Paradigm','Touch Force Choice');
    strctDesignStat = fnAddAttribute(strctDesignStat,'Design', strShortDesignName);
    strctDesignStat = fnAddAttribute(strctDesignStat,'NumTrials',  num2str(sum(abRelevantTrials)));

    strStatFile = [strOutputFolder, filesep, strSubject,'-',strTimeDate,'_TouchForceChoice_BehaviorStat_',strShortDesignName];
    fprintf('Saving things to %s...',strStatFile);
    
    save(strStatFile,'strctDesignStat','-V6');
    fprintf('Done!\n');
end

figure(12);clf;
barh(1:iNumUniqueTrialTypes,a2fNumTrialsNormalized)
legend(acUniqueOutcomes)
set(gca,'ytick', 1:iNumUniqueTrialTypes,'yticklabel',acUniqueTrialNames);
xlabel('Percentage of trials');
figure(13);clf;
bar(a2fNumTrialsNormalized,'stacked');
legend(acUniqueOutcomes,'location','northoutside')
set(gca,'ylim',[0 1])
ylabel('Percentage of trials');
set(gca,'xtick', 1: iNumUniqueTrialTypes, 'xticklabel',acUniqueTrialNames);
xticklabel_rotate;

% Matrix of statistics including timestamps
stats = zeros(iNumTrials, 4);
for i=2:iNumTrials
    trial = strctParadigm.acTrials.Buffer{i};
    trialtype = trial.m_iTrialType;
    time = trial.m_strctTrialOutcome.m_afSelectedChoiceTS - trial.m_strctTrialOutcome.m_fChoicesOnsetTS_Kofiko;
    SelectedChoice = trial.m_strctTrialOutcome.m_aiSelectedChoice;
    strResult = trial.m_strctTrialOutcome.m_strResult;
    if strResult == 'Incorrect'
        result = 0;
    else
        result = 1;
    end;        
    stats(i,:) = [trialtype, time, SelectedChoice, result]
end
end

