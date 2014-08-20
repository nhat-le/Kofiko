function fnParadigmMouseWheelCallbacksNew(strCallback,varargin)
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)

global g_strctParadigm g_strctStimulusServer  g_strctGUIParams g_strctCycle 

switch strCallback
    case 'BlockLoopingToggle'
        g_strctParadigm.m_bBlockLooping = get(g_strctParadigm.m_strctControllers.m_hLoopCurrentBlock,'value') > 0;
    case 'BlocksDoneAction'
        acOptions =get(g_strctParadigm.m_strctControllers.m_hBlocksDoneActionPopup,'String');
        iValue =get(g_strctParadigm.m_strctControllers.m_hBlocksDoneActionPopup,'value');
        g_strctParadigm.m_strBlockDoneAction = acOptions{iValue};
    case 'JumpToBlock'
        if isempty(g_strctParadigm.m_strctDesign)
            return;
        end;
        g_strctParadigm.m_iNumTimesBlockShown = 0;
        g_strctParadigm.m_iCurrentBlockIndexInOrderList = get(g_strctParadigm.m_strctControllers.m_hBlockLists,'value');
        g_strctParadigm.m_iCurrentMediaIndexInBlockList = 1;
        iSelectedBlock = g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder(g_strctParadigm.m_iCurrentOrder).m_aiBlockIndexOrder(g_strctParadigm.m_iCurrentBlockIndexInOrderList);
        iNumMediaInBlock = length(g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlocks(iSelectedBlock).m_aiMedia);
        if g_strctParadigm.m_bRandom
            [fDummy,g_strctParadigm.m_aiCurrentRandIndices] = sort(rand(1,iNumMediaInBlock));
        else
            g_strctParadigm.m_aiCurrentRandIndices = 1:iNumMediaInBlock;
        end
    
    case 'LocalStereoMode'
         iNewStereoMode = get(g_strctParadigm.m_strctControllers.m_hLocalStereoModePopup,'value');
         acStereoModes = get(g_strctParadigm.m_strctControllers.m_hLocalStereoModePopup,'String');
         g_strctParadigm.m_strLocalStereoMode = acStereoModes{iNewStereoMode};

        
    case 'JuicePanel'
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(3),'visible','on');
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(2),'visible','off');
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(1),'visible','off');
    case 'DesignPanel'
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(1),'visible','on');
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(2),'visible','off');
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(3),'visible','off');
    case 'StimulusPanel'
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(1),'visible','off');
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(2),'visible','on');
        set(g_strctParadigm.m_strctControllers.m_hSubPanels(3),'visible','off');

        
    case 'MinStimulusON_MS'
        iNewMinStimulusON_MS =  g_strctParadigm.MinStimulusON_MS.Buffer(g_strctParadigm.MinStimulusON_MS.BufferIdx);
        iMaxStimulusON_MS = g_strctParadigm.MaxStimulusON_MS.Buffer(g_strctParadigm.MaxStimulusON_MS.BufferIdx);
        if iNewMinStimulusON_MS > iMaxStimulusON_MS
            fnTsSetVarParadigm('MaxStimulusON_MS',iNewMinStimulusON_MS);
            fnUpdateSlider(g_strctParadigm.m_strctControllers.m_hMaxStimulusON_MSSlider, iNewMinStimulusON_MS);
            set(g_strctParadigm.m_strctControllers.m_hMaxStimulusON_MSEdit,'String',num2str(iNewMinStimulusON_MS));
        end
    case 'StimMode'
        g_strctParadigm.m_strctCurrentTrial =[];
    case 'MaxStimulusON_MS'
        iNewMaxStimulusON_MS =  g_strctParadigm.MaxStimulusON_MS.Buffer(g_strctParadigm.MaxStimulusON_MS.BufferIdx);
        iMinStimulusON_MS = g_strctParadigm.MinStimulusON_MS.Buffer(g_strctParadigm.MinStimulusON_MS.BufferIdx);
        if iNewMaxStimulusON_MS < iMinStimulusON_MS
            fnTsSetVarParadigm('MinStimulusON_MS',iNewMaxStimulusON_MS);
            fnUpdateSlider(g_strctParadigm.m_strctControllers.m_hMinStimulusON_MSSlider, iNewMaxStimulusON_MS);
            set(g_strctParadigm.m_strctControllers.m_hMinStimulusON_MSEdit,'String',num2str(iNewMaxStimulusON_MS));
        end
        
    case 'MinVoltageDiff'
        fNewMinVoltageDiff =  g_strctParadigm.MinVoltageDiff.Buffer(g_strctParadigm.MinVoltageDiff.BufferIdx);
        fMaxVoltageDiff = g_strctParadigm.MaxVoltageDiff.Buffer(g_strctParadigm.MaxVoltageDiff.BufferIdx);
        if fNewMinVoltageDiff > fMaxVoltageDiff
            fnTsSetVarParadigm('MaxVoltageDiff',fNewMinVoltageDiff);
            fnUpdateSlider(g_strctParadigm.m_strctControllers.m_hMaxVoltageDiffSlider, fNewMinVoltageDiff);
            set(g_strctParadigm.m_strctControllers.m_hMaxVoltageDiffEdit,'String',num2str(fNewMinVoltageDiff));
        end

    case 'MaxVoltageDiff'
        fNewMaxVoltageDiff =  g_strctParadigm.MaxVoltageDiff.Buffer(g_strctParadigm.MaxVoltageDiff.BufferIdx);
        fMinVoltageDiff = g_strctParadigm.MinVoltageDiff.Buffer(g_strctParadigm.MinVoltageDiff.BufferIdx);
        if fNewMaxVoltageDiff < fMinVoltageDiff
            fnTsSetVarParadigm('MinVoltageDiff',fNewMaxVoltageDiff);
            fnUpdateSlider(g_strctParadigm.m_strctControllers.m_hMinVoltageDiffSlider, fNewMaxVoltageDiff);
            set(g_strctParadigm.m_strctControllers.m_hMinVoltageDiffEdit,'String',num2str(fNewMaxVoltageDiff));
        end
        
    case 'RotationAngle'
        if g_strctParadigm.m_bParameterSweep
            fnInitializeParameterSweep();
        end
        
    case 'StimulusSizePix'
        if g_strctParadigm.m_bParameterSweep
            fnInitializeParameterSweep();
        end

    case 'Resuming'
        if g_strctParadigm.m_iMachineState == 6
            g_strctParadigm.m_iMachineState = 1;
        end
    case 'PhotoDiodeRectToggle'
        g_strctParadigm.m_bShowPhotodiodeRect = ~g_strctParadigm.m_bShowPhotodiodeRect;
    case 'Pausing'
    
    case 'LoadList'
        fnParadigmToKofikoComm('SafeCallback','LoadListSafe');
    case 'LoadListSafe'
        fnSafeLoadListAux();



%     case 'LFPStatToggle'
%         g_strctGUIParams.m_bShowLFPStat = ~g_strctGUIParams.m_bShowLFPStat;

    case 'Start'
        g_strctParadigm.m_iMachineState = 1;
        [fLocalTime, fServerTime, fJitter] = fnSyncClockWithStimulusServer(100);
        fnTsSetVarParadigm('SyncTime', [fLocalTime,fServerTime,fJitter]);

        g_strctParadigm.m_fLastFixatedTimer = GetSecs();
    case 'Random'
        g_strctParadigm.m_bRandom =  get(g_strctParadigm.m_strctControllers.m_hRandomImageIndex,'value');
        
        
        iSelectedBlock = g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder(g_strctParadigm.m_iCurrentOrder).m_aiBlockIndexOrder(g_strctParadigm.m_iCurrentBlockIndexInOrderList);
        iNumMediaInBlock = length(g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlocks(iSelectedBlock).m_aiMedia);
        if g_strctParadigm.m_bRandom
                    [fDummy,g_strctParadigm.m_aiCurrentRandIndices] = sort(rand(1,iNumMediaInBlock));
        else
            g_strctParadigm.m_aiCurrentRandIndices = 1:iNumMediaInBlock;
        end


    case 'JuiceTimeMS'
        iNewJuiceTimeMS =  g_strctParadigm.JuiceTimeMS.Buffer(g_strctParadigm.JuiceTimeMS.BufferIdx);


    case 'StimulusPos'
        if g_strctParadigm.m_bUpdateStimulusPos
            g_strctParadigm.m_bUpdateStimulusPos = false;
            set( g_strctParadigm.m_strctControllers.m_hStimulusPosChange,'String','New Stimulus Pos','fontweight','normal');
        else
            g_strctParadigm.m_bUpdateStimulusPos = true;
            set( g_strctParadigm.m_strctControllers.m_hStimulusPosChange,'String','Updating Stimulus Pos','fontweight','bold');
        end;
        if g_strctParadigm.m_bParameterSweep
            fnInitializeParameterSweep();
        end

    case 'BackgroundColor'
        fnParadigmToKofikoComm('JuiceOff');
        bParadigmPaused = fnParadigmToKofikoComm('IsPaused');

        if ~bParadigmPaused
            bPausing = true;
            fnPauseParadigm()
        else
            bPausing = false;
        end


        fnShowHideWind('PTB Onscreen window [10]:','hide');
        aiColor  = uisetcolor();
        fnShowHideWind('PTB Onscreen window [10]:','show');
        if length(aiColor) > 1
            fnTsSetVarParadigm('BackgroundColor',round(aiColor*255));
            %            fnDAQWrapper('StrobeWord', fnFindCode('Stimulus Position Changed'));
        end;
        if bPausing
            fnResumeParadigm();
        end
case 'BandColor'
        fnParadigmToKofikoComm('JuiceOff');
        bParadigmPaused = fnParadigmToKofikoComm('IsPaused');

        if ~bParadigmPaused
            bPausing = true;
            fnPauseParadigm()
        else
            bPausing = false;
        end


        fnShowHideWind('PTB Onscreen window [10]:','hide');
        aiColor  = uisetcolor();
        fnShowHideWind('PTB Onscreen window [10]:','show');
        if length(aiColor) > 1
            fnTsSetVarParadigm('BandColor',round(aiColor*255));
            %            fnDAQWrapper('StrobeWord', fnFindCode('Stimulus Position Changed'));
        end;
        if bPausing
            fnResumeParadigm();
        end

    case 'ResetUnit'
        g_strctParadigm.m_strWhatToReset = 'Unit';
        set(g_strctParadigm.m_strctControllers.m_hResetUnit,'value',1);
        set(g_strctParadigm.m_strctControllers.m_hResetChannel,'value',0);
        set(g_strctParadigm.m_strctControllers.m_hResetAllChannels,'value',0);
    case 'ResetChannel'
        g_strctParadigm.m_strWhatToReset = 'Channel';
        set(g_strctParadigm.m_strctControllers.m_hResetUnit,'value',0);
        set(g_strctParadigm.m_strctControllers.m_hResetChannel,'value',1);
        set(g_strctParadigm.m_strctControllers.m_hResetAllChannels,'value',0);
    case 'ResetAllChannels'
        g_strctParadigm.m_strWhatToReset = 'AllChannels';
        set(g_strctParadigm.m_strctControllers.m_hResetUnit,'value',0);
        set(g_strctParadigm.m_strctControllers.m_hResetChannel,'value',0);
        set(g_strctParadigm.m_strctControllers.m_hResetAllChannels,'value',1);
    case 'ResetStat'
        fnParadigmToKofikoComm('ResetStat',g_strctParadigm.m_strWhatToReset);
        
    case 'StartRecording'
        fnParadigmToKofikoComm('ResetStat');

        
%        set(g_strctParadigm.m_strctControllers.m_hLoadList,'enable','off');
%        set(g_strctParadigm.m_strctControllers.m_hFavroiteLists,'enable','off');
    case 'StopRecording'
%        set(g_strctParadigm.m_strctControllers.m_hLoadList,'enable','on');
%        set(g_strctParadigm.m_strctControllers.m_hFavroiteLists,'enable','on');
        [fLocalTime, fServerTime, fJitter] = fnSyncClockWithStimulusServer(100);
        fnTsSetVarParadigm('SyncTime', [fLocalTime,fServerTime,fJitter]);
    case 'LoadFavoriteList'
        fnParadigmToKofikoComm('SafeCallback','LoadFavoriteListSafe');
    case 'LoadFavoriteListSafe'
        fnParadigmToKofikoComm('JuiceOff');
        iSelectedImageList = get(g_strctParadigm.m_strctControllers.m_hFavroiteLists,'value');
        if ~fnLoadMouseWheelDesign(g_strctParadigm.m_acFavroiteLists{iSelectedImageList});
            return;
        end
                
        [fLocalTime, fServerTime, fJitter] = fnSyncClockWithStimulusServer(100);
        fnTsSetVarParadigm('SyncTime', [fLocalTime,fServerTime,fJitter]);
        fnResetStat();
        
        g_strctParadigm.m_iNumTimesBlockShown = 0;
        g_strctParadigm.m_iCurrentBlockIndexInOrderList = 1;
        g_strctParadigm.m_iCurrentMediaIndexInBlockList = 1;
        g_strctParadigm.m_iCurrentOrder = 1;
        
        g_strctParadigm.m_strctCurrentTrial = [];
        
    case 'ParameterSweep'
        g_strctParadigm.m_bParameterSweep = get(g_strctParadigm.m_strctControllers.m_hParameterSweep,'value');
        if (g_strctParadigm.m_bParameterSweep)
            
           g_strctParadigm.m_strctSavedParam.m_pt2fStimulusPosition = fnTsGetVar(g_strctParadigm,'StimulusPos');
           g_strctParadigm.m_strctSavedParam.m_fTheta = fnTsGetVar(g_strctParadigm,'RotationAngle');
           g_strctParadigm.m_strctSavedParam.m_fSize = fnTsGetVar(g_strctParadigm,'StimulusSizePix');
            
            fnInitializeParameterSweep();
            g_strctParadigm.m_iStimuliCounter = 1;
            g_strctParadigm.m_iMachineState = 1;
            
            
        else
            
            fnTsSetVarParadigm('StimulusPos',g_strctParadigm.m_strctSavedParam.m_pt2fStimulusPosition);
            fnTsSetVarParadigm('RotationAngle',g_strctParadigm.m_strctSavedParam.m_fTheta);
            fnTsSetVarParadigm('StimulusSizePix',g_strctParadigm.m_strctSavedParam.m_fSize);
            
        end

    case 'MotionStarted'
        g_strctParadigm.m_iMachineState = 0;
        fnParadigmToStimulusServer('PauseButRecvCommands');
        g_strctParadigm.m_bPausedDueToMotion = true;
    case 'MotionFinished'
        if ~fnParadigmToKofikoComm('IsPaused')
             g_strctParadigm.m_strctCurrentTrial = fnMouseWheelPrepareTrial();
            g_strctParadigm.m_iMachineState = 1;
        end
        g_strctParadigm.m_bPausedDueToMotion = false;
    case 'ParameterSweepMode'
        g_strctParadigm.m_iParameterSweepMode = get(g_strctParadigm.m_strctControllers.m_hParameterSweepPopup,'value');
        fnInitializeParameterSweep();
    case 'UpdateListFiringRate'
        [Dummy, acShortFileNames] = fnCellToCharShort(g_strctParadigm.m_acImageFileNames);
        
%         for k=1:length(acShortFileNames)
%             acShortFileNames{k} = sprintf('%.2f %s',...
%                 g_strctCycle.m_a2fAvgStimulusResponse(g_strctGUIParams.m_iSelectedChannelPSTH,k),acShortFileNames{k});
%         end
%          
%         set(g_strctParadigm.m_strctControllers.m_hImageList,'String',acShortFileNames);


    case 'PlayStimuliLocally'
        g_strctParadigm.m_bDisplayStimuliLocally = ~g_strctParadigm.m_bDisplayStimuliLocally;
    case 'ShowWhileLoading'
        g_strctParadigm.m_bShowWhileLoading = ~g_strctParadigm.m_bShowWhileLoading;
    case 'DrawAttentionEvent'
        g_strctParadigm.m_iMachineState = 1;

    otherwise
        fnParadigmToKofikoComm('DisplayMessage', [strCallback,' not handeled']);
         
end;

return;

function fnSafeLoadListAux()
global g_strctParadigm
fnParadigmToKofikoComm('JuiceOff');
fnParadigmToStimulusServer('PauseButRecvCommands');
fnHidePTB();
[strFile, strPath] = uigetfile([g_strctParadigm.m_strInitial_DefaultImageFolder,'*.txt;*.xml']);

fnShowPTB()
if strFile(1) ~= 0
    g_strctParadigm.m_strNextImageList = [strPath,strFile];
    
    if ~fnLoadMouseWheelDesign(g_strctParadigm.m_strNextImageList);
        return;
    end;
    
    [fLocalTime, fServerTime, fJitter] = fnSyncClockWithStimulusServer(100);
    fnTsSetVarParadigm('SyncTime', [fLocalTime,fServerTime,fJitter]);

    % If not available in the favorite list, add it!
    iIndex = -1;
    for k=1:length(g_strctParadigm.m_acFavroiteLists)
        if strcmpi(g_strctParadigm.m_acFavroiteLists{k}, g_strctParadigm.m_strNextImageList)
            iIndex = k;
            break;
        end
    end


    if iIndex == -1
        % Not found, add!
        g_strctParadigm.m_acFavroiteLists = [g_strctParadigm.m_strNextImageList,g_strctParadigm.m_acFavroiteLists];
        set(g_strctParadigm.m_strctControllers.m_hFavroiteLists,'String',fnCellToCharShort(g_strctParadigm.m_acFavroiteLists),'value',1);
    else
        set(g_strctParadigm.m_strctControllers.m_hFavroiteLists,'value',iIndex);
    end
    
      

end;