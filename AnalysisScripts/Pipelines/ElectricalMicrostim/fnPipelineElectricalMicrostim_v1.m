function fnPipelineElectricalMicrostim_v1(strctInputs)
clear global g_acDesignCache

strDataRootFolder = strctInputs.m_strDataRootFolder;
strConfigFolder   = strctInputs.m_strConfigFolder;
strSession        = strctInputs.m_strSession;

if strDataRootFolder(end) ~= filesep()
    strDataRootFolder(end+1) = filesep();
end;
fnWorkerLog('Starting optogenetics microstim standard analysis pipline...');
fnWorkerLog('Session : %s',strSession);
fnWorkerLog('Data Root : %s',strDataRootFolder);

strRawFolder = [strDataRootFolder,'RAW',filesep()];
strKofikoFile = fullfile(strRawFolder,[strSession,'.mat']);
strAdvancerFile = fullfile(strRawFolder,[strSession,'-Advancers.txt']);
strStatServerFile = fullfile(strRawFolder,[strSession,'-StatServerInfo.mat']);
strStrobeFile = fullfile(strRawFolder,[strSession,'-strobe.raw']);
strAnalogFile = fullfile(strRawFolder,[strSession,'-EyeX.raw']);  % any can suffice...
strSyncFile = fullfile(strRawFolder,[strSession,'-sync.mat']);

aiInd = find(strSession=='_');
strSubject = strSession(aiInd(2)+1:end);
strTimeDate = strSession(1:aiInd(2)-1);

strTriggerFile = fullfile(strRawFolder,[strSession,'-Stimulation_Trig.raw']);

strOutputFolder = [strDataRootFolder,'Processed',filesep(),'Optogenetic_Analysis',filesep()];
if ~exist(strOutputFolder,'dir')
    mkdir(strOutputFolder);
end;

%% Verify everything is around.
fnCheckForFilesExistence({strKofikoFile, strAdvancerFile, strStatServerFile,...
    strStrobeFile,strAnalogFile,strSyncFile,strTriggerFile});

% Load needed information to do processing
load(strSyncFile);
strctKofiko = load(strKofikoFile);
strctStatServer = load(strStatServerFile);

%%
%% Read advancer file for electrode position during the experiments...
a2fTemp = textread(strAdvancerFile);
afDepthRelativeToGridTop = a2fTemp(:,2);
aiAdvancerUniqueID = a2fTemp(:,1);
afAdvancerChangeTS_StatServer = a2fTemp(:,6);
afAdvancerChangeTS_Plexon = fnTimeZoneChange(afAdvancerChangeTS_StatServer,strctSync,'StatServer','Plexon');

strctAdvancersInformation.m_afDepthRelativeToGridTop = afDepthRelativeToGridTop;
strctAdvancersInformation.m_aiAdvancerUniqueID = aiAdvancerUniqueID;
strctAdvancersInformation.m_afAdvancerChangeTS_Plexon = afAdvancerChangeTS_Plexon;

strStatFolder = [strDataRootFolder,filesep,'Processed',filesep,'ElectricalMicrostim',filesep()];
if ~exist(strStatFolder,'dir')
    mkdir(strStatFolder);
end;

% Compute eye movement triggered by some channel
[strctTrigger, afTriggerTime] = fnReadDumpAnalogFile(strTriggerFile);
[Dummy,astrctPulseIntervals] = fnIdentifyStimulationTrains(strctTrigger,afTriggerTime, false);

 if isempty(astrctPulseIntervals)
     fnWorkerLog('Failed to find any trigger information');
     return;
 end;
 
 afTrainOnsets_TS_PLX = afTriggerTime( cat(1,astrctPulseIntervals.m_iStart));


aiActiveRecordingChannels = strctStatServer.g_strctNeuralServer.m_aiActiveSpikeChannels;
for k=1:length(aiActiveRecordingChannels)
    iChannelID=aiActiveRecordingChannels(k);
    fnAnalyzeEyeMovementsDuringMicroStimAsFunctionOfDepth(strctKofiko,strctSync,strRawFolder,strSession,iChannelID, strctAdvancersInformation,strctStatServer,afTrainOnsets_TS_PLX, strStatFolder);
end

return;

function fnCheckForFilesExistence(acFileList)
for k=1:length(acFileList)
    if ~exist(acFileList{k},'file')
        fprintf('File is missing : %s\n',acFileList{k});
        error('FileMissing');
    end
end




function fnAnalyzeEyeMovementsDuringMicroStimAsFunctionOfDepth(strctKofiko,strctSync,strRawFolder,strSession, iChannelID, strctAdvancersInformation,strctStatServer,afTrainOnsets_TS_PLX,  strOutputFolder)
strEyeXFile = fullfile(strRawFolder,[strSession,'-EyeX.raw']);  
strEyeYFile = fullfile(strRawFolder,[strSession,'-EyeY.raw']);  


% Merge very similar trains
iAdvancerUniqueID = strctStatServer.g_strctNeuralServer.m_a2iChannelToGridHoleAdvancer(iChannelID,3);
fMergeDistanceMM = 0.2;
afSampleAdvancerTimes = afTrainOnsets_TS_PLX;
afIntervalDepthMM= fnMyInterp1(strctAdvancersInformation.m_afAdvancerChangeTS_Plexon(strctAdvancersInformation.m_aiAdvancerUniqueID == iAdvancerUniqueID),...
    strctAdvancersInformation.m_afDepthRelativeToGridTop(strctAdvancersInformation.m_aiAdvancerUniqueID == iAdvancerUniqueID),afSampleAdvancerTimes);
[afUniqueDepthMM, aiMappingToUnique, aiCount] = fnMyUnique(afIntervalDepthMM, fMergeDistanceMM);
fnWorkerLog('Found %d unique recording depths for which stimulation was applied', length(afUniqueDepthMM));
% For each one of these locations, aggregate all stimulation trains (even
% though they can be different....)


%
strSubject = strctKofiko.g_strctAppConfig.m_strctSubject.m_strName;
strTimeDate = strctKofiko.g_strctAppConfig.m_strTimeDate;
strTimeDate(strTimeDate == ':') = '-';
strTimeDate(strTimeDate == ' ') = '_';

afRangeMS = -200:500;

for iDepthIter=1:length(afUniqueDepthMM)
    fnWorkerLog('%d Stimulation trains were applied at depth %.2f',aiCount(iDepthIter), afUniqueDepthMM(iDepthIter));
    aiTrainIndices = find(aiMappingToUnique == iDepthIter);
    afStartTS = afTrainOnsets_TS_PLX(aiTrainIndices);
    iNumTrials = length(afStartTS);
    % Sample eye movements every 1 MS (way too much..)
    % show PSTH for -500 to +500
    iZeroIndex = find(afRangeMS == 0);
    iNumSamplesPerTrial = length(afRangeMS);
    % Sample eye position!
    a2fResampleTimes = zeros(iNumTrials, iNumSamplesPerTrial);
    for k=1:iNumTrials
        a2fResampleTimes(k,:) = afStartTS(k) + afRangeMS/1e3;
    end
    % Sample X & Y
    strctX = fnReadDumpAnalogFile(strEyeXFile,'Resample',a2fResampleTimes);
    strctY= fnReadDumpAnalogFile(strEyeYFile,'Resample',a2fResampleTimes);
    % Align to time zero
    a2fX = strctX.m_afData;%-repmat(strctX.m_afData(:,iZeroIndex),1,iNumSamplesPerTrial);
    a2fY = strctY.m_afData;%-;repmat(strctY.m_afData(:,iZeroIndex),1,iNumSamplesPerTrial);
    a2fGainX = reshape(fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.GainX, 'Kofiko','Plexon',a2fResampleTimes(:), strctSync),size(a2fX));
    a2fGainY = reshape(fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.GainY, 'Kofiko','Plexon',a2fResampleTimes(:), strctSync),size(a2fY));
    a2fOffsetX= reshape(fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.CenterX , 'Kofiko','Plexon',a2fResampleTimes(:), strctSync),size(a2fX));
    a2fOffsetY = reshape(fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.CenterY, 'Kofiko','Plexon',a2fResampleTimes(:), strctSync),size(a2fY));
    a2fXpix = (a2fX+2048 - a2fOffsetX).*a2fGainX + strctKofiko.g_strctStimulusServer.m_aiScreenSize(3)/2;
    a2fYpix = (a2fY+2048 - a2fOffsetY).*a2fGainY + strctKofiko.g_strctStimulusServer.m_aiScreenSize(4)/2;

    a2fXpix_nozero = a2fXpix;
    a2fYpix_nozero = a2fYpix;
    a2fXpix = a2fXpix-repmat(a2fXpix(:,iZeroIndex),1,iNumSamplesPerTrial);
    a2fYpix= a2fYpix-repmat(a2fYpix(:,iZeroIndex),1,iNumSamplesPerTrial);
    
    strctStat.m_afTrainOnset = afStartTS;
    strctStat.m_a2fXpix = a2fXpix;
    strctStat.m_a2fYpix = a2fYpix;

    strctStat.m_a2fXpix_nozero = a2fXpix_nozero;
    strctStat.m_a2fYpix_nozero = a2fYpix_nozero;
    
    strctStat.m_fDepth = afUniqueDepthMM(iDepthIter);
    strctStimStat.m_astrctStimulation(iDepthIter) = strctStat;

end

strctStimStat.m_afRangeMS= afRangeMS;
strctStimStat.m_strDisplayFunction = 'fnDefaultElectricalStimDisplayFunc';
strctStimStat = fnAddAttribute(strctStimStat,'Subject', strSubject);
strctStimStat = fnAddAttribute(strctStimStat,'TimeDate', strctKofiko.g_strctAppConfig.m_strTimeDate);
strctStimStat = fnAddAttribute(strctStimStat,'Type','Microstim Saccade');
strctStimStat = fnAddAttribute(strctStimStat,'Channel', num2str(iChannelID));

strStatFile = [strOutputFolder, filesep, strSubject,'-',strTimeDate,'_ElectricalMicrostim_Channel',num2str(iChannelID),'.mat'];
fnWorkerLog('Saving things to %s',strStatFile);
save(strStatFile,'strctStimStat');
return;


%%

% % % function fnAnalyzeEyeMovementsDuringMicroStim()
% % % %% Micro stim stimulation that is not linked to a unit interval
% % % % search for unique trains and segment them according to recording
% % % % depth....
% % % % We will average eye movements....
% % % if 0
% % % [strctTrain, afTrainTime] = fnReadDumpAnalogFile(strTrainFile);
% % % astrctUniqueTrains = fnIdentifyStimulationTrains(strctTrain,afTrainTime,false);
% % % afTrainOnsets_TS_PLX = cat(1,astrctUniqueTrains.m_afTrainOffsetTS_Plexon);
% % % % Merge very similar trains
% % % 
% % % iChannelID = 1;
% % % iAdvancerUniqueID = strctStatServer.g_strctNeuralServer.m_a2iChannelToGridHoleAdvancer(iChannelID,3);
% % % fMergeDistanceMM = 0.2;
% % % afSampleAdvancerTimes = afTrainOnsets_TS_PLX;
% % % afIntervalDepthMM= fnMyInterp1(afAdvancerChangeTS_Plexon(aiAdvancerUniqueID == iAdvancerUniqueID), afDepthRelativeToGridTop(aiAdvancerUniqueID == iAdvancerUniqueID),afSampleAdvancerTimes);
% % % [afUniqueDepthMM, aiMappingToUnique, aiCount] = fnMyUnique(afIntervalDepthMM, fMergeDistanceMM);
% % % fprintf('Found %d unique recording depths for which stimulation was applied\n', length(afUniqueDepthMM));
% % % % For each one of these locations, aggregate all stimulation trains (even
% % % % though they can be different....)
% % % for iDepthIter=1:length(afUniqueDepthMM)
% % %     fprintf('%d Stimulation trains were applied at depth %.2f\n',aiCount(iDepthIter), afUniqueDepthMM(iDepthIter));
% % %     aiTrainIndices = find(aiMappingToUnique == iDepthIter);
% % %     afStartTS = cat(1,astrctUniqueTrains(aiTrainIndices).m_afTrainOnsetTS_Plexon);
% % %     iNumTrials = length(afStartTS);
% % %     % Sample eye movements every 1 MS (way too much..)
% % %     % show PSTH for -500 to +500
% % %     afRangeMS = 0:200;
% % %     iZeroIndex = find(afRangeMS == 0);
% % %     iNumSamplesPerTrial = length(afRangeMS);
% % %     % Sample eye position!
% % %     a2fResampleTimes = zeros(iNumTrials, iNumSamplesPerTrial);
% % %     for k=1:iNumTrials
% % %         a2fResampleTimes(k,:) = afStartTS(k) + afRangeMS/1e3;
% % %     end
% % %     % Sample X & Y
% % %     strctX = fnReadDumpAnalogFile(strEyeXFile,'Resample',a2fResampleTimes);
% % %     strctY= fnReadDumpAnalogFile(strEyeYFile,'Resample',a2fResampleTimes);
% % %     % Align to time zero
% % %     a2fX = strctX.m_afData;%-repmat(strctX.m_afData(:,iZeroIndex),1,iNumSamplesPerTrial);
% % %     a2fY = strctY.m_afData;%-;repmat(strctY.m_afData(:,iZeroIndex),1,iNumSamplesPerTrial);
% % %     a2fGainX = reshape(fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.GainX, 'Kofiko','Plexon',a2fResampleTimes(:), strctSync),size(a2fX));
% % %     a2fGainY = reshape(fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.GainY, 'Kofiko','Plexon',a2fResampleTimes(:), strctSync),size(a2fY));
% % %     a2fOffsetX= reshape(fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.CenterX , 'Kofiko','Plexon',a2fResampleTimes(:), strctSync),size(a2fX));
% % %     a2fOffsetY = reshape(fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.CenterY, 'Kofiko','Plexon',a2fResampleTimes(:), strctSync),size(a2fY));
% % %     a2fXpix = (a2fX+2048 - a2fOffsetX).*a2fGainX + strctKofiko.g_strctStimulusServer.m_aiScreenSize(3)/2;
% % %     a2fYpix = (a2fY+2048 - a2fOffsetY).*a2fGainY + strctKofiko.g_strctStimulusServer.m_aiScreenSize(4)/2;
% % % 
% % %     a2fXpix = a2fXpix-repmat(a2fXpix(:,iZeroIndex),1,iNumSamplesPerTrial);
% % %     a2fYpix= a2fYpix-repmat(a2fYpix(:,iZeroIndex),1,iNumSamplesPerTrial);
% % %     
% % %     figure(12);
% % %     clf;hold on;
% % %     for k=1:iNumTrials
% % %         plot(a2fXpix(k,:),a2fYpix(k,:),'r');
% % %         plot(a2fXpix(k,1),a2fYpix(k,1),'b+');
% % %         plot(a2fXpix(k,end),a2fYpix(k,end),'bo');
% % %     end
% % %     axis ij
% % %     box on
% % %     axis equal
% % %     xlabel('pixels');
% % %     ylabel('pixels');
% % %     legend({'Eye trace','t=0','t=+200ms'},'Location','NorthEastOutside')
% % %     figure(13);
% % %     subplot(2,1,1);
% % %     plot(a2fXpix');
% % %     xlabel('Time from stimulation (onset at t=0)');
% % %     ylabel('X coordinate');
% % %     subplot(2,1,2);
% % %     plot(a2fYpix');
% % %     xlabel('Time from stimulation (onset at t=0)');
% % %     ylabel('Y coordinate');
% % % end
% % % end
% % % %%