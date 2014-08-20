% Reanalyze trial outcome using raw eye movements...
% save('C:\acTrials','acTrials','strRawFolder','strSession','strctSync','strctKofiko','-V6');
function acTrials=fnReanalyzeSaccadeTrials(acTrials,strRawFolder,strSession,strctSync,strctKofiko,a2fTargetCenter,fFixationRadius,fChoiceRadius)
%load('C:\acTrials');
%iTrialIter = 1;
iNumTrials = length(acTrials);

strEyeXfile = [strRawFolder,filesep,strSession,'-EyeX.raw'];
strEyeYfile = [strRawFolder,filesep,strSession,'-EyeY.raw'];

pt2fCenter = strctKofiko.g_strctStimulusServer.m_aiScreenSize(3:4)/2;
fMinTimeToSpendInChoiceRegionMS = 3;

         
               
afTheta = linspace(0,2*pi,20);
fTrialTimeoutSec=1.5;
fTrialLengthSec = 0.65; % Cue prestation + memory period
fSaccadeVelocityThresholdHigh = 1.5;
fSaccadeVelocityThresholdLow= 0.4;

for iTrialIter=1:iNumTrials
    fprintf('Reanalyzing trial %d out of %d\n',iTrialIter,iNumTrials);
    fReactionTimeSec = NaN;
    iSelectedChoice = NaN;
    fAngularAccuracyDeg = NaN;
    fAmplitudeAccuracy = NaN;
    
    strctTrial = acTrials{iTrialIter};
    iCorrectChoiceIndexInTrial = find(cat(1,strctTrial.m_astrctChoicesMedia.m_bJuiceReward));
    pt2fCorrectChoicePos = strctTrial.m_astrctChoicesMedia(iCorrectChoiceIndexInTrial).m_pt2fPosition-pt2fCenter;
    [fDummy,iCorrectChoiceIndex] = min(sqrt((pt2fCorrectChoicePos(1) - a2fTargetCenter(:,1)).^2+(pt2fCorrectChoicePos(2) - a2fTargetCenter(:,2)).^2));
    fTargetDistance = sqrt(sum(a2fTargetCenter(iCorrectChoiceIndex,:).^2));
    assert(fDummy == 0);
    if ~isfield(strctTrial.m_strctTrialOutcome,'m_afCueOnset_TS_StimulusServer')
        acTrials{iTrialIter}.m_strctNewTrialOutcome = [];
        continue;
    end;
    fTime0_Stat = strctTrial.m_strctTrialOutcome.m_afCueOnset_TS_StimulusServer;
    fTime0_PLX = fnTimeZoneChange( fTime0_Stat, strctSync, 'StimulusServer','Plexon');
    fTime1_PLX = fTime0_PLX + fTrialLengthSec + fTrialTimeoutSec; % Max trial length;
    
    % At time 0, eye coordinate should be inside the fixation window, and
    % that should have been for the past 500 ms
    
    [strctEyeX, afPlexonTime] = fnReadDumpAnalogFile(strEyeXfile,'Interval',[fTime0_PLX,fTime1_PLX]);
    [strctEyeY, afPlexonTime] = fnReadDumpAnalogFile(strEyeYfile,'Interval',[fTime0_PLX,fTime1_PLX]);
    % Convert the raw eye position to pixel coordinates.
    afOffsetX = fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.CenterX, 'Kofiko','Plexon',afPlexonTime, strctSync);
    afOffsetY = fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.CenterY, 'Kofiko','Plexon',afPlexonTime, strctSync);
    afGainX = fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.GainX, 'Kofiko','Plexon',afPlexonTime, strctSync);
    afGainY = fnTimeZoneChangeTS_Resampling(strctKofiko.g_strctEyeCalib.GainY, 'Kofiko','Plexon',afPlexonTime, strctSync);
    afEyeXpix = double((strctEyeX.m_afData+2048 - afOffsetX).*afGainX + strctKofiko.g_strctStimulusServer.m_aiScreenSize(3)/2);
    afEyeYpix = double((strctEyeY.m_afData+2048 - afOffsetY).*afGainY + strctKofiko.g_strctStimulusServer.m_aiScreenSize(4)/2);
    
    afEyeXpixZero = afEyeXpix-pt2fCenter(1);
    afEyeYpixZero = afEyeYpix-pt2fCenter(2);
    
    
    afDistanceToFixationSpot = sqrt(afEyeXpixZero.^2+afEyeYpixZero.^2);
    
    % Try to estimate the first fixation point after the saccade outside
    % the fixation region
    afVelocitySmooth=abs([0;diff(fndllBilateral1D(afDistanceToFixationSpot,70,60,60))])';
    aiHighVelocityIndices = find(afVelocitySmooth>fSaccadeVelocityThresholdHigh);
    for k=1:length(aiHighVelocityIndices)
        iFirstFastIndex = aiHighVelocityIndices(k);
        fFirstFixationAfterSaccadeTimePoint = NaN;
        pt2fFirstFixationAfterSaccade = [];
        if ~isempty(iFirstFastIndex)
            abTemp = zeros(1,length(afVelocitySmooth))>0;
            abTemp(iFirstFastIndex:end)=true;
            astrctIntervals = fnGetIntervals(abTemp & afVelocitySmooth<fSaccadeVelocityThresholdLow);
            if ~isempty(astrctIntervals)
                aiLength = cat(1,astrctIntervals.m_iLength);
                iIndexFixation = find(aiLength>20,1,'first');
                if ~isempty(iIndexFixation)
                    if afDistanceToFixationSpot(astrctIntervals(iIndexFixation).m_iStart) > fFixationRadius
                        % Verify there is no invalid values between start
                        % and finish of saccade
                        fFirstFixationAfterSaccadeTimePoint = astrctIntervals(iIndexFixation).m_iStart;
                        bOutsideRange = ~all( abs(afEyeXpixZero(iFirstFastIndex:fFirstFixationAfterSaccadeTimePoint)) < 2000) || ...
                            ~all( abs(afEyeYpixZero(iFirstFastIndex:fFirstFixationAfterSaccadeTimePoint)) < 2000) ;
                        if bOutsideRange
                            astrctIntervals = fnGetIntervals(abTemp & afVelocitySmooth<4);
                            for j=1:length(astrctIntervals)
                                if astrctIntervals(j).m_iLength >= 3 && afDistanceToFixationSpot(  astrctIntervals(j).m_iStart) > fFixationRadius
                                    fFirstFixationAfterSaccadeTimePoint = astrctIntervals(j).m_iStart;
                                    break;
                                end
                            end
                        end
                        break;
                    end
                end
            end
        end
    end
    
    if ~isnan(fFirstFixationAfterSaccadeTimePoint)
        % Correct the saccade start....
        astrctIntervals = fnGetIntervals(afVelocitySmooth < fSaccadeVelocityThresholdLow);
        if ~isempty(astrctIntervals)
            aiLengths = cat(1,astrctIntervals.m_iLength);
            aiEnds = cat(1,astrctIntervals.m_iEnd);
            iLastInterval = find(aiEnds < iFirstFastIndex & aiLengths > 20,1,'last');
            if ~isempty(iLastInterval)
                iFirstFastIndex = astrctIntervals(iLastInterval).m_iEnd;
            end
        end
        
        % Esimtate saccade accuracy in terms of distance to center of
        % target.
        pt2fFirstFixationAfterSaccade = [afEyeXpixZero(fFirstFixationAfterSaccadeTimePoint), afEyeYpixZero(fFirstFixationAfterSaccadeTimePoint)];
        fAmplitudeAccuracy=  sqrt((afEyeXpixZero(fFirstFixationAfterSaccadeTimePoint)-a2fTargetCenter(iCorrectChoiceIndex,1)).^2+...
            (afEyeYpixZero(fFirstFixationAfterSaccadeTimePoint)-a2fTargetCenter(iCorrectChoiceIndex,2)).^2);
        
    end
    
    iIndex=[];
    % Now, estimate decision using regions outside fixation spot
    astrctIntervals = fnGetIntervals(afDistanceToFixationSpot>fFixationRadius);
    if isempty(astrctIntervals)
        fFirstTimeOutsideFixationRegion = [];
    else
        aiLength = cat(1,astrctIntervals.m_iLength);
        iIndex=find(aiLength>20,1,'first');
        if isempty(iIndex)
        fFirstTimeOutsideFixationRegion = [];
        else
        fFirstTimeOutsideFixationRegion = afPlexonTime(astrctIntervals(iIndex).m_iStart)-fTime0_PLX;
        end
    end
    if ~isempty(iIndex)
        fExitAngle = atan2(afEyeYpixZero(astrctIntervals(iIndex).m_iStart),        afEyeXpixZero(astrctIntervals(iIndex).m_iStart));
    else
        fExitAngle = NaN;
    end
    
    
    if isempty(fFirstTimeOutsideFixationRegion ) || (fFirstTimeOutsideFixationRegion > fTrialTimeoutSec+fTrialLengthSec)
        strTrialOutcome = 'Timeout';
    else
        % Which choice?
        afTimeForChoice = NaN*ones(1,8);
        aiIndexOfTimeForChoice = NaN*ones(1,8);
        for iChoiceIter=1:8
            abInsideChoice = sqrt( (afEyeXpixZero-a2fTargetCenter(iChoiceIter,1)).^2+(afEyeYpixZero-a2fTargetCenter(iChoiceIter,2)).^2) <= fChoiceRadius;
            astrctIntervals = fnGetIntervals(abInsideChoice);
            % Valid intervals (larger than 5 ms) ?
            if ~isempty(astrctIntervals)
                afIntervalLength = cat(1,astrctIntervals.m_iLength);
                iIndex = find(afIntervalLength*0.25>=fMinTimeToSpendInChoiceRegionMS,1,'first');
                if ~isempty(iIndex)
                    aiIndexOfTimeForChoice(iChoiceIter) = astrctIntervals(iIndex).m_iStart;
                    afTimeForChoice(iChoiceIter) = afPlexonTime(astrctIntervals(iIndex).m_iStart)-fTime0_PLX-fTrialLengthSec;
                end
            end
        end
        % Find first choice....
        if all(isnan(afTimeForChoice))
            % This is more like a short amplitude response....
            
            % But which direction did he go for?
            iIndex = find(afDistanceToFixationSpot>fFixationRadius,1,'first');
            aiIndexOfTimeForChoice = iIndex;
            afDirection = [afEyeXpixZero(iIndex ), afEyeYpixZero(iIndex )];
            afDirection =afDirection/norm(afDirection)*fTargetDistance;
            [fDummy, iSelectedChoice]=min(sqrt((afDirection(1)-a2fTargetCenter(:,1)).^2+(afDirection(2)-a2fTargetCenter(:,2)).^2));
            fReactionTimeSec = afPlexonTime(iIndex)-fTime0_PLX-fTrialLengthSec;
        fAngularAccuracyDeg = abs(atan2( afEyeYpixZero(aiIndexOfTimeForChoice),afEyeXpixZero(aiIndexOfTimeForChoice))/pi*180-...
            atan2( a2fTargetCenter(iCorrectChoiceIndex,2),a2fTargetCenter(iCorrectChoiceIndex,1))/pi*180);
        else
            [fReactionTimeSec, iSelectedChoice] = min(afTimeForChoice);
        fAngularAccuracyDeg = abs(atan2( afEyeYpixZero(aiIndexOfTimeForChoice(iSelectedChoice)),afEyeXpixZero(aiIndexOfTimeForChoice(iSelectedChoice)))/pi*180-...
            atan2( a2fTargetCenter(iCorrectChoiceIndex,2),a2fTargetCenter(iCorrectChoiceIndex,1))/pi*180);
            
        end
        
        
        if fFirstTimeOutsideFixationRegion <= fTrialLengthSec
            strTrialOutcome = 'Aborted';
            % OK, but which target was selected?
        else
            % Either correct or incorrect. Depending on trial type.
            if iSelectedChoice == iCorrectChoiceIndex
                strTrialOutcome = 'Correct';
            else
                strTrialOutcome = 'Incorrect';
            end
        end
    end
    
    strctNewTrialOutcome.m_fAmplitudeAccuracy = fAmplitudeAccuracy;
    strctNewTrialOutcome.m_fAngularAccuracyDeg = fAngularAccuracyDeg;
    strctNewTrialOutcome.m_iSelectedTarget = iSelectedChoice;
    strctNewTrialOutcome.m_fReactionTimeSec =fReactionTimeSec;
    strctNewTrialOutcome.m_strOutcome =strTrialOutcome;
    strctNewTrialOutcome.m_afEyeXpixZero = afEyeXpixZero;
    strctNewTrialOutcome.m_afEyeYpixZero = afEyeYpixZero;
    strctNewTrialOutcome.m_pt2fFirstFixationAfterSaccade = pt2fFirstFixationAfterSaccade;
    strctNewTrialOutcome.m_fExitAngle = fExitAngle;
    acTrials{iTrialIter}.m_strctNewTrialOutcome = strctNewTrialOutcome;
    
    
        if 0
        figure(11);
        clf;hold on;
        plot(fFixationRadius*cos(afTheta),fFixationRadius*sin(afTheta),'r');
        % plot targets
        for k=1:8
            if k == iCorrectChoiceIndex
                plot(a2fTargetCenter(k,1)+80*cos(afTheta),a2fTargetCenter(k,2)+80*sin(afTheta),'g');
            else
                plot(a2fTargetCenter(k,1)+80*cos(afTheta),a2fTargetCenter(k,2)+80*sin(afTheta),'b');
            end
            if ~isnan(iSelectedChoice) && k == iSelectedChoice
                plot(a2fTargetCenter(k,1)+50*cos(afTheta),a2fTargetCenter(k,2)+50*sin(afTheta),'g');
            end
            text(a2fTargetCenter(k,1),a2fTargetCenter(k,2),sprintf('%d',k));
        end
        iTemp = find(afPlexonTime>fTime0_PLX+fTrialLengthSec,1,'first');
        
        plot(afEyeXpix(1:iTemp)-pt2fCenter(1),afEyeYpix(1:iTemp)-pt2fCenter(2),'k');
        plot(afEyeXpix(iTemp:end)-pt2fCenter(1),afEyeYpix(iTemp:end)-pt2fCenter(2),'c');
        if ~isempty(pt2fFirstFixationAfterSaccade)
            plot(pt2fFirstFixationAfterSaccade(1),pt2fFirstFixationAfterSaccade(2),'ro','MarkerSize',21);
        end
        
        if ~isempty(iFirstFastIndex) && ~isnan(fFirstFixationAfterSaccadeTimePoint)
            plot(afEyeXpixZero(iFirstFastIndex:fFirstFixationAfterSaccadeTimePoint),afEyeYpixZero(iFirstFastIndex:fFirstFixationAfterSaccadeTimePoint),'m')
            plot([0 afEyeXpixZero(fFirstFixationAfterSaccadeTimePoint)],[0 afEyeYpixZero(fFirstFixationAfterSaccadeTimePoint)],'r','LineWidth',2)
        end

        
        axis([-500 500 -500 500]);
        title(sprintf('Trial %d Outcome: %s',iTrialIter,strTrialOutcome));
        pause
    end
    
end
