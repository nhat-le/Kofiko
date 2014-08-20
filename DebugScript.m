hPTBWindow = Screen('OpenWindow', 0,[],[0 0 300 300]);
[hMovie,fDuration,fFramesPerSeconds,iWidth,iHeight]=Screen('OpenMovie', hPTBWindow, '\\KOFIKOCOMP\StimulusSet\MouseTest\Stimulus1.mov');
      

Screen('PlayMovie', hMovie, 1,0,1);
Screen('SetMovieTimeIndex',hMovie,0);
fNow = GetSecs();
iIter=0;
while (1)
[hFrameTexture, fWhen] = Screen('GetMovieImage', hPTBWindow, hMovie,1);
if hFrameTexture>0
    fprintf('Frame %d\n',iIter);iIter=iIter+1;
    Screen('DrawTexture', hPTBWindow, hFrameTexture,[],[50 50 200 200]);
    fCueOnsetTS = Screen('Flip',hPTBWindow,fNow+fWhen); % This would block the server until the next flip.
Screen('Close', hFrameTexture);
else
    break;
end

end

 