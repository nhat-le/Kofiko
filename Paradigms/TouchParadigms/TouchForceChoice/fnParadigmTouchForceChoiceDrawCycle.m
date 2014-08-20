function varargout=fnParadigmTouchForceChoiceDrawCycle(acInputsFromKofiko)
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)

global  g_strctDraw g_strctStimulusServer g_strctPTB g_strctParadigm


if g_strctPTB.m_bRunningOnStimulusServer
    hPTBWindow = g_strctPTB.m_hWindow;
else
    hPTBWindow = g_strctStimulusServer.m_hWindow;
end
varargout{1} = [];
varargout{2} = [];
if ~isempty(acInputsFromKofiko)
    
    strCommand = acInputsFromKofiko{1};
    
    switch strCommand
        case 'LoadMedia'
            g_strctDraw.m_acMedia = fnLoadMedia(hPTBWindow,acInputsFromKofiko{2});
            fnStimulusServerToKofikoParadigm('MediaLoaded');
        case 'PrepareTrial'
            g_strctDraw.m_strctCurrentTrial = acInputsFromKofiko{2};
            
            % Load Images, unless they are already in memory...
            if g_strctDraw.m_strctCurrentTrial.m_bLoadOnTheFly
                g_strctDraw.m_acMedia = fnLoadMedia(hPTBWindow,g_strctDraw.m_strctCurrentTrial.m_astrctMedia);
                % Need to prep the media array in prepare trial function...
            end
            PsychPortAudio('Stop',g_strctPTB.m_hAudioDevice);
            
            fnStimulusServerToKofikoParadigm('TrialPreparationDone');
        case 'ClearScreen'
            Screen('Flip',hPTBWindow); % clear & Block
            PsychPortAudio('Stop',g_strctPTB.m_hAudioDevice);
            
        case 'ShowFixationSpot'
            fnDrawFixationSpot(hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_strctPreCueFixation, true, 1);
            fFlipTime =  Screen('Flip', hPTBWindow); % Blocking !
            if ~g_strctPTB.m_bRunningOnStimulusServer
                fFlipTime =  GetSecs(); % Don't trust TS obtained from flip on touch mode
            end
            fnStimulusServerToKofikoParadigm('FixationSpotFlip',fFlipTime); % For remote kofiko
            varargout{1} = fFlipTime; % for local touch screen
        case 'AbortTrial'
            if nargin > 1
                % We need to present only the choice media and wait for a while
                % before moving on...
                iSelectedChoice = acInputsFromKofiko{2};
                fTimeOnScreenMS =  acInputsFromKofiko{3};
                fnDisplayChoices(hPTBWindow,iSelectedChoice, g_strctDraw.m_strctCurrentTrial, g_strctDraw.m_acMedia, true, true,false,1,false); % Blocking (!)
                WaitSecs(fTimeOnScreenMS/1e3);
            end
            
            g_strctDraw.m_iMachineState  = 0;
            Screen('Flip', hPTBWindow); % Blocking !
            PsychPortAudio('Stop',g_strctPTB.m_hAudioDevice);
            
            if isfield(g_strctDraw,'m_strctCurrentTrial') && g_strctDraw.m_strctCurrentTrial.m_bLoadOnTheFly
                % Clean up!
                fnReleaseMedia( g_strctDraw.m_acMedia);
                g_strctDraw.m_acMedia = [];
            end
            return;
        case 'StartTrial'
            g_strctDraw.m_iMachineState = 1;
            WaitSecs(g_strctDraw.m_strctCurrentTrial.m_strctPreCueFixation.m_fPostTouchDelayMS/1e3);

        case 'ClearMemory'
            
    end
end

SHOW_CHOICES = 101;
MEMORY_PERIOD_WAIT = 100;
MEMORY_PERIOD = 105;
SHOWING_CUES = 50;
CUE_WAIT_WHILE_ON_SCREEN = 51;
CUE_MEMORY_PERIOD = 505;
CUE_MEMORY_PERIOD_WAIT = 506;
NEXT_CUE = 200;

if isfield(g_strctDraw,'m_iMachineState') && ~isempty(g_strctDraw.m_iMachineState)
    %fprintf('%d\n', g_strctDraw.m_iMachineState);
    switch  g_strctDraw.m_iMachineState
        case 1
            % Trial started. Show cue(s) if needed...
            
            if isempty(g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia)
                % NO CUE condition
                if ~isempty(g_strctDraw.m_strctCurrentTrial.m_astrctChoicesMedia)
                    
                    if ~isempty(g_strctDraw.m_strctCurrentTrial.m_strctMemoryPeriod)
                        g_strctDraw.m_fMemoryOnsetTS = GetSecs();
                        g_strctDraw.m_iMachineState  = MEMORY_PERIOD_WAIT;
                    else
                        g_strctDraw.m_iMachineState  = SHOW_CHOICES;
                    end
                else
                    g_strctDraw.m_iMachineState  = 0; % Degenerate case (touch screen training)
                end
                
            else
                % CUE CONDITION (!)
                g_strctDraw.m_iCurrentCue = 1;
                g_strctDraw.m_iMachineState = SHOWING_CUES;
                
            end
            
            
        case SHOWING_CUES
            if  ~g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bDisplayCue
                g_strctDraw.m_iMachineState = NEXT_CUE;
            else
                % Movie
                if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bMovie
                    g_strctDraw.m_afCueOnsetTS(g_strctDraw.m_iCurrentCue) =fnInitializeMovie(hPTBWindow); % And display first frame...
                else
                    g_strctDraw.m_afCueOnsetTS(g_strctDraw.m_iCurrentCue)=fnDrawCue(hPTBWindow,true);
                end
                
                fnStimulusServerToKofikoParadigm('CueOnset',g_strctDraw.m_afCueOnsetTS(g_strctDraw.m_iCurrentCue),g_strctDraw.m_iCurrentCue);
                g_strctDraw.m_iMachineState = CUE_WAIT_WHILE_ON_SCREEN;
            end
        case CUE_WAIT_WHILE_ON_SCREEN
            % Keep playing movie until cue period has elapsed.
            if GetSecs()-g_strctDraw.m_afCueOnsetTS(g_strctDraw.m_iCurrentCue) <= ...
                    g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_fCuePeriodMS/1e3  - (0.2 * (1/g_strctPTB.m_iRefreshRate) )
                
                if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bMovie
                    fnKeepPlayingMovie(hPTBWindow);
                end
            else
                g_strctDraw.m_iMachineState = CUE_MEMORY_PERIOD;
            end
        case CUE_MEMORY_PERIOD
            
            if  g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_fCueMemoryPeriodMS > 0
                
                Screen('FillRect',hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_afBackgroundColor);
                if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bCueMemoryPeriodShowFixation
                    fnDrawFixationSpot(hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue), false, 1);
                end
                g_strctDraw.m_afCueMemoryOnsetTS(g_strctDraw.m_iCurrentCue) = Screen('Flip',hPTBWindow);
                
                if ~g_strctPTB.m_bRunningOnStimulusServer
                    g_strctDraw.m_afCueMemoryOnsetTS(g_strctDraw.m_iCurrentCue) =  GetSecs(); % Don't trust TS obtained from flip on touch mode
                end
                fnStimulusServerToKofikoParadigm('CueMemoryOnsetTS',g_strctDraw.m_afCueMemoryOnsetTS(g_strctDraw.m_iCurrentCue), g_strctDraw.m_iCurrentCue);
                varargout{1} = 'CueMemoryOnsetTS';
                varargout{2} = g_strctDraw.m_afCueMemoryOnsetTS(g_strctDraw.m_iCurrentCue);
                
                g_strctDraw.m_iMachineState = CUE_MEMORY_PERIOD_WAIT;
                
                
                % Do we have a cue memoy period?
                % If yes, perform the wait
                % If not, go to next cue, or to the memory period before
                % choices...
            else
                % No Cue Memory Period. Next Cue?
                g_strctDraw.m_iMachineState =NEXT_CUE;
            end
            
        case CUE_MEMORY_PERIOD_WAIT
            if GetSecs()- g_strctDraw.m_afCueMemoryOnsetTS(g_strctDraw.m_iCurrentCue) > ...
                    (g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_fCueMemoryPeriodMS/1e3 -(0.2 * (1/g_strctPTB.m_iRefreshRate) ))
                
                g_strctDraw.m_iMachineState =NEXT_CUE;
            end
            
        case NEXT_CUE
            
            iNumCues = length(g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia);
            if g_strctDraw.m_iCurrentCue+1 > iNumCues
                % Finished showing cues!
                % Goto memory period!
                g_strctDraw.m_iMachineState = MEMORY_PERIOD;
            else
                g_strctDraw.m_iCurrentCue = g_strctDraw.m_iCurrentCue + 1;
                g_strctDraw.m_iMachineState = SHOWING_CUES;
            end
            
        case MEMORY_PERIOD
            
            % Cue period is over! Do we have a cue memory period?
            if ~isempty(g_strctDraw.m_strctCurrentTrial.m_strctMemoryPeriod) && (g_strctDraw.m_strctCurrentTrial.m_strctMemoryPeriod.m_fMemoryPeriodMS ~= 0)
                Screen('FillRect',hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_strctMemoryPeriod.m_afBackgroundColor);
                if g_strctDraw.m_strctCurrentTrial.m_strctMemoryPeriod.m_bShowFixationSpot
                    fnDrawFixationSpot(hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_strctMemoryPeriod, false, 1);
                end
                g_strctDraw.m_fMemoryOnsetTS = Screen('Flip',hPTBWindow);
                
                if ~g_strctPTB.m_bRunningOnStimulusServer
                    g_strctDraw.m_fMemoryOnsetTS =  GetSecs(); % Don't trust TS obtained from flip on touch mode
                end
                fnStimulusServerToKofikoParadigm('MemoryOnsetTS',g_strctDraw.m_fMemoryOnsetTS);
                varargout{1} = 'MemoryOnsetTS';
                varargout{2} = g_strctDraw.m_fMemoryOnsetTS;
                
                g_strctDraw.m_iMachineState = MEMORY_PERIOD_WAIT;
            else
                g_strctDraw.m_iMachineState = SHOW_CHOICES;
            end
            
            
        case MEMORY_PERIOD_WAIT
            % Memory period
            if GetSecs()-g_strctDraw.m_fMemoryOnsetTS > (g_strctDraw.m_strctCurrentTrial.m_strctMemoryPeriod.m_fMemoryPeriodMS/1e3 - (0.2 * (1/g_strctPTB.m_iRefreshRate) ))
                g_strctDraw.m_iMachineState = SHOW_CHOICES;
            end
            
            
            
        case SHOW_CHOICES
           
            if ~g_strctDraw.m_strctCurrentTrial.m_strctChoices.m_bKeepCueOnScreen
                if g_strctDraw.m_strctCurrentTrial.m_strctChoices.m_bShowChoicesOnScreen                     
                    fChoicesOnsetTS = fnDisplayChoices(hPTBWindow, 1:iNumChoices, g_strctDraw.m_strctCurrentTrial, g_strctDraw.m_acMedia,true,true,false,1,false);
                else
                    fChoicesOnsetTS = fnDisplayChoices(hPTBWindow, [], g_strctDraw.m_strctCurrentTrial, g_strctDraw.m_acMedia,true,true,false,1,false);
                end
            else
                fnDrawCue(hPTBWindow,false);
                fnDisplayChoices(hPTBWindow, 1:iNumChoices, g_strctDraw.m_strctCurrentTrial, g_strctDraw.m_acMedia,false,false,false,1,false);
                fChoicesOnsetTS = Screen('Flip',hPTBWindow); % This would block the server until the next flip.
                if ~g_strctPTB.m_bRunningOnStimulusServer
                    fChoicesOnsetTS =  GetSecs(); % Don't trust TS obtained from flip on touch mode
                end
            end
            
            fnStimulusServerToKofikoParadigm('ChoicesOnsetTS',fChoicesOnsetTS);
            
            fprintf('Paradigm %g \n') 
            
            if g_strctParadigm.m_iMachineState == 21
            % Choices
            iNumChoices =  length(g_strctDraw.m_strctCurrentTrial.m_astrctChoicesMedia); 
            % INITIALIZE "MOVIE" 
            x = -150; y = 350; w = 0; h = 500; 
            rect = [x;y;w;h];
            % window = hPTBWindow
            n = 1;
            speed = 5;
            start = Screen('Flip', hPTBWindow);
            rate = Screen('GetFlipInterval', hPTBWindow);
            while g_strctParadigm.m_bMovie == 1
                % ANIMATION
                fnParadigmToKofikoComm('SetParadigmState', sprintf('Waiting for answer (%.2f Sec)',g_strctParadigm.m_strctCurrentTrial.m_strctPostTrial.m_fTrialTimeoutMS/1e3-fElapsedTime));
                Screen('FillRect', hPTBWindow, [], rect);
                Screen('Flip', hPTBWindow, start + speed*n*rate);
                n = n + 1;        
                for row = 1:4
                    if row == 1 || row == 3
                        for col = 1: size(rect, 2)
                            rect(row, col) = rect(row, col) + 12;
                        end
                    end
                end
                %add a new square 
                newrect = [x; y; w; h];
                rect = [rect newrect];

                % if a square has moved off-screen, remove its column from rect
    %             for j = 1 : size(rect, 2)
    %                 if rect(1, j) == screenWidth
    %                     rect(:, j) = [];
    %                 end
    %             end
            end
            
            rect = [];
            %JCL 10/17/13
            %Screen('PlayMovie', g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_hHandle, 1,0,1);
            %fnKeepPlayingMovie(hPTBWindow);
            end
            
            
            varargout{1} = 'ChoicesOnsetTS';
            varargout{2} = fChoicesOnsetTS;
            g_strctDraw.m_iMachineState = 7;
            PsychPortAudio('Stop',g_strctPTB.m_hAudioDevice);
        case 7
            % Trial is almost over ? unless we need to extinguish
            % non-saccaded targets....
            
    end
end

return;




function fCueOnsetTS=fnInitializeMovie(hPTBWindow, iCueIndex)
global g_strctDraw g_strctPTB


if g_strctDraw.m_strctCurrentTrial.m_bLoadOnTheFly
    g_strctDraw.m_iLocalMediaIndex = g_strctDraw.m_iCurrentCue; 

else
    g_strctDraw.m_iLocalMediaIndex = g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_iMediaIndex;
end


Screen('PlayMovie', g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_hHandle, 1,0,1);
Screen('SetMovieTimeIndex',g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_hHandle,0);
g_strctDraw.m_fMovieOnset = GetSecs();

% Show first frame

% Clear screen
Screen('FillRect',hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_afBackgroundColor);

aiTextureSize = [ g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_iWidth,g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_iHeight];

g_strctDraw.m_aiStimulusRect = fnComputeStimulusRect(g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_fCueSizePix,aiTextureSize, ...
    g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_pt2fCuePosition);


[hFrameTexture, g_strctDraw.m_fMovieTimeToFlip] = Screen('GetMovieImage', hPTBWindow, ...
    g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_hHandle,1);

% Assume there is at least one frame in this movie... otherwise this
% will crash...
if hFrameTexture > 0
    Screen('DrawTexture', hPTBWindow, hFrameTexture,[],g_strctDraw.m_aiStimulusRect, 0);
    
    % Overlay fixation?
    if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bOverlayPreCueFixation
        fnDrawFixationSpot(hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue), false, 1);
    end
    
    if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bCueHighlight
        Screen('FrameRect',hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_afCueHighlightColor, g_strctDraw.m_aiStimulusRect,2);
    end
    
    fCueOnsetTS = Screen('Flip',hPTBWindow); % This would block the server until the next flip.
    Screen('Close', hFrameTexture);
else
    fCueOnsetTS = Screen('Flip',hPTBWindow);
end

if ~g_strctPTB.m_bRunningOnStimulusServer
    fCueOnsetTS =  GetSecs(); % Don't trust TS obtained from flip on touch mode
end


%         iApproxNumFrames = g_strctDraw.m_aiApproxNumFrames(g_strctDraw.m_strctTrial.m_iStimulusIndex);
%         g_strctDraw.m_iFrameCounter = 1;
return;


function fnKeepPlayingMovie(hPTBWindow)
global g_strctDraw
% Movie is playing... Fetch frame and display it
%g_strctDraw.m_iLocalMediaIndex = iCueIndex;

[hFrameTexture, fTimeToFlip] = Screen('GetMovieImage', hPTBWindow, ...
    g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_hHandle,1);

if hFrameTexture == -1
    % End of movie. Circular display....
    Screen('SetMovieTimeIndex',g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_hHandle,0);
    g_strctDraw.m_fMovieOnset = GetSecs();
else
    % Still have frames
    if fTimeToFlip == g_strctDraw.m_fMovieTimeToFlip
        % This frame HAS been displayed yet.
        % Don't do anything. (it should still be on the screen...)
        Screen('Close', hFrameTexture);
    else
        Screen('DrawTexture', hPTBWindow, hFrameTexture,[],g_strctDraw.m_aiStimulusRect, 0);
        % Overlay fixation?
        if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bOverlayPreCueFixation
            fnDrawFixationSpot(hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue), false, 1);
        end
        if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bCueHighlight
            Screen('FrameRect',hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_afCueHighlightColor, g_strctDraw.m_aiStimulusRect,2);
        end
        Screen('Flip',hPTBWindow, g_strctDraw.m_fMovieOnset+fTimeToFlip); % This would block the server until the next flip.
        Screen('Close', hFrameTexture);
    end
end

return;


function fCueOnsetTS=fnDrawCue(hPTBWindow,bFlip)
global g_strctDraw g_strctPTB
% Clear screen

if g_strctDraw.m_strctCurrentTrial.m_bLoadOnTheFly
    g_strctDraw.m_iLocalMediaIndex = g_strctDraw.m_iCurrentCue;
else
    g_strctDraw.m_iLocalMediaIndex = g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_iMediaIndex;
end

if  ~isempty(g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_strctAudio)
    % Start playing sound, only then display things on screen.
    % This will introduce some delay/latency, but since we don't know when
    % was the last flip.... we can't sync to that event.
    
    strctAudioSample = g_strctDraw.m_acMedia{g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_strctAudio.m_iMediaIndex    };
    strctAudioSample.m_afAudioData(:,2) = strctAudioSample.m_afAudioData(:,1);
    
    % fill up the buffer
    PsychPortAudio('FillBuffer', g_strctPTB.m_hAudioDevice, strctAudioSample.m_afAudioData');
    PsychPortAudio('Start',g_strctPTB.m_hAudioDevice,1,0,1); % Blocking (!!!)
end


if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bClearBefore
    Screen('FillRect',hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_afBackgroundColor);
end

aiTextureSize = [ g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_iWidth,g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_iHeight];
g_strctDraw.m_aiStimulusRect = fnComputeStimulusRect(g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_fCueSizePix,aiTextureSize, ...
    g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_pt2fCuePosition);

Screen('DrawTexture', hPTBWindow, g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_hHandle,[],g_strctDraw.m_aiStimulusRect, 0);

% Overlay fixation?
if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bOverlayPreCueFixation
    fnDrawFixationSpot(hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue), false, 1);
end

if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bCueHighlight
    Screen('FrameRect',hPTBWindow, g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_afCueHighlightColor, g_strctDraw.m_aiStimulusRect,2);
end
if bFlip
    
    if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bDontFlip
        fCueOnsetTS =  GetSecs(); 
    else
        if g_strctDraw.m_strctCurrentTrial.m_astrctCueMedia(g_strctDraw.m_iCurrentCue).m_bClearAfter
            fCueOnsetTS = Screen('Flip',hPTBWindow); % This would block the server until the next flip.
        else
            % Don't clear the buffer. Next cue can potentially be drawn on the
            % same screen as well...
            fCueOnsetTS = Screen('Flip',hPTBWindow,0,1); % This would block the server until the next flip.
        end
    end
    
    if ~g_strctPTB.m_bRunningOnStimulusServer
        fCueOnsetTS =  GetSecs(); % Don't trust TS obtained from flip on touch mode
    end
else
    fCueOnsetTS  = NaN;
end


return;




