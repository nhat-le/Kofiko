function strctTrial = fnMouseWheelPrepareTrial()

%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)
global g_strctParadigm  g_strctDAQParams
g_strctParadigm.m_bMovieInitialized  = false;

if isempty(g_strctParadigm.m_strctDesign)
    strctTrial = [];
    return;
end;

iLargeBuffer = 50000;


strctTrial.m_fStimulusSizePix = g_strctParadigm.StimulusSizePix.Buffer(1,:,g_strctParadigm.StimulusSizePix.BufferIdx);
aiScreenSize = fnParadigmToKofikoComm('GetStimulusServerScreenSize');

%read next voltage
fWheelVoltage= fnDAQ('GetAnalog', g_strctDAQParams.m_fConveyerPort);
fnTsSetVarParadigm('WheelVoltage',fWheelVoltage);

strctTrial.m_fWheelVoltage = g_strctParadigm.WheelVoltage.Buffer(1,:,g_strctParadigm.WheelVoltage.BufferIdx);
if isempty(g_strctParadigm.m_strctCurrentTrial)   %%%%%
    if g_strctParadigm.m_bParameterSweep
        [iNewStimulusIndex,iSelectedBlock] =  fnSelectNextStimulusUsingParameterSweep();
    else
        [iNewStimulusIndex,iSelectedBlock] = fnSelectNextStimulus();
        %g_strctParadigm.m_iTotalStim = g_strctParadigm.m_iTotalStim +1;
    end
    StimMode = g_strctParadigm.StimMode.Buffer(1,:,g_strctParadigm.StimMode.BufferIdx);
    
    
    % Faster access than fnTsGetVar...
    strctTrial.m_fVoltageDiff = strctTrial.m_fWheelVoltage;
    fnTsSetVarParadigm('VoltageDiff',strctTrial.m_fVoltageDiff);
      
    strctTrial.m_iStimulusIndex = iNewStimulusIndex;
    g_strctParadigm = fnTsAddVar(g_strctParadigm, 'StimulusIndex',strctTrial.m_iStimulusIndex, iLargeBuffer);
    %fnTsSetVarParadigm('StimulusIndex',iNewStimulusIndex);
    
    strctTrial.m_bGivenJuice = false;
    fnTsSetVarParadigm('GivenJuice',strctTrial.m_bGivenJuice);
    
    % sound only plays once per trial
    fnTsSetVarParadigm('SoundPerTrial', 0);
     
    switch StimMode
        case 1
            strctTrial.m_pt2fStimulusPos = [-strctTrial.m_fStimulusSizePix, aiScreenSize(4)/2];
        case 2
            strctTrial.m_pt2fStimulusPos = [strctTrial.m_fStimulusSizePix + aiScreenSize(3), aiScreenSize(4)/2];

        case 3
            strctTrial.m_pt2fStimulusPos = [aiScreenSize(3)/2, -strctTrial.m_fStimulusSizePix];
        case 4
            strctTrial.m_pt2fStimulusPos = [aiScreenSize(3)/2, strctTrial.m_fStimulusSizePix + aiScreenSize(4)];            
    end
     fnTsSetVarParadigm('StimulusPos',strctTrial.m_pt2fStimulusPos);

else

    p2fLastStimulusPos = g_strctParadigm.StimulusPos.Buffer(1,:,g_strctParadigm.StimulusPos.BufferIdx);   
    fLastWheelVoltage = g_strctParadigm.WheelVoltage.Buffer(1,:,g_strctParadigm.WheelVoltage.BufferIdx-1);
    fLastWheelSpeed = g_strctParadigm.Speed.Buffer(1,:,g_strctParadigm.Speed.BufferIdx);
    StopTime = g_strctParadigm.StopTime.Buffer(1,:,g_strctParadigm.StopTime.BufferIdx);
    StimMode = g_strctParadigm.StimMode.Buffer(1,:,g_strctParadigm.StimMode.BufferIdx);
    
    iMoveStepPix = g_strctParadigm.MoveStepPix.Buffer(1,:,g_strctParadigm.MoveStepPix.BufferIdx);
    g_strctDAQParams.m_fVoltageToPixelMap = iMoveStepPix; % Need measurement
    if StimMode < 3
        constant = 2;
        movable = 1;
    else
        constant = 1;
        movable = 2;
    end
    
    if mod(StimMode,2) == 0;
        increase = -1;
    else
        increase = 1;
    end
    p2fNewStimulusPos(constant) = p2fLastStimulusPos(constant);
    % JCL 9/20/13 prevent pic from moving backwards
    % Added threshold of 50
    %     if strctTrial.m_fWheelVoltage > fLastWheelVoltage + 200
    %         p2fNewStimulusPos(1) = p2fLastStimulusPos(1)+ iMoveStepPix;
    %         % reward movement for training JCL 9/24/13
    %         %end
    %         %    elseif strctTrial.m_fWheelVoltage < fLastWheelVoltage - 100
    %         %        p2fNewStimulusPos(1) = p2fLastStimulusPos(1)- iMoveStepPix;
    %     else
    %         % mark down stops
    %         p2fNewStimulusPos(1) = p2fLastStimulusPos(1);
    %     end
    %p2fNewStimulusPos(movable) = p2fLastStimulusPos(movable)+increase*round((strctTrial.m_fWheelVoltage - fLastWheelVoltage)/1e2*g_strctDAQParams.m_fVoltageToPixelMap);
    strctTrial.m_fVoltageDiff = strctTrial.m_fWheelVoltage - fLastWheelVoltage;
%     if strctTrial.m_fVoltageDiff < -2e4 
%         speed = g_strctDAQParams.m_fVoltageToPixelMap;
%         StopTime = 0;
%     else
%         speed = fLastWheelSpeed - 0.5;
%         StopTime = StopTime + GetSecs - g_strctParadigm.VoltageDiff.TimeStamp(g_strctParadigm.WheelVoltage.BufferIdx-1);
% 
%     end
%     if speed < 0; 
%         speed = 0; 
%     end;
    if abs(strctTrial.m_fVoltageDiff) > 1e4 % Abrupt Change means nothing!
        speed = 0;
    else
        % stimulus cannot move backwards if it's out of the box
        % to prevent kofiko from re-choosing new stimulus
        if p2fLastStimulusPos(movable)<strctTrial.m_fStimulusSizePix || p2fLastStimulusPos(movable)>aiScreenSize(movable+2)-strctTrial.m_fStimulusSizePix
            speed = min(0, strctTrial.m_fVoltageDiff/iMoveStepPix);
        else
            speed = strctTrial.m_fVoltageDiff/iMoveStepPix; %with backward
        end
    end
    
    SpeedThreshold = 5;
    if abs(speed) < SpeedThreshold;
        StopTime = StopTime + GetSecs - g_strctParadigm.VoltageDiff.TimeStamp(g_strctParadigm.WheelVoltage.BufferIdx-1);
    else
        StopTime = 0;
    end
    

    p2fNewStimulusPos(movable) = p2fLastStimulusPos(movable)+increase*round(speed);
        p2fNewStimulusPos(constant) = p2fLastStimulusPos(constant); %+ 10*sin((Getsecs-fTrialStart)*pi/0.5);
    fnTsSetVarParadigm('StopTime', StopTime);
    fnTsSetVarParadigm('Speed', speed);
    fnTsSetVarParadigm('VoltageDiff',strctTrial.m_fVoltageDiff);
    
    if p2fNewStimulusPos(movable)<-strctTrial.m_fStimulusSizePix || p2fNewStimulusPos(movable)>aiScreenSize(movable+2)+strctTrial.m_fStimulusSizePix
        if g_strctParadigm.m_bParameterSweep
            [iNewStimulusIndex,iSelectedBlock] =  fnSelectNextStimulusUsingParameterSweep();
        else
            [iNewStimulusIndex,iSelectedBlock] = fnSelectNextStimulus();
        end
        
        % Faster access than fnTsGetVar...
        strctTrial.m_iStimulusIndex = iNewStimulusIndex;
        fnTsSetVarParadigm('StimulusIndex',iNewStimulusIndex);
        strctTrial.m_bGivenJuice = false;
        fnTsSetVarParadigm('GivenJuice',strctTrial.m_bGivenJuice);
        
        if p2fNewStimulusPos(1)<-strctTrial.m_fStimulusSizePix
            p2fNewStimulusPos(1) = aiScreenSize(3)+strctTrial.m_fStimulusSizePix;
        elseif p2fNewStimulusPos(1)> aiScreenSize(3)+strctTrial.m_fStimulusSizePix
            p2fNewStimulusPos(1) = -strctTrial.m_fStimulusSizePix;
        end
    else
        strctTrial.m_iStimulusIndex = g_strctParadigm.StimulusIndex.Buffer(1,:,g_strctParadigm.StimulusIndex.BufferIdx);
        strctTrial.m_bGivenJuice = g_strctParadigm.GivenJuice.Buffer(1,:,g_strctParadigm.GivenJuice.BufferIdx);
    end
    
    fnTsSetVarParadigm('StimulusPos',p2fNewStimulusPos);
    strctTrial.m_pt2fStimulusPos = p2fNewStimulusPos;
    % JCL 9/20/2013 3x the flips per comparison
    %     if strctTrial.m_fWheelVoltage > fLastWheelVoltage + 500
    %         for i = 1:3
    %             p2fNewStimulusPos = [p2fNewStimulusPos(1) + iMoveStepPix, p2fNewStimulusPos(2)];
    %             fnTsSetVarParadigm('StimulusPos',p2fNewStimulusPos);
    %             strctTrial.m_pt2fStimulusPos = p2fNewStimulusPos;
    %         end
    %     end
    %
    
end

strctTrial.m_strctMedia = g_strctParadigm.m_strctDesign.m_astrctMedia(strctTrial.m_iStimulusIndex);

fMaxVoltageDiff =  g_strctParadigm.MaxVoltageDiff.Buffer(g_strctParadigm.MaxVoltageDiff.BufferIdx);
fMinVoltageDiff =  g_strctParadigm.MinVoltageDiff.Buffer(g_strctParadigm.MinVoltageDiff.BufferIdx);
iMaxStimulusON_MS =  g_strctParadigm.MaxStimulusON_MS.Buffer(g_strctParadigm.MaxStimulusON_MS.BufferIdx);
iMinStimulusON_MS =  g_strctParadigm.MinStimulusON_MS.Buffer(g_strctParadigm.MinStimulusON_MS.BufferIdx);
if abs(strctTrial.m_fVoltageDiff) >= fMaxVoltageDiff
    strctTrial.m_fStimulusON_MS = iMinStimulusON_MS;
elseif abs(strctTrial.m_fVoltageDiff) <= fMinVoltageDiff
    strctTrial.m_fStimulusON_MS = iMaxStimulusON_MS;
else
    strctTrial.m_fStimulusON_MS = ...
        iMinStimulusON_MS+(iMaxStimulusON_MS-iMinStimulusON_MS+1)...
        *(abs(strctTrial.m_fVoltageDiff)-fMinVoltageDiff)/(fMaxVoltageDiff-fMinVoltageDiff+1);
end
strctTrial.m_fStimulusOFF_MS = 0;

strctTrial.m_iNoiseIndex = 0;
strctTrial.m_bNoiseOverlay = false;
strctTrial.m_a2fNoisePattern =  [];



strctTrial.m_afBackgroundColor = squeeze(g_strctParadigm.BackgroundColor.Buffer(1,:,g_strctParadigm.BackgroundColor.BufferIdx));
strctTrial.m_afCorrectBoxColor = squeeze(g_strctParadigm.CorrectBoxColor.Buffer(1,:,g_strctParadigm.CorrectBoxColor.BufferIdx));
strctTrial.m_afBandColor = squeeze(g_strctParadigm.BandColor.Buffer(1,:,g_strctParadigm.BandColor.BufferIdx));
strctTrial.m_afBandCenter = g_strctParadigm.BandCenter.Buffer(1,:,g_strctParadigm.BandCenter.BufferIdx);
strctTrial.m_afBandWidth = g_strctParadigm.BandWidth.Buffer(1,:,g_strctParadigm.BandWidth.BufferIdx);
strctTrial.m_afStimMode = StimMode;
strctTrial.m_afPosRange = g_strctParadigm.TargetPosRange.Buffer(1,:,g_strctParadigm.TargetPosRange.BufferIdx);
% strctTrial.m_afSoundFreq = g_strctParadigm.SoundFreq.Buffer(1,:,g_strctParadigm.SoundFreq.BufferIdx);
% strctTrial.m_afSoundData = g_strctParadigm.SoundData.Buffer(1,:,g_strctParadigm.SoundData.BufferIdx);
% strctTrial.m_afSoundHandle = g_strctParadigm.SoundHandle.Buffer(1,:,g_strctParadigm.SoundOn.BufferIdx);

strctTrial.m_afBoxHeight = g_strctParadigm.BoxHeight.Buffer(1,:,g_strctParadigm.BoxHeight.BufferIdx);


strctTrial.m_fRotationAngle = g_strctParadigm.RotationAngle.Buffer(1,:,g_strctParadigm.RotationAngle.BufferIdx);
strctTrial.m_bShowPhotodiodeRect = g_strctParadigm.m_bShowPhotodiodeRect;
strctTrial.m_iPhotoDiodeWindowPix = g_strctParadigm.m_iPhotoDiodeWindowPix;



return;


function [iNewStimulusIndex,iSelectedBlock]=  fnSelectNextStimulusUsingParameterSweep()
global g_strctParadigm
aiScreenSize = fnParadigmToKofikoComm('GetStimulusServerScreenSize');
iSelectedBlock = [];

iNewStimulusIndex = g_strctParadigm.m_a2fParamSpace(g_strctParadigm.m_strctParamSweep.m_iParamSweepIndex,1);
fX = g_strctParadigm.m_a2fParamSpace(g_strctParadigm.m_strctParamSweep.m_iParamSweepIndex,2);
fY = g_strctParadigm.m_a2fParamSpace(g_strctParadigm.m_strctParamSweep.m_iParamSweepIndex,3);
fSize = g_strctParadigm.m_a2fParamSpace(g_strctParadigm.m_strctParamSweep.m_iParamSweepIndex,4);
fTheta = g_strctParadigm.m_a2fParamSpace(g_strctParadigm.m_strctParamSweep.m_iParamSweepIndex,5);

pt2fStimulusPosition = aiScreenSize(3:4)/2 + [fX,fY];

fnTsSetVarParadigm('StimulusPos',pt2fStimulusPosition);
fnTsSetVarParadigm('RotationAngle',fTheta);
fnTsSetVarParadigm('StimulusSizePix',fSize);

g_strctParadigm.m_strctParamSweep.m_iParamSweepIndex = g_strctParadigm.m_strctParamSweep.m_iParamSweepIndex + 1;
if g_strctParadigm.m_strctParamSweep.m_iParamSweepIndex > size(g_strctParadigm.m_a2fParamSpace,1)
    fnInitializeParameterSweep();
    g_strctParadigm.m_iRepeatitionCount = g_strctParadigm.m_iRepeatitionCount + 1;
end
return;


function [iNewStimulusIndex,iSelectedBlock] = fnSelectNextStimulus()
global g_strctParadigm
iSelectedBlock = g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder(g_strctParadigm.m_iCurrentOrder).m_aiBlockIndexOrder(g_strctParadigm.m_iCurrentBlockIndexInOrderList);
iNumMediaInBlock = length(g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlocks(iSelectedBlock).m_aiMedia);
iNewStimulusIndex =g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlocks(iSelectedBlock).m_aiMedia( g_strctParadigm.m_aiCurrentRandIndices(g_strctParadigm.m_iCurrentMediaIndexInBlockList));


% Increase counters
g_strctParadigm.m_iCurrentMediaIndexInBlockList = g_strctParadigm.m_iCurrentMediaIndexInBlockList + 1;
if g_strctParadigm.m_iCurrentMediaIndexInBlockList  > iNumMediaInBlock
    % Yey! We finished displaying a block!
    % Reset and increase counters accordingly!
    g_strctParadigm.m_iCurrentMediaIndexInBlockList = 1;
    % Generate a new random indices for the media in this block!
    if g_strctParadigm.m_bRandom
        [fDummy,g_strctParadigm.m_aiCurrentRandIndices] = sort(rand(1,iNumMediaInBlock));
    else
        g_strctParadigm.m_aiCurrentRandIndices = 1:iNumMediaInBlock;
    end
    
    g_strctParadigm.m_iNumTimesBlockShown = g_strctParadigm.m_iNumTimesBlockShown + 1;
    
    % How many times do we need to display this block ?
    iNumTimesToShowBlock = g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder(g_strctParadigm.m_iCurrentOrder).m_aiBlockRepitition(g_strctParadigm.m_iCurrentBlockIndexInOrderList);
    iNumBlockOrder = length(g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder(g_strctParadigm.m_iCurrentOrder).m_aiBlockRepitition);
    iNumOrders = length(g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder);
    
    if g_strctParadigm.m_iNumTimesBlockShown >= iNumTimesToShowBlock && ~g_strctParadigm.m_bBlockLooping
        % Time to move on to next block.
        g_strctParadigm.m_iNumTimesBlockShown = 0;
        g_strctParadigm.m_iCurrentBlockIndexInOrderList = g_strctParadigm.m_iCurrentBlockIndexInOrderList + 1;
        if g_strctParadigm.m_iCurrentBlockIndexInOrderList > iNumBlockOrder
            % We finished displaying everything according to the desired order. What's next?
            % 1. Reset and Stop
            % 2. Stop but increase current order (fMRI Style?)
            % 3. Continue, by starting all over again using the same order
            % 4. Continue, by starting all over again using the next order
            switch g_strctParadigm.m_strBlockDoneAction
                case 'Reset And Stop'
                    g_strctParadigm.m_iCurrentBlockIndexInOrderList = 1;
                    g_strctParadigm.m_iCurrentMediaIndexInBlockList = 1;
                    g_strctParadigm.m_iMachineState = 0;
                case 'Set Next Order But Do not Start'
                    g_strctParadigm.m_iCurrentBlockIndexInOrderList = 1;
                    g_strctParadigm.m_iCurrentMediaIndexInBlockList = 1;
                    g_strctParadigm.m_iMachineState = 0;
                    g_strctParadigm.m_iCurrentOrder = g_strctParadigm.m_iCurrentOrder + 1;
                    if g_strctParadigm.m_iCurrentOrder > iNumOrders
                        g_strctParadigm.m_iCurrentOrder = 1;
                    end
                case 'Repeat Same Order'
                    g_strctParadigm.m_iCurrentBlockIndexInOrderList = 1;
                    g_strctParadigm.m_iCurrentMediaIndexInBlockList = 1;
                case 'Set Next Order and Start'
                    g_strctParadigm.m_iCurrentBlockIndexInOrderList = 1;
                    g_strctParadigm.m_iCurrentMediaIndexInBlockList = 1;
                    g_strctParadigm.m_iCurrentOrder = g_strctParadigm.m_iCurrentOrder + 1;
                    if g_strctParadigm.m_iCurrentOrder > iNumOrders
                        g_strctParadigm.m_iCurrentOrder = 1;
                    end
                otherwise
                    assert(false);
            end
        end
        
        set(g_strctParadigm.m_strctControllers.m_hBlockLists,'value',g_strctParadigm.m_iCurrentBlockIndexInOrderList);
        
        iSelectedBlockNext = g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder(g_strctParadigm.m_iCurrentOrder).m_aiBlockIndexOrder(g_strctParadigm.m_iCurrentBlockIndexInOrderList);
        iNumMediaInBlock = length(g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlocks(iSelectedBlockNext).m_aiMedia);
        if g_strctParadigm.m_bRandom
            [fDummy,g_strctParadwigm.m_aiCurrentRandIndices] = sort(rand(1,iNumMediaInBlock));
        else
            g_strctParadigm.m_aiCurrentRandIndices = 1:iNumMediaInBlock;
        end
        
    end
    
end
