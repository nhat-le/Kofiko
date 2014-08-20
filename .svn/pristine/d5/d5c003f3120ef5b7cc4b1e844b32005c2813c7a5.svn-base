function strctGridModel = fnBuildGridModel_Standard(strctGridParams)
% This function generates a structure that contains the grid model
% It uses various information in strctGridParams to construct the grid
% The output is a structure that must contain
%
%
% strctGridModel.m_strctGridParams  - Parameters used to construct this model
% strctGridModel.m_afGridHolesX    - Holes X Position
% strctGridModel.m_afGridHolesY    - Holes Y Position
% strctGridModel.m_apt3fGridHolesNormals - Holes Normal Direction
%
%

fGridHoleDiameterMM = fnGetGridParameter(strctGridParams,'HoleDiam');
fOffsetX = fnGetGridParameter(strctGridParams,'OffsetX');
fOffsetY = fnGetGridParameter(strctGridParams,'OffsetY');
fGridHoleDistanceMM = fnGetGridParameter(strctGridParams,'HoleDist');
fGridInnerDiameterMM = fnGetGridParameter(strctGridParams,'GridInnerDiam');
fGridThetaRad = fnGetGridParameter(strctGridParams,'Theta') /180*pi;
fGridPhiDeg = fnGetGridParameter(strctGridParams,'Phi');
fGridHeightMM = fnGetGridParameter(strctGridParams,'GridHeight');
bClipInvalid =  fnGetGridParameter(strctGridParams,'ClipInvalid');
strNumHoles = fnGetGridParameter(strctGridParams,'NumHoles');
strCenterWhere = fnGetGridParameter(strctGridParams,'CenterWhere');
    
strHoleDistWhere = fnGetGridParameter(strctGridParams,'HoleDistWhere');
if strcmpi(strHoleDistWhere,'tilted')
	% with increasing tilt angle the disytance between the projections get
	% larger until at 90 degree it reaches infinity, for this to happen we
	% need to divide not multiply the tilted IHD by the cosine of the tilt
	% angle
    fGridHoleDistanceMM = fGridHoleDistanceMM / cos(fGridPhiDeg/180*pi);
end

strctGridModel.m_strctGridParams = strctGridParams;

% needs to be adjusted before fOffsetY is used for the holes...
if strcmpi(strCenterWhere,'tilted')
	tilted_center_2_hinge_distance_mm = fGridInnerDiameterMM / 2;
	fOffsetY = (tilted_center_2_hinge_distance_mm / cosd(fGridPhiDeg)) - tilted_center_2_hinge_distance_mm;
	
end

if strcmpi(strNumHoles,'auto')
 
    afXCenters = fOffsetX+[fliplr(-fGridHoleDistanceMM:...
        -fGridHoleDistanceMM:-((fGridInnerDiameterMM/2) - fGridHoleDiameterMM)),...
        0:fGridHoleDistanceMM:(fGridInnerDiameterMM/2) - fGridHoleDiameterMM];
    
    afYCenters = fOffsetY+[fliplr(-fGridHoleDistanceMM:...
        -fGridHoleDistanceMM:-((fGridInnerDiameterMM/2) - fGridHoleDiameterMM)),...
        0:fGridHoleDistanceMM:(fGridInnerDiameterMM/2) - fGridHoleDiameterMM];
    
else
    iNumHoles = str2num(strNumHoles);
    afXCenters = [fOffsetX + ([1:iNumHoles-1] * -fGridHoleDistanceMM),  fOffsetX + ([0:iNumHoles-1] * fGridHoleDistanceMM)];
    afYCenters = [fOffsetY + ([1:iNumHoles-1] * -fGridHoleDistanceMM),  fOffsetY + ([0:iNumHoles-1] * fGridHoleDistanceMM)];
end
afDistFromCenterX = -(length(afXCenters)-1)/2:(length(afXCenters)-1)/2;
afDistFromCenterY = -(length(afYCenters)-1)/2:(length(afYCenters)-1)/2;

[a2iDistX, a2iDistY] = meshgrid(afDistFromCenterX,afDistFromCenterY);
[a2fXc, a2fYc] = meshgrid(afXCenters, afYCenters);
    




% Build the normals (using Phi angle)
[fNormalX,fNormalY, fNormalZ] = sph2cart(pi/2, (90-fGridPhiDeg)/180*pi, 1); % Look at the X-Z plane
fNormalZ = -fNormalZ;

if bClipInvalid 
    a2bFeasibleTop =  sqrt(a2fXc.^2 + a2fYc.^2) + fGridHoleDiameterMM/2 < fGridInnerDiameterMM/2;
    fHoleLength = fGridHeightMM / cos(fGridPhiDeg/180*pi);
    
    a2bFeasibleBottom = sqrt(    (a2fXc + fNormalX*fHoleLength ).^2 + ...
    (a2fYc + fNormalY*fHoleLength ).^2) + fGridHoleDiameterMM/2< fGridInnerDiameterMM/2;

    a2bFeasible = a2bFeasibleBottom & a2bFeasibleTop;
else
    a2bFeasible = ones(size(a2fXc)) > 0;
end


N=sum(a2bFeasible(:));
afGridX = a2fXc(a2bFeasible);
afGridY = a2fYc(a2bFeasible);

% Now, Rotate the grid by theta
a2fR = [cos(fGridThetaRad) sin(fGridThetaRad)
    -sin(fGridThetaRad) cos(fGridThetaRad)];
Tmp = a2fR * [afGridX';afGridY'];
afGridHolesX = Tmp(1,:);
afGridHolesY = Tmp(2,:);


% And, rotate the normals as well....
afRotationDirection = [0 0 1];
a2fTrans = eye(4);
a2fTrans(1:3,1:3) = fnRotateVectorAboutAxis(afRotationDirection,fGridThetaRad);
Tmp = a2fTrans * [fNormalX;fNormalY;fNormalZ;1];

% All normals are the same....
apt3fGridNormals = repmat(Tmp,[1, N]);
apt3fGridNormals=apt3fGridNormals(1:3,:);

strctGridModel.m_afGridHolesX = afGridHolesX;
strctGridModel.m_afGridHolesY = afGridHolesY;
strctGridModel.m_aiLocX = a2iDistX(a2bFeasible);
strctGridModel.m_aiLocY = a2iDistY(a2bFeasible);

strctGridModel.m_apt3fGridHolesNormals = apt3fGridNormals;
strctGridModel.m_strctGridParams.m_abSelectedHoles = zeros(1, N)>0;

strctHoleInfo.m_strElectrodeType = '';
strctHoleInfo.m_fGuideTubeLengthMM = 0;
strctHoleInfo.m_fInitialDepthMM = 0;
strctHoleInfo.m_strTargetName = '';
strctHoleInfo.m_abChannels = zeros(1,128) > 0; % Max 128 channels
strctHoleInfo.m_afChannelDepthOffset = zeros(1,128); % Relative to tip
strctHoleInfo.m_strAdvancer = [];
for iGridHoleIter=1:N
    strctGridModel.m_strctGridParams.m_astrctHoleInformation(iGridHoleIter) = strctHoleInfo;
end

if 0
    % Draw GridafAlpha
    afAlpha = linspace(0,2*pi,100);
    afCos = cos(afAlpha);
    afSin = sin(afAlpha);
    
    figure(10);
    clf;
    hold on;
    for k=1:length(strctGridModel.m_afGridHolesX)
        
        plot(strctGridModel.m_afGridHolesX(k), strctGridModel.m_afGridHolesY(k),'ro');
        plot3([strctGridModel.m_afGridHolesX(k) strctGridModel.m_afGridHolesX(k) + strctGridModel.m_apt3fGridHolesNormals(1,k)*10],...
            [strctGridModel.m_afGridHolesY(k) strctGridModel.m_afGridHolesY(k) + strctGridModel.m_apt3fGridHolesNormals(2,k)*10],...
            [0                                0 + strctGridModel.m_apt3fGridHolesNormals(3,k)*fHoleLength],'b');
    end
    plot(afCos*fGridInnerDiameterMM/2,afSin*fGridInnerDiameterMM/2,'k');
    plot3(afCos*fGridInnerDiameterMM/2,afSin*fGridInnerDiameterMM/2,-fGridHeightMM *ones(size(afAlpha)),'k');
    
    plot3([0 10],[0 0],[0 0],'r','LineWidth',2);
    plot3([0 0],[0 10],[0 0],'g','LineWidth',2);
    plot3([0 0],[0 0],[0 -10],'c','LineWidth',2);
    xlabel('X');
    ylabel('Y');
    box on
    axis equal
    cameratoolbar
end

return;

