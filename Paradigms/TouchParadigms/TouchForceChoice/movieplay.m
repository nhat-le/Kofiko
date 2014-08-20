function movieplay(hPTBWindow)

[hPTBWindow] = Screen('OpenWindow', 0,[],[20 20 1200 700]);
[hMovie,fDuration,fFramesPerSeconds,iWidth,iHeight]=Screen('OpenMovie', hPTBWindow, 'C:\Shay\Data\StimulusSet\MouseTest\squares2.avi');
      
Screen('PlayMovie', hMovie, 1);
Screen('SetMovieTimeIndex',hMovie,0);

fNow = GetSecs();
i = 0;
while i < 100
[hFrameTexture, fWhen] = Screen('GetMovieImage', hPTBWindow, hMovie,1);
    if hFrameTexture>0
        %fprintf('Frame %d\n',iIter);iIter=iIter+1;
        Screen('DrawTexture', hPTBWindow, hFrameTexture,[],[]);
        i = i + 1;
        fCueOnsetTS = Screen('Flip',hPTBWindow,fNow+fWhen); % This would block the server until the next flip.
        Screen('Close', hFrameTexture);
    end
end
Screen('Flip', hPTBWindow);
Screen('CloseMovie', hMovie);
fprintf('done')