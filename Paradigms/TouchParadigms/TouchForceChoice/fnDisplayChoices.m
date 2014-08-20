function fChoicesOnsetTS = fnDisplayChoices(hPTBWindow, aiChoices, strctCurrentTrial, acMedia,bFlip,bClear,bHighlightRewardedChoices,fScale, bDrawResponseRegion)
global  g_strctPTB
% Clear screen
if bClear
    Screen('FillRect',hPTBWindow, strctCurrentTrial.m_strctChoices.m_afBackgroundColor);
end


for iChoiceIter=aiChoices
    if strctCurrentTrial.m_bLoadOnTheFly
        iLocalMediaIndex = 1+iChoiceIter;
    else
        iLocalMediaIndex = strctCurrentTrial.m_astrctChoicesMedia(iChoiceIter).m_iMediaIndex;
    end
    
    aiTextureSize = [ acMedia{iLocalMediaIndex}.m_iWidth,acMedia{iLocalMediaIndex}.m_iHeight];
    
    aiStimulusRect = fnComputeStimulusRect(strctCurrentTrial.m_astrctChoicesMedia(iChoiceIter).m_fSizePix,aiTextureSize, ...
        strctCurrentTrial.m_astrctChoicesMedia(iChoiceIter).m_pt2fPosition);
    
    %Christine 10/28/13
    if acMedia{iLocalMediaIndex}.m_bMovie
        fnInitializeMovie(hPTBWindow, iLocalMediaIndex );
        fnKeepPlayingMovie(hPTBWindow);
    else        
        Screen('DrawTexture', hPTBWindow, acMedia{iLocalMediaIndex}.m_hHandle,[],fScale*aiStimulusRect, 0);   
    end
   %end christine     
    
    if bHighlightRewardedChoices
        if strctCurrentTrial.m_astrctChoicesMedia(iChoiceIter).m_bJuiceReward
            Screen('FrameRect', hPTBWindow, [0 255 0],fScale*aiStimulusRect,3);
        end
        if bDrawResponseRegion
            aiResponseRect = [strctCurrentTrial.m_astrctChoicesMedia(iChoiceIter).m_pt2fPosition(:)'-ones(1,2)*strctCurrentTrial.m_strctChoices.m_fInsideChoiceRegionSize,...
                                             strctCurrentTrial.m_astrctChoicesMedia(iChoiceIter).m_pt2fPosition(:)'+ones(1,2)*strctCurrentTrial.m_strctChoices.m_fInsideChoiceRegionSize];
            switch lower(strctCurrentTrial.m_strctChoices.m_strInsideChoiceRegionType)
                case 'rect'
                              Screen('FrameRect', hPTBWindow, [255 255 255],fScale*aiResponseRect);
                case 'circular'
                              Screen('FrameArc', hPTBWindow, [255 255 255],fScale*aiResponseRect,0,360);
                    
            end
        end
        
        
    end
    
end

if  strctCurrentTrial.m_strctChoices.m_bShowFixationSpot
      fnDrawFixationSpot(hPTBWindow, strctCurrentTrial.m_strctChoices, false, fScale);
end


if bFlip
    fChoicesOnsetTS = Screen('Flip',hPTBWindow); % This would block the server until the next flip.
    if ~g_strctPTB.m_bRunningOnStimulusServer
        fChoicesOnsetTS =  GetSecs(); % Don't trust TS obtained from flip on touch mode
    end
else
    fChoicesOnsetTS =  NaN;
end

return;

%Christine 10/28/13
function fCueOnsetTS=fnInitializeMovie(hPTBWindow, index)
global g_strctDraw g_strctPTB


if g_strctDraw.m_strctCurrentTrial.m_bLoadOnTheFly
    g_strctDraw.m_iLocalMediaIndex = index;
else
    g_strctDraw.m_iLocalMediaIndex = index;
end

[hMovie, fDuration, fFramesPerSeconds, iWidth, iHeight] = Screen('OpenMovie', hPTBWindow, g_strctDraw.m_acMedia{g_strctDraw.m_iLocalMediaIndex}.m_hHandle);
Screen('PlayMovie', hMovie, 1,0,1);
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
    Screen('DrawTexture', hPTBWindow, hFrameTexture,[],[], 0);
    
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

