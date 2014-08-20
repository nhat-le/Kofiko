function fnParadigmMouseWheelDrawCycleNew2(acInputFromKofiko)
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)

global g_strctPTB g_strctDraw g_strctServerCycle 

if ~isempty(acInputFromKofiko)
    strCommand = acInputFromKofiko{1};
    switch strCommand
        case 'ClearMemory'
            fnStimulusServerClearTextureMemory();
        case 'PauseButRecvCommands'
            if g_strctPTB.m_bInStereoMode
                Screen('SelectStereoDrawBuffer', g_strctPTB.m_hWindow,0); % Left Eye
                Screen(g_strctPTB.m_hWindow,'FillRect',0);
                Screen('SelectStereoDrawBuffer', g_strctPTB.m_hWindow,1); % Right Eye
                Screen(g_strctPTB.m_hWindow,'FillRect',0);
            else
                Screen(g_strctPTB.m_hWindow,'FillRect',0);
            end
            Screen(g_strctPTB.m_hWindow,'Flip');
            g_strctServerCycle.m_iMachineState = 0;
        case 'LoadImageList'
            acFileNames = acInputFromKofiko{2};
            Screen(g_strctPTB.m_hWindow,'FillRect',0);
            Screen(g_strctPTB.m_hWindow,'Flip');
            
            fnStimulusServerClearTextureMemory();
            [g_strctDraw.m_ahHandles,g_strctDraw.m_a2iTextureSize,...
                g_strctDraw.m_abIsMovie,g_strctDraw.m_aiApproxNumFrames,Dummy, g_strctDraw.m_acImages] = fnInitializeTexturesAux(acFileNames,false,true);
            
            fnStimulusServerToKofikoParadigm('AllImagesLoaded');
            g_strctServerCycle.m_iMachineState = 0;
        case 'ShowTrial'
            g_strctDraw.m_strctTrial = acInputFromKofiko{2};
            switch g_strctDraw.m_strctTrial.m_strctMedia.m_strMediaType
                case 'Image'
                    if g_strctPTB.m_bInStereoMode
                        % If we are already in stereo mode and a monocular image is to be presented, just duplicate the
                        % image across the two channels....
                        g_strctDraw.m_strctTrial.m_strctMedia.m_aiMediaToHandleIndexInBuffer = ones(1,2) * g_strctDraw.m_strctTrial.m_strctMedia.m_aiMediaToHandleIndexInBuffer;
                        g_strctServerCycle.m_iMachineState = 6;
                    else
                        g_strctServerCycle.m_iMachineState = 1;
                    end
                case 'Movie'
                    if g_strctPTB.m_bInStereoMode
                        % If we are already in stereo mode and a monocular image is to be presented, just duplicate the
                        % image across the two channels....
                        g_strctDraw.m_strctTrial.m_strctMedia.m_aiMediaToHandleIndexInBuffer = ones(1,2) * g_strctDraw.m_strctTrial.m_strctMedia.m_aiMediaToHandleIndexInBuffer;
                        g_strctServerCycle.m_iMachineState = 9;
                    else
                        g_strctServerCycle.m_iMachineState = 4;
                    end
                case 'StereoImage'
                    g_strctServerCycle.m_iMachineState = 6;
                case 'StereoMovie'
                    g_strctServerCycle.m_iMachineState = 9;
                otherwise
                    assert(false);
            end
    end
end;

switch g_strctServerCycle.m_iMachineState
    case 0
        % Do nothing
    case 1
        fnDisplayMonocularImage();
    case 2
        fnWaitMonocularImageONPeriod();
    case 3
        fnWaitMonocularImageOFFPeriod();

    otherwise
        modeNum = num2str(g_strctServerCycle.m_iMachineState);
        errorMessage = ['Different mode of presentation detected:' modeNum]; 
        error(errorMessage);
        
end;

return;


function fnDisplayMonocularImage()
global g_strctDraw g_strctPTB g_strctServerCycle

%Get relavant parameters
BandColor = g_strctDraw.m_strctTrial.m_afBandColor;
BandWidth = g_strctDraw.m_strctTrial.m_afBandWidth;
BandCenter = g_strctDraw.m_strctTrial.m_afBandCenter;
StimMode = g_strctDraw.m_strctTrial.m_afStimMode;
TargetPosRange = g_strctDraw.m_strctTrial.m_afPosRange;
hTexturePointer = g_strctDraw.m_strctTrial.m_strctMedia.m_aiMediaToHandleIndexInBuffer(1);
aiTextureSize = g_strctDraw.m_a2iTextureSize(:, hTexturePointer);
aiStimulusRect = fnComputeStimulusRect(g_strctDraw.m_strctTrial.m_fStimulusSizePix,aiTextureSize, ...
    g_strctDraw.m_strctTrial.m_pt2fStimulusPos);
BoxHeight = g_strctDraw.m_strctTrial.m_afBoxHeight;
aiStimulusScreenSize = g_strctPTB.m_aiRect;

%Fill background
Screen('FillRect',g_strctPTB.m_hWindow, g_strctDraw.m_strctTrial.m_afBackgroundColor);

%Draw letter
Screen('DrawTexture', g_strctPTB.m_hWindow, g_strctDraw.m_ahHandles(hTexturePointer),[],aiStimulusRect, g_strctDraw.m_strctTrial.m_fRotationAngle);

%Draw target box
left = g_strctPTB.m_aiRect(3)/2 - TargetPosRange;
right = g_strctPTB.m_aiRect(3)/2 + TargetPosRange;
top = 0; %g_strctPTB.m_aiRect(4)/2 - BoxHeight;
bottom = g_strctPTB.m_aiRect(4); %/2 + BoxHeight;

   
% Change color if the stimulus falls in the target range
if and(aiStimulusRect(1)> left, aiStimulusRect(3)<right)         
    Screen('FrameRect',g_strctPTB.m_hWindow,g_strctDraw.m_strctTrial.m_afCorrectBoxColor,[left top right bottom],50);
else
    Screen('FrameRect',g_strctPTB.m_hWindow,[0 0 0],[left top right bottom],50);
end

%If stimulus goes into the target box, play sound only once.
if aiStimulusRect(1)> left && aiStimulusRect(3)<right && g_strctPTB.SoundPlayed == 0 && ~isempty(g_strctPTB.m_hAudioDevice)
%     time = GetSecs();
    disp('Trying to play');
    PsychPortAudio('Start',g_strctPTB.m_hAudioDevice,1,0,0); % Blocking (!!!)
    Screen('FillRect',g_strctPTB.m_hWindow,[255 116 0],[0 0 10 10]);
    g_strctPTB.SoundPlayed = 1;
elseif isempty(g_strctPTB.m_hAudioDevice)
    error('No audio device')
end

%If stimulus goes out of the target box, reset the sound state
if aiStimulusRect(3)>right
    g_strctPTB.SoundPlayed = 0;
end

%Draw the bands
if BandWidth > 0
    BandWidth = round(BandWidth/2)*2;
    if StimMode < 3
        band1_center = round(aiStimulusScreenSize(4)/2-BandCenter);
        band2_center = round(aiStimulusScreenSize(4)/2+BandCenter);
        Screen('FillRect',g_strctPTB.m_hWindow,BandColor,[0,band1_center-BandWidth/2,aiStimulusScreenSize(3),band1_center+BandWidth/2]);
        Screen('FillRect',g_strctPTB.m_hWindow,BandColor,[0,band2_center-BandWidth/2,aiStimulusScreenSize(3),band2_center+BandWidth/2]);
    else
        
        band1_center = round(aiStimulusScreenSize(3)/2-BandCenter);
        band2_center = round(aiStimulusScreenSize(3)/2+BandCenter);
        Screen('FillRect',g_strctPTB.m_hWindow,BandColor,[band1_center-BandWidth/2,0,band1_center+BandWidth/2 ,aiStimulusScreenSize(4)]);
        Screen('FillRect',g_strctPTB.m_hWindow,BandColor,[band2_center-BandWidth/2,0,band2_center+BandWidth/2,aiStimulusScreenSize(4)]);
    end
end


g_strctServerCycle.m_fLastFlipTime = Screen('Flip',g_strctPTB.m_hWindow); % This would block the server until the next flip.
fnStimulusServerToKofikoParadigm('FlipON',g_strctServerCycle.m_fLastFlipTime,g_strctDraw.m_strctTrial.m_iStimulusIndex);
g_strctServerCycle.m_iMachineState = 2;
return;


function fnWaitMonocularImageONPeriod()
global g_strctDraw g_strctPTB g_strctServerCycle
fCurrTime  = GetSecs();

if (fCurrTime - g_strctServerCycle.m_fLastFlipTime) > g_strctDraw.m_strctTrial.m_fStimulusON_MS/1e3 - (0.2 * (1/g_strctPTB.m_iRefreshRate) )
    % Turn stimulus off
    if g_strctDraw.m_strctTrial.m_fStimulusOFF_MS > 0
        Screen('FillRect',g_strctPTB.m_hWindow, g_strctDraw.m_strctTrial.m_afBackgroundColor);
        
        aiFixationRect = [g_strctDraw.m_strctTrial.m_pt2iFixationSpot-g_strctDraw.m_strctTrial.m_fFixationSizePix,...
            g_strctDraw.m_strctTrial.m_pt2iFixationSpot+g_strctDraw.m_strctTrial.m_fFixationSizePix];
        
        Screen('FillArc',g_strctPTB.m_hWindow,[255 255 255], aiFixationRect,0,360);
        
        if g_strctDraw.m_strctTrial.m_bShowPhotodiodeRect
            
            Screen('FillRect',g_strctPTB.m_hWindow,[0 0 0], ...
                [g_strctPTB.m_aiRect(3)-g_strctDraw.m_strctTrial.m_iPhotoDiodeWindowPix ...
                g_strctPTB.m_aiRect(4)-g_strctDraw.m_strctTrial.m_iPhotoDiodeWindowPix ...
                g_strctPTB.m_aiRect(3) g_strctPTB.m_aiRect(4)]);
        end
        
        g_strctServerCycle.m_fLastFlipTime = Screen('Flip', g_strctPTB.m_hWindow); % Block.
        fnStimulusServerToKofikoParadigm('FlipOFF',g_strctServerCycle.m_fLastFlipTime);
        g_strctServerCycle.m_iMachineState = 3;
    else
        fnStimulusServerToKofikoParadigm('TrialFinished');
        g_strctServerCycle.m_iMachineState = 0;
    end
end

return;


function fnWaitMonocularImageOFFPeriod
global g_strctDraw g_strctPTB g_strctServerCycle
fCurrTime  = GetSecs();

if (fCurrTime - g_strctServerCycle.m_fLastFlipTime) > ...
        (g_strctDraw.m_strctTrial.m_fStimulusOFF_MS)/1e3 - (0.2 * (1/g_strctPTB.m_iRefreshRate) )
    fnStimulusServerToKofikoParadigm('TrialFinished');
    g_strctServerCycle.m_iMachineState = 0;
end
return;


