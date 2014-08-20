function bSuccessful = fnParadigmMouseWheelInitNew()
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)

global g_strctParadigm g_strctStimulusServer
g_strctParadigm.m_fStartTime = GetSecs;

% Default initializations...
g_strctParadigm.m_iMachineState = 0; % Always initialize first state to zero.
g_strctParadigm.m_iSoundState = 0; %Sound state 0 = silent; 1 = play sound

if fnParadigmToKofikoComm('IsTouchMode')
    bSuccessful = false;
    return;
end
% BLOCK DONE ACTION
g_strctParadigm.m_strBlockDoneAction = 'Repeat Same Order';
g_strctParadigm.m_iNumTimesBlockShown = 0;
g_strctParadigm.m_iCurrentBlockIndexInOrderList = 1;
g_strctParadigm.m_iCurrentMediaIndexInBlockList = 1;
g_strctParadigm.m_iCurrentOrder = 1;
g_strctParadigm.m_bBlockLooping = false;
%g_strctParadigm.m_iCorrectStim = 0;
%g_strctParadigm.m_iTotalStim = 0;

%g_strctParadigm.m_bDoNotDrawThisCycle = false;

% Finite State Machine related parameters
g_strctParadigm.m_bRandom = g_strctParadigm.m_fInitial_RandomStimuli; 

g_strctParadigm.m_bRepeatNonFixatedImages = true;

iSmallBuffer = 500;
iLargeBuffer = 50000;

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'JuiceTimeMS', g_strctParadigm.m_fInitial_JuiceTimeMS, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'WaitTime', g_strctParadigm.m_fInitial_WaitTime, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'Speed', 0, iLargeBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'StopTime', 0, iLargeBuffer);

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'CorrectStop', 0, iLargeBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'IncorrectStop', 0, iLargeBuffer);

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'TargetPosRange', g_strctParadigm.m_fInitial_TargetPosRange, iSmallBuffer);

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'BoxHeight', g_strctParadigm.m_fInitial_BoxHeight, iSmallBuffer);

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'SoundPerTrial', 0, iSmallBuffer);

%Create the sound file
% Fs1 = 44100;
% t=[0:1/Fs1:(1-1/Fs1)*0.1];
% freq = 400;%Hz
% f1 = sin(2*pi*freq*t)*0.3;

% InitializePsychSound;                
% Channels = size(f1,1);
% try
%     Handle = PsychPortAudio('Open', [], [], 0, Fs1, Channels);
% catch exception
%     msgString = getReport(exception);
%     disp(msgString);
% end
% PsychPortAudio('FillBuffer', Handle, f1);


% g_strctParadigm = fnTsAddVar(g_strctParadigm, 'SoundFreq', Fs1, iSmallBuffer);
% g_strctParadigm = fnTsAddVar(g_strctParadigm, 'SoundData', f1, iSmallBuffer);
% g_strctParadigm = fnTsAddVar(g_strctParadigm, 'SoundHandle', Handle, iSmallBuffer);








g_strctParadigm = fnTsAddVar(g_strctParadigm, 'SyncTime',[0,0,0],iLargeBuffer);

% Stimulus related parameters. These will be sent to the stimulus server,
% so make sure all required stimulus parameters (that can change) are
% represented in this structure.

g_strctParadigm.m_iPhotoDiodeWindowPix = 30; % Very important if you want to get a signal from the photodiode to plexon


g_strctParadigm = fnTsAddVar(g_strctParadigm, 'BackgroundColor',  g_strctParadigm.m_afInitial_BackgroundColor, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'CorrectBoxColor',  g_strctParadigm.m_afInitial_CorrectBoxColor, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'BandColor',  g_strctParadigm.m_afInitial_BandColor, iSmallBuffer);
%Initial_Mode
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'StimMode',  g_strctParadigm.m_fInitial_Mode, iSmallBuffer);

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'CurrStimulusIndex', 0, iLargeBuffer);

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'StimulusSizePix', g_strctParadigm.m_fInitial_StimulusSizePix, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'StimulusPos', [-g_strctParadigm.m_fInitial_StimulusSizePix g_strctStimulusServer.m_aiScreenSize(4)/2], iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'RotationAngle', 0, iLargeBuffer);

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'WheelVoltage', g_strctParadigm.m_fInitial_WheelVoltage, iLargeBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'GivenJuice',false, iLargeBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'VoltageDiff',g_strctParadigm.m_fInitial_WheelVoltage, iLargeBuffer);

g_strctParadigm.m_strctSavedParam.m_pt2fStimulusPosition = fnTsGetVar(g_strctParadigm,'StimulusPos');
g_strctParadigm.m_strctSavedParam.m_fTheta = fnTsGetVar(g_strctParadigm,'RotationAngle');
g_strctParadigm.m_strctSavedParam.m_fSize = fnTsGetVar(g_strctParadigm,'StimulusSizePix');

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'Trials',[0;0;0;0;0;0;0;0],iLargeBuffer);


g_strctParadigm.m_strctCurrentTrial = [];
g_strctParadigm.m_bShowPhotodiodeRect = g_strctParadigm.m_fInitial_ShowPhotodiodeRect;

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'ImageList', '',20);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'Designs', {},20);

g_strctParadigm = fnTsAddVar(g_strctParadigm, 'MaxVoltageDiff', g_strctParadigm.m_fInitial_MaxVoltageDiff, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'MinVoltageDiff', g_strctParadigm.m_fInitial_MinVoltageDiff, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'MaxStimulusON_MS', g_strctParadigm.m_fInitial_MaxStimulusON_MS, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'MinStimulusON_MS', g_strctParadigm.m_fInitial_MinStimulusON_MS, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'MoveStepPix', g_strctParadigm.m_fInitial_MoveStepPix, iSmallBuffer);
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'BandWidth', g_strctParadigm.m_fInitial_BandWidth, iSmallBuffer);
%Initial_BandCenter
g_strctParadigm = fnTsAddVar(g_strctParadigm, 'BandCenter', g_strctParadigm.m_fInitial_BandCenter, iSmallBuffer);


g_strctParadigm.m_iNumStimuli = 0;
g_strctParadigm.m_bStimulusDisplayed = false;
g_strctParadigm.m_aiCurrentRandIndices = [];

g_strctParadigm.m_strSavedImageList = '';
%g_strctParadigm.m_fInsideGazeRectTimer = 0; 
%g_strctParadigm.m_bUpdateFixationSpot = false;
g_strctParadigm.m_bUpdateStimulusPos = false;

g_strctParadigm.m_strLocalStereoMode = 'Side by Side (Large)';
    
g_strctParadigm.m_strState = 'Doing Nothing;';

g_strctParadigm.m_strImageList = '';
% g_strctParadigm.m_strOnlyFacesImageList = g_strctParadigm.m_strInitial_FacesImageList;
% g_strctParadigm.m_strFOBImageList = g_strctParadigm.m_strInitial_FOBImageList;

g_strctParadigm.m_bDisplayStimuliLocally = true;
g_strctParadigm.m_bMovieInitialized = false;

g_strctParadigm.m_fLastFixatedTimer = 0; 

g_strctParadigm.m_a2bStimulusCategory = [];
g_strctParadigm.m_acCatNames = [];

g_strctParadigm.m_bPausedDueToMotion = false;


acFieldNames = fieldnames(g_strctParadigm);
acFavroiteLists = cell(1,0);
iListCounter = 1;
for k=1:length(acFieldNames)
    if strncmpi(acFieldNames{k},'m_strInitial_FavroiteList',25)
        strImageListFileName = getfield(g_strctParadigm,acFieldNames{k});
        if exist(strImageListFileName,'file')
           acFavroiteLists{iListCounter} = strImageListFileName;
           iListCounter = iListCounter + 1;
        end
    end
end
g_strctParadigm.m_bParameterSweep = g_strctParadigm.m_fInitial_ParameterSweep;
g_strctParadigm.m_iParameterSweepMode = 1;

g_strctParadigm.m_astrctParameterSweepModes(1).m_strName = 'Fixed';
g_strctParadigm.m_astrctParameterSweepModes(1).m_afX  = 0;
g_strctParadigm.m_astrctParameterSweepModes(1).m_afY  = 0;
g_strctParadigm.m_astrctParameterSweepModes(1).m_afSize  = [];
g_strctParadigm.m_astrctParameterSweepModes(1).m_afTheta  = [];

g_strctParadigm.m_astrctParameterSweepModes(2).m_strName = '7x7 Position Only';
g_strctParadigm.m_astrctParameterSweepModes(2).m_afX  = [-300:100:300];
g_strctParadigm.m_astrctParameterSweepModes(2).m_afY  = [-300:100:300];
g_strctParadigm.m_astrctParameterSweepModes(2).m_afSize  = [];
g_strctParadigm.m_astrctParameterSweepModes(2).m_afTheta  = [];

g_strctParadigm.m_astrctParameterSweepModes(3).m_strName = '7x7x3 Position & Scale';
g_strctParadigm.m_astrctParameterSweepModes(3).m_afX  = [-300:100:300];
g_strctParadigm.m_astrctParameterSweepModes(3).m_afY  = [-300:100:300];
g_strctParadigm.m_astrctParameterSweepModes(3).m_afSize  = [32 64 128];
g_strctParadigm.m_astrctParameterSweepModes(3).m_afTheta  = [];

g_strctParadigm.m_astrctParameterSweepModes(4).m_strName = '21x21 Position Only';
g_strctParadigm.m_astrctParameterSweepModes(4).m_afX  = -400:40:400;
g_strctParadigm.m_astrctParameterSweepModes(4).m_afY  = -300:30:300;
g_strctParadigm.m_astrctParameterSweepModes(4).m_afSize  = [];
g_strctParadigm.m_astrctParameterSweepModes(4).m_afTheta  = [];

g_strctParadigm.m_astrctParameterSweepModes(5).m_strName = '21x21x3 Position Only';
g_strctParadigm.m_astrctParameterSweepModes(5).m_afX  = -400:40:400;
g_strctParadigm.m_astrctParameterSweepModes(5).m_afY  = -300:30:300;
g_strctParadigm.m_astrctParameterSweepModes(5).m_afSize  = [32 64 128];
g_strctParadigm.m_astrctParameterSweepModes(5).m_afTheta  = [];

g_strctParadigm.m_acImageFileNames = [];


g_strctParadigm.m_strctMiroSctim.m_bActive = false;


TRIAL_START_CODE = 32700;
TRIAL_END_CODE = 32699;
TRIAL_ALIGN_CODE = 32698;
TRIAL_OUTCOME_MISS = 32695;
TRIAL_INCORRECT_FIX = 32696;
TRIAL_CORRECT_FIX = 32697;

strctDesign.TrialStartCode = TRIAL_START_CODE;
strctDesign.TrialEndCode = TRIAL_END_CODE;
strctDesign.TrialAlignCode = TRIAL_ALIGN_CODE;
strctDesign.TrialOutcomesCodes = [TRIAL_OUTCOME_MISS,TRIAL_INCORRECT_FIX,TRIAL_CORRECT_FIX];
strctDesign.KeepTrialOutcomeCodes = [TRIAL_CORRECT_FIX];
strctDesign.TrialTypeToConditionMatrix = [];
strctDesign.ConditionOutcomeFilter = cell(0);
strctDesign.NumTrialsInCircularBuffer = 200;
strctDesign.Pre_TimeSec = 0.5;
strctDesign.Post_TimeSec = 0.5;
g_strctParadigm.m_strctStatServerDesign = strctDesign;
g_strctParadigm.m_bJustLoaded = true;

iInitialIndex = -1;
if ~isempty(g_strctParadigm.m_strInitial_DefaultImageList) && exist(g_strctParadigm.m_strInitial_DefaultImageList,'file')
   if fnLoadMouseWheelDesign(g_strctParadigm.m_strInitial_DefaultImageList)
    
    for k=1:length(acFavroiteLists)
        if strcmpi(acFavroiteLists{k}, g_strctParadigm.m_strInitial_DefaultImageList)
            iInitialIndex = k;
            break;
        end
    end
    if iInitialIndex == -1
        acFavroiteLists = [g_strctParadigm.m_strInitial_DefaultImageList,acFavroiteLists];
        iInitialIndex = 1;
    end
   end
else
    g_strctParadigm.m_strctDesign = [];
end;
g_strctParadigm.m_strWhatToReset = 'Unit';

g_strctParadigm.m_acFavroiteLists = acFavroiteLists;
g_strctParadigm.m_iInitialIndexInFavroiteList = iInitialIndex;
g_strctParadigm.m_bShowWhileLoading = true;





bSuccessful = true;
return;


 
