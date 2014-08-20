function fnParadigmMouseWheelParadigmSwitchNew(strEvent)
%
% Copyright (c) 2008 Shay Ohayon, California Institute of Technology.
% This file is a part of a free software. you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation (see GPL.txt)

global g_strctParadigm

switch strEvent
    case 'Init'
        strImageList = fnTsGetVar(g_strctParadigm,'ImageList');
        if ~isempty(strImageList)
             fnLoadMouseWheelDesign(strImageList);
        end;

        if  isfield(g_strctParadigm,'m_strctStatServerDesign')
            fnParadigmToStatServerComm('senddesign', g_strctParadigm.m_strctStatServerDesign);
        end
    
    case 'Close'
        if fnParadigmToStatServerComm('IsConnected')
            fnParadigmToStatServerComm('ClearDesign');
        end
        fnParadigmMouseWheelCleanTextureMemory();
end
return;
