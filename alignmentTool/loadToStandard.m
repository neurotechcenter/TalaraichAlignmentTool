function [cortex,electrodes,aligment_pos] = loadToStandard(pathToSubject,pathToAlignmentPoints,Norig,Torig,pathToElectrodes,alignment)
%LOADTOSTANDARD Summary of this function goes here
%   Detailed explanation goes here


if(nargin < 6)
    alignment='tal';
end
pathToLhPial = strcat(pathToSubject, '/surf/lh.pial');
pathToRhPial = strcat(pathToSubject, '/surf/rh.pial');
if(nargin < 5)
    elecMatrix=zeros(0,3);
elseif(isempty(pathToElectrodes))
    elecMatrix=zeros(0,3);
else
    [~, ~, fExt] = fileparts(pathToElectrodes);
    switch(fExt)
        case '.dat'
            elecMatrix=importelectrodes(pathToElectrodes);
        case '.mat'
            load(pathToElectrodes);
        otherwise
            error('unexpected file extension!');
    end
    elecMatrix=(Torig*inv(Norig)*[elecMatrix(:, 1), elecMatrix(:, 2), elecMatrix(:, 3), ones(size(elecMatrix, 1), 1)]')';
    elecMatrix=elecMatrix(:, 1:3);
end
if(nargin < 3)
    Torig=[];
    Norig=[];
end

ac_dat=importelectrodes(pathToAlignmentPoints{1});
ac_dat=ac_dat(1,:);

pc_dat=importelectrodes(pathToAlignmentPoints{2});

mid_sag_dat=importelectrodes(pathToAlignmentPoints{3});


if(~isempty(Norig) && ~isempty (Torig))
    ac_dat   = (Torig*inv(Norig)*[  ac_dat(:, 1),   ac_dat(:, 2),   ac_dat(:, 3), ones(size(ac_dat, 1),   1)]')';
    pc_dat   = (Torig*inv(Norig)*[  pc_dat(:, 1),   pc_dat(:, 2),   pc_dat(:, 3), ones(size(pc_dat, 1),   1)]')';
    mid_sag_dat = (Torig*inv(Norig)*[mid_sag_dat(:, 1), mid_sag_dat(:, 2), mid_sag_dat(:, 3), ones(size(mid_sag_dat, 1), 1)]')';
    ac_dat=ac_dat(:,1:3);
    pc_dat=pc_dat(:,1:3);
    mid_sag_dat=mid_sag_dat(:,1:3);
end

[LHtempvert, LHtemptri] = read_surf(pathToLhPial);
[RHtempvert, RHtemptri] = read_surf(pathToRhPial);

cortex.vert=[LHtempvert; RHtempvert];

% references to vert matrix must be 1-based
LHtemptri = LHtemptri + 1;
RHtemptri = RHtemptri + 1;

% all RH verts come after all LH verts
adjustedRHtemptri = RHtemptri + size(LHtempvert, 1);
cortex.tri = [LHtemptri; adjustedRHtemptri];



[cortex,electrodes,aligment_pos]=projectToStandard(cortex,elecMatrix,[ac_dat;pc_dat;mid_sag_dat],alignment);


end

