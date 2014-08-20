function astrctMesh = fnBuildGridMesh_Standard(strctGridModel, bDrawShort)
clear astrctMesh

fGridHoleDiameterMM = fnGetGridParameter(strctGridModel.m_strctGridParams,'HoleDiam');
fOffsetX = fnGetGridParameter(strctGridModel.m_strctGridParams,'OffsetX');
fOffsetY = fnGetGridParameter(strctGridModel.m_strctGridParams,'OffsetY');
fGridHoleDistanceMM = fnGetGridParameter(strctGridModel.m_strctGridParams,'HoleDist');
fGridInnerDiameterMM = fnGetGridParameter(strctGridModel.m_strctGridParams,'GridInnerDiam');
fGridThetaRad = fnGetGridParameter(strctGridModel.m_strctGridParams,'Theta') /180*pi;
fGridPhiDeg = fnGetGridParameter(strctGridModel.m_strctGridParams,'Phi');
fGridHeightMM = fnGetGridParameter(strctGridModel.m_strctGridParams,'GridHeight');
bLongGrid = fnGetGridParameter(strctGridModel.m_strctGridParams,'LongGrid');

if bDrawShort
    fAboveGridMM = 0;
    bLongGrid = false;
    fElectrodeLengthMM = 2*fGridHeightMM;
else
    fAboveGridMM = 25;
    fLongGridMM = 80;
    fElectrodeLengthMM = 80;
end

iNumActiveHoles = sum(strctGridModel.m_strctGridParams.m_abSelectedHoles);
aiActiveHoles = find(strctGridModel.m_strctGridParams.m_abSelectedHoles);


if iNumActiveHoles > 0
    clear astrctMeshElectrode
    for iHoleIter=1:iNumActiveHoles
          astrctMeshElectrode(iHoleIter) = fnCreateRotatedCylinderMesh(...
            strctGridModel.m_apt3fGridHolesNormals(:, aiActiveHoles(iHoleIter))',...
            -strctGridModel.m_afGridHolesX(aiActiveHoles(iHoleIter)),...
            strctGridModel.m_afGridHolesY(aiActiveHoles(iHoleIter)),...
            fGridHoleDiameterMM, -(fElectrodeLengthMM), fAboveGridMM, 6,[1 0 1]);
    
    end
else
    astrctMeshElectrode = [];
end

astrctMeshMaster = fnBuildCylinderWithPlane(fGridHeightMM, fGridInnerDiameterMM, [1 0 0],fGridPhiDeg/180*pi, 0, 0, 0,fGridThetaRad,bLongGrid);
astrctMesh=[astrctMeshMaster,astrctMeshElectrode];
% 
% % Generate a plane that will indicate the grid Theta rotation
% strctMeshGridDir.m_a2fVertices = [                    0         0            0              0; ...
%     fGridInnerDiameterMM/2 0 fGridInnerDiameterMM/2 0;...
%     -fGridHeightMM -fGridHeightMM 0  0];
% 
% strctMeshGridDir.m_a2iFaces = [1,2,3; 2 3 4]';
% strctMeshGridDir.m_afColor = [0 1 0];
% strctMeshGridDir.m_fOpacity = 0.6;
% astrctMesh(1)  = strctMeshGridDir;
% 
% % Generate a cylinder for the inner diameter of the grid
% astrctMesh(2) = fnCreateCylinderMesh(fGridInnerDiameterMM, ...
%     -fGridHeightMM, 0, 20,[1 0 0]);
% 
% if bLongGrid
%     % The projection of the grid is portrayed by a rotated cylinder that
%     % points to the grid hole direction
%     afRotationDirection = [1 0 0];
%     fRotationAngle = fGridPhiDeg/180*pi;
%     a2fTrans = eye(4);
%     a2fTrans(1:3,1:3) = fnRotateVectorAboutAxis(afRotationDirection,fRotationAngle);
%     astrctMesh(3) = fnApplyTransformOnMesh( fnCreateCylinderMesh(fGridInnerDiameterMM, -fLongGridMM, 0, 20,[ 0 1 0]),a2fTrans);
% end
% 
% % Add holes
% 
% % iNumHoles = length(strctGridModel.m_afGridHolesX);
% % strctGridModel.m_strctGridParams.m_abSelectedHoles = zeros(1,iNumHoles)>0;
% % strctGridModel.m_strctGridParams.m_abSelectedHoles(1:5:end) = 1;
% iNumActiveHoles = sum(strctGridModel.m_strctGridParams.m_abSelectedHoles);
% aiActiveHoles = find(strctGridModel.m_strctGridParams.m_abSelectedHoles);
% 
% afRotationDirection = [1 0 0];
% a2fTransPhi = eye(4);
% a2fTransPhi(1:3,1:3) = fnRotateVectorAboutAxis(afRotationDirection,fGridPhiDeg/180*pi);
% a2fRotationTheta = eye(4);
% a2fRotationTheta(1:3,1:3) = fnRotateVectorAboutAxis([0 0 1], fGridThetaRad);
% 
% if iNumActiveHoles > 0
%     clear astrctMeshElectrode
%     strctMeshElectrodeZeroPos= fnCreateCylinderMesh(fGridHoleDiameterMM, ...
%         -(fElectrodeLengthMM), fAboveGridMM, 6,[1 0 1]);
%     for iHoleIter=1:iNumActiveHoles
%         iHoleIndex = aiActiveHoles(iHoleIter);
%         % First, rotate by Phi
%         strctElectrodeAfterPhi = fnApplyTransformOnMesh(strctMeshElectrodeZeroPos, a2fTransPhi);
%         % Then, rotate by theta. This will not affect [X,Y] since it is
%         % still at [0,0]...
%         strctElectrodeAfterTheta = fnApplyTransformOnMesh(strctElectrodeAfterPhi, a2fRotationTheta);
%         
%         % Now, translate by [X,Y]
%         a2fTransXY = eye(4);
%         a2fTransXY(1,4) = -strctGridModel.m_afGridHolesX(iHoleIndex);
%         a2fTransXY(2,4) = strctGridModel.m_afGridHolesY(iHoleIndex);
%         astrctMeshElectrode(iHoleIter) = fnApplyTransformOnMesh(strctElectrodeAfterTheta, a2fTransXY);
%     end
% else
%     astrctMeshElectrode = [];
% end
% 
% astrctMesh = fnApplyTransformOnMesh(astrctMesh, a2fRotationTheta);
% astrctMesh = [astrctMesh, astrctMeshElectrode];

if 0
    figure(11);
    clf;hold on;
    H=cla;
    fnDrawMeshIn3D(astrctMesh,H);
    %
    box on
    cameratoolbar show
    axis equal
end
return;
