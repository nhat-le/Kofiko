function fnParadigmMouseWheelGUINew()
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)

global g_strctParadigm g_strctPTB g_handles g_strctStimulusServer g_strctGUIParams


% Note, always add controllers as fields to g_strctParadigm.m_strctControllers
% This way, they are automatically removed once we switch to another
% paradigm


   
[hParadigmPanel, iPanelHeight, iPanelWidth] = fnCreateParadigmPanel();
strctControllers.m_hPanel = hParadigmPanel;
strctControllers.m_iPanelHeight = iPanelHeight;
strctControllers.m_iPanelWidth = iPanelWidth;

iNumButtonsInRow = 3;
iButtonWidth = iPanelWidth / iNumButtonsInRow - 20;


[strctDesignControllers.m_hPanel, strctDesignControllers.m_iPanelHeight,strctDesignControllers.m_iPanelWidth] = ...
    fnCreateParadigmSubPanel(hParadigmPanel,50,iPanelHeight-5,'Design');


[strctStimulusControllers.m_hPanel, strctStimulusControllers.m_iPanelHeight,strctStimulusControllers.m_iPanelWidth] = ...
    fnCreateParadigmSubPanel(hParadigmPanel,50,iPanelHeight-5,'Stimulus Parameters');


[strctJuiceControllers.m_hPanel, strctJuiceControllers.m_iPanelHeight,strctJuiceControllers.m_iPanelWidth] = ...
    fnCreateParadigmSubPanel(hParadigmPanel,50,iPanelHeight-5,'Juice Parameters');


strctControllers.m_hSubPanels = [strctDesignControllers.m_hPanel;strctStimulusControllers.m_hPanel;strctJuiceControllers.m_hPanel];

strctControllers.m_hSetSDesignPanel = uicontrol('Parent',hParadigmPanel, 'Style', 'pushbutton', 'String', 'Design',...
      'Position', [5 iPanelHeight-40 50 30], 'Callback', [g_strctParadigm.m_strCallbacks,'(''DesignPanel'');']);

strctControllers.m_hSetStimulusPanel = uicontrol('Parent',hParadigmPanel, 'Style', 'pushbutton', 'String', 'Stimulus',...
      'Position', [60 iPanelHeight-40 50 30], 'Callback', [g_strctParadigm.m_strCallbacks,'(''StimulusPanel'');']);
    
strctControllers.m_hSetJuicePanel = uicontrol('Parent',hParadigmPanel, 'Style', 'pushbutton', 'String', 'Juice',...
      'Position', [110+5 iPanelHeight-40 50 30], 'Callback', [g_strctParadigm.m_strCallbacks,'(''JuicePanel'');']);

  
  %% Juice Controllers
strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctJuiceControllers.m_hPanel, 40+30*0, ...
    'Juice Time (ms):', 'JuiceTimeMS',25, 100, [1, 5], fnTsGetVar(g_strctParadigm,'JuiceTimeMS'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctJuiceControllers.m_hPanel, 40+30*1, ...
    'WaitTime', 'WaitTime',0.1, 5, [0.1, .5], fnTsGetVar(g_strctParadigm,'WaitTime'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctJuiceControllers.m_hPanel, 40+30*2, ...
    'Target Pos Range (ms):', 'TargetPosRange',0, 1000, [1, 5], fnTsGetVar(g_strctParadigm,'TargetPosRange'));

set(strctJuiceControllers.m_hPanel,'visible','off');


%% Stimulus Controllers
strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*0, ...
    'Stimulus size (pix):', 'StimulusSizePix',0, 700,  [1, 50], fnTsGetVar(g_strctParadigm,'StimulusSizePix'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*1, ...
    'Rotation Angle (Deg):', 'RotationAngle', -180, 180, [1, 5], fnTsGetVar(g_strctParadigm,'RotationAngle'));


strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*2, ...
    'Min Stim ON Time (ms):', 'MinStimulusON_MS',g_strctStimulusServer.m_fRefreshRateMS, ...
    500*g_strctStimulusServer.m_fRefreshRateMS, ...
    [g_strctStimulusServer.m_fRefreshRateMS, g_strctStimulusServer.m_fRefreshRateMS*5],...
    fnTsGetVar(g_strctParadigm,'MinStimulusON_MS'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*3, ...
    'Max Stim ON Time (ms):', 'MaxStimulusON_MS',g_strctStimulusServer.m_fRefreshRateMS, ...
    500*g_strctStimulusServer.m_fRefreshRateMS, ...
    [g_strctStimulusServer.m_fRefreshRateMS, g_strctStimulusServer.m_fRefreshRateMS*5],...
    fnTsGetVar(g_strctParadigm,'MaxStimulusON_MS'));


strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*4, ...
    'Min Voltage Diff :', 'MinVoltageDiff',1, 1000,...
    [1 100],fnTsGetVar(g_strctParadigm,'MinVoltageDiff'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*5, ...
    'Max Voltage Diff :', 'MaxVoltageDiff',1, 50000,...
    [1 500],fnTsGetVar(g_strctParadigm,'MaxVoltageDiff'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*6, ...
    'Move Step (Pix):', 'MoveStepPix',10, 400,...
    [1 50],fnTsGetVar(g_strctParadigm,'MoveStepPix'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*7, ...
    'Band Width (Pix):', 'BandWidth',0, 250,...
    [1 50],fnTsGetVar(g_strctParadigm,'BandWidth'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*8, ...
    'Band Center', 'BandCenter',1, 500,...
    [1 50],fnTsGetVar(g_strctParadigm,'BandCenter'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*9, ...
    'Stimulation Mode', 'StimMode',1, 4,...
    [1 2],fnTsGetVar(g_strctParadigm,'StimMode'));

strctControllers = fnAddTextSliderEditComboSmallWithCallback2(strctControllers,strctStimulusControllers.m_hPanel, 40+30*11, ...
    'BoxHeight (pix):', 'BoxHeight',0, 700,  [1 50], fnTsGetVar(g_strctParadigm,'BoxHeight'));


strctControllers.m_hSetNewBackground = uicontrol('Parent',strctStimulusControllers.m_hPanel,'Style', 'pushbutton', 'String', 'Band Color',...
     'Position', [1 iPanelHeight-400 iButtonWidth 30], 'Callback', [g_strctParadigm.m_strCallbacks,'(''BandColor'');']);
 
strctControllers.m_hSetNewBackground = uicontrol('Parent',strctStimulusControllers.m_hPanel,'Style', 'pushbutton', 'String', 'Back Color',...
     'Position', [2*iButtonWidth+40 iPanelHeight-400 iButtonWidth 30], 'Callback', [g_strctParadigm.m_strCallbacks,'(''BackgroundColor'');']);

strctControllers.m_hStimulusPosChange = uicontrol('Parent',strctStimulusControllers.m_hPanel,'Style', 'pushbutton', 'String', 'Free Stimulus Pos',...
     'Position', [iButtonWidth+20 iPanelHeight-400 iButtonWidth 30], 'Callback', [g_strctParadigm.m_strCallbacks,'(''StimulusPos'');']);

set(strctStimulusControllers.m_hPanel,'visible','off');
%% Design options
strctControllers.hImageListContextMenu = uicontextmenu;
uimenu(strctControllers.hImageListContextMenu, 'Label', 'Load List', 'Callback', [g_strctParadigm.m_strCallbacks,'(''LoadList'');']);


strctControllers.m_hFavroiteLists = uicontrol('Style', 'listbox', 'String', fnCellToCharShort(g_strctParadigm.m_acFavroiteLists),...
    'Position', [5 iPanelHeight-200 ,strctDesignControllers.m_iPanelWidth-10 120], 'parent',strctDesignControllers.m_hPanel, 'Callback',[g_strctParadigm.m_strCallbacks,'(''LoadFavoriteList'');'],...
    'value',max(1,g_strctParadigm.m_iInitialIndexInFavroiteList),'UIContextMenu',strctControllers.hImageListContextMenu);

strctControllers.m_hBlockText= uicontrol('Style', 'text', 'String', 'Stimuli Blocks:',...
    'Position', [5 iPanelHeight-225 ,130 15], 'parent',strctDesignControllers.m_hPanel,'HorizontalAlignment','left');


if ~isempty(g_strctParadigm.m_strctDesign)
    acBlockNames = {g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlocks.m_strBlockName};
    acBlockNames = acBlockNames(g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder(1).m_aiBlockIndexOrder);
else
    acBlockNames = {};
end

if ~isempty(g_strctParadigm.m_strctDesign)
    acOrderNames = {g_strctParadigm.m_strctDesign.m_strctBlocksAndOrder.m_astrctBlockOrder.m_strOrderName};
else
    acOrderNames = {};
end

strctControllers.m_hBlockOrderPopup = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'popupmenu', 'String', ...
     acOrderNames,'value', 1,...
     'Position', [90 iPanelHeight-265 160 60], 'Callback', [g_strctParadigm.m_strCallbacks,'(''ChangeBlockOrder'');']);



strctControllers.m_hBlockLists = uicontrol('Style', 'listbox', 'String', acBlockNames,...
    'Position', [5 iPanelHeight-330 ,strctDesignControllers.m_iPanelWidth-10 100], 'parent',strctDesignControllers.m_hPanel, 'Callback',[g_strctParadigm.m_strCallbacks,'(''JumpToBlock'');'],...
    'value',1);




iOffset = 400;

strctControllers.m_hPhotoDiodeRect = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'checkbox', 'String', 'Photodiode Rect','value', g_strctParadigm.m_bShowPhotodiodeRect,...
     'Position', [5 iPanelHeight-iOffset-0 220 20], 'Callback', [g_strctParadigm.m_strCallbacks,'(''PhotoDiodeRectToggle'');']);

strctControllers.m_hRandomImageIndex = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'checkbox', 'String', 'Randomize Order','value', g_strctParadigm.m_bRandom,...
     'Position', [5 iPanelHeight-iOffset-20 220 20], 'Callback', [g_strctParadigm.m_strCallbacks,'(''Random'');']);

strctControllers.m_hParameterSweep = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'checkbox', 'String', 'Parameter Sweep','value', g_strctParadigm.m_bParameterSweep,...
     'Position', [5 iPanelHeight-iOffset-40 220 20], 'Callback', [g_strctParadigm.m_strCallbacks,'(''ParameterSweep'');']);
 

strctControllers.m_hParameterSweepPopup = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'popupmenu', 'String', ...
    {g_strctParadigm.m_astrctParameterSweepModes.m_strName},'value', 1,...
     'Position', [130 iPanelHeight-iOffset-115 160 60], 'Callback', [g_strctParadigm.m_strCallbacks,'(''ParameterSweepMode'');']);
 
strctControllers.m_hDisplayStimuliLocally = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'checkbox', 'String', 'Play Stimuli Locally','value', g_strctParadigm.m_bDisplayStimuliLocally,...
     'Position', [5 iPanelHeight-iOffset-120 120 20], 'Callback', [g_strctParadigm.m_strCallbacks,'(''PlayStimuliLocally'');']);
 
strctControllers.m_hShowWhileLoading = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'checkbox', 'String', 'Show While Loading','value',  g_strctParadigm.m_bShowWhileLoading,...
     'Position', [5 iPanelHeight-iOffset-140 220 20], 'Callback', [g_strctParadigm.m_strCallbacks,'(''ShowWhileLoading'');']);
 
 strctControllers.m_hBlocksDoneText = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'text', 'String', ...
     'After blocks action:','Position', [5 iPanelHeight-iOffset-235 100 20],'HorizontalAlignment','left');
 
acBlocksDoneAction = {'Reset And Stop',  'Set Next Order But Do not Start',   'Repeat Same Order',    'Set Next Order and Start'};

iIndex = fnFindString(acBlocksDoneAction, g_strctParadigm.m_strBlockDoneAction);
if iIndex == -1
    g_strctParadigm.m_strBlockDoneAction = acBlocksDoneAction{1};
    iIndex = 1;
end
 
 strctControllers.m_hBlocksDoneActionPopup = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'popupmenu', 'String', ...
     acBlocksDoneAction,'value', iIndex,...
     'Position', [130 iPanelHeight-iOffset-270 160 60], 'Callback', [g_strctParadigm.m_strCallbacks,'(''BlocksDoneAction'');']);


strctControllers.m_hLoopCurrentBlock = uicontrol('Parent',strctDesignControllers.m_hPanel,'Style', 'checkbox', 'String', 'Loop Current Block','value',  g_strctParadigm.m_bBlockLooping,...
     'Position', [5 iPanelHeight-iOffset-255 180 20], 'Callback', [g_strctParadigm.m_strCallbacks,'(''BlockLoopingToggle'');']);
 
 
 
g_strctParadigm.m_strctControllers = strctControllers;
return;
