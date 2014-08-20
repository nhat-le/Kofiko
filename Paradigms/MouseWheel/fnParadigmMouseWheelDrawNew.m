function fnParadigmMouseWheelDrawNew()
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)


global g_strctParadigm


%% Draw Stimulus
if ~isempty(g_strctParadigm.m_strctCurrentTrial) && g_strctParadigm.m_bStimulusDisplayed && isfield(g_strctParadigm.m_strctCurrentTrial,'m_iStimulusIndex') && ...
        g_strctParadigm.m_iMachineState ~= 6
    % Trial exist. Check state and draw either the image g_strctParadigm.m_strctCurrentTrial
    iMediaToDisplay = g_strctParadigm.m_strctCurrentTrial.m_iStimulusIndex;
    switch g_strctParadigm.m_strctDesign.m_astrctMedia(iMediaToDisplay).m_strMediaType
        case 'Image'
            fnDisplayMonocularImageLocally();
        otherwise
            assert(false);
    end
end

return;


function fnDisplayMonocularImageLocally()
global g_strctParadigm g_strctPTB

pt2fStimulusPos =g_strctParadigm.m_strctCurrentTrial.m_pt2fStimulusPos;
fStimulusSizePix =g_strctParadigm.m_strctCurrentTrial.m_fStimulusSizePix;
fRotationAngle = g_strctParadigm.m_strctCurrentTrial.m_fRotationAngle;

hTexturePointer = g_strctParadigm.m_strctDesign.m_astrctMedia(g_strctParadigm.m_strctCurrentTrial.m_iStimulusIndex).m_aiMediaToHandleIndexInBuffer(1);

aiTextureSize = g_strctParadigm.m_strctTexturesBuffer.m_a2iTextureSize(:,hTexturePointer)';
aiStimulusRect = g_strctPTB.m_fScale * fnComputeStimulusRect(fStimulusSizePix, aiTextureSize, pt2fStimulusPos);

StimMode = g_strctParadigm.m_strctCurrentTrial.m_afStimMode;
BandWidth = g_strctParadigm.m_strctCurrentTrial.m_afBandWidth;
BandColor = g_strctParadigm.m_strctCurrentTrial.m_afBandColor;
BandCenter = g_strctParadigm.m_strctCurrentTrial.m_afBandCenter;
BackgroundColor = g_strctParadigm.m_strctCurrentTrial.m_afBackgroundColor;
CorrectBoxColor = g_strctParadigm.m_strctCurrentTrial.m_afCorrectBoxColor;

TargetPosRange = g_strctParadigm.TargetPosRange.Buffer(1,:,g_strctParadigm.TargetPosRange.BufferIdx);


%aiStimulusScreenSize = fnParadigmToKofikoComm('GetStimulusServerScreenSize');

if g_strctParadigm.m_bDisplayStimuliLocally
    if g_strctParadigm.m_strctCurrentTrial.m_bNoiseOverlay
        % Overlay image with nosie...will be slower (!)
        
        a2fImage = g_strctParadigm.m_strctTexturesBuffer.m_acImages{hTexturePointer};
        if size(a2fImage,3) == 3
            % Modify the image....
            I = a2fImage(:,:,1);
            a2bMask = I == 255;
            [a2fX,a2fY] = meshgrid(linspace(1,  size(g_strctParadigm.m_strctCurrentTrial.m_a2fNoisePattern,2), size(a2fImage,2)),...
                linspace(1,  size(g_strctParadigm.m_strctCurrentTrial.m_a2fNoisePattern,1), size(a2fImage,1)));
            a2fNoiseResamples = fnFastInterp2(g_strctParadigm.m_strctCurrentTrial.m_a2fNoisePattern, a2fX(:),a2fY(:));
            I(a2bMask) = a2fNoiseResamples(a2bMask)*255;
            a2fImage = I;
        end
        
        hImageID = Screen('MakeTexture', g_strctPTB.m_hWindow,  a2fImage);
        Screen('DrawTexture', g_strctPTB.m_hWindow, hImageID,[],aiStimulusRect, fRotationAngle);
        Screen('Close',hImageID);
        
    else
        % Default presentation mode of images...
        % Fill the background
        Screen('FillRect', g_strctPTB.m_hWindow, BackgroundColor);     
        
        % Draw the letter
        Screen('DrawTexture', g_strctPTB.m_hWindow, g_strctParadigm.m_strctTexturesBuffer.m_ahHandles(hTexturePointer),[],aiStimulusRect, fRotationAngle);
        
        % Draw target box
        %[left top right bottom] defines the position of the box
        
        BoxHeight = g_strctParadigm.BoxHeight.Buffer(1,:,g_strctParadigm.BoxHeight.BufferIdx);
        left = g_strctPTB.m_aiRect(3)/2 - TargetPosRange;
        right = g_strctPTB.m_aiRect(3)/2 + TargetPosRange;
        top = 0;
        bottom = g_strctPTB.m_aiRect(4);
        
        
        if and(aiStimulusRect(1)> left, aiStimulusRect(3)<right)         
            Screen('FrameRect',g_strctPTB.m_hWindow,CorrectBoxColor,[left top right bottom],50);
        else
            Screen('FrameRect',g_strctPTB.m_hWindow,[0 0 0],[left top right bottom],50);
        end
       

        if BandWidth > 0
          
            if StimMode < 3
                BandWidth = BandWidth/g_strctPTB.m_fScaledHeight*g_strctPTB.m_aiRect(4);
                BandWidth = round(BandWidth/2) * 2;
                BandCenter =  BandCenter/g_strctPTB.m_fScaledHeight*g_strctPTB.m_aiRect(4);
                
                band1_center = round(g_strctPTB.m_aiRect(4)/2-BandCenter);%+g_strctPTB.m_aiScreenRect(2);
                band2_center = round(g_strctPTB.m_aiRect(4)/2+BandCenter);%+g_strctPTB.m_aiScreenRect(2);
               
                Screen('FillRect',g_strctPTB.m_hWindow,BandColor,[0,band1_center-BandWidth/2,g_strctPTB.m_aiScreenRect(3),band1_center+BandWidth/2]);
                Screen('FillRect',g_strctPTB.m_hWindow,BandColor,[0,band2_center-BandWidth/2,g_strctPTB.m_aiScreenRect(3),band2_center+BandWidth/2]);
            else
                
                BandWidth = BandWidth/g_strctPTB.m_fScaledWidth*g_strctPTB.m_aiRect(3);
                BandWidth = round(BandWidth/2) * 2;
                BandCenter =  BandCenter/g_strctPTB.m_fScaledWidth*g_strctPTB.m_aiRect(3);
                band1_center = round(aiStimulusRect(3)/2-BandCenter)+g_strctPTB.m_aiScreenRect(2);
                band2_center = round(aiStimulusRect(3)/2+BandCenter)+g_strctPTB.m_aiScreenRect(2);
                Screen('FillRect',g_strctPTB.m_hWindow,BandColor,[band1_center-BandWidth/2,0,band1_center+BandWidth/2 ,g_strctPTB.m_aiRect(4)]);
                Screen('FillRect',g_strctPTB.m_hWindow,BandColor,[band2_center-BandWidth/2,0,band2_center+BandWidth/2,g_strctPTB.m_aiRect(4)]);
            end
        end
    end
    
    
else
    Screen(g_strctPTB.m_hWindow,'DrawText', sprintf('Image %d (%s)',g_strctParadigm.m_strctCurrentTrial.m_iStimulusIndex,...
        g_strctParadigm.m_strctDesign.m_astrctMedia(g_strctParadigm.m_strctCurrentTrial.m_iStimulusIndex).m_strName), pt2fStimulusPos(1),pt2fStimulusPos(2), [0 255 0]);
end

return;

