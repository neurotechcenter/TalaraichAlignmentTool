function [cortex,cmapstruct,ix,tala,vcontribs,viewstruct,fs_root,bm_file] = loadBrainModelfromFreeSurfer(workspace_path,pathToFsInstallDirectory)
%LOADBRAINMODELFROMFREESURFER Summary of this function goes here
%   Detailed explanation goes here
ix=1;
viewstruct.what2view={'brain','electrodes'};
viewstruct.viewvect=[-90 0];
viewstruct.material='dull';
viewstruct.enablelight=1;
viewstruct.enableaxis=0;
viewstruct.lightpos=[-200 0 0];
viewstruct.lightingtype='gouraud';



cmapstruct.cmap=hot(64);
cmapstruct.basecol=[0.7 0.7 0.7];
cmapstruct.fading=1;
cmapstruct.ixg2=9;
cmapstruct.ixg1=-9;
cmapstruct.enablecolormap=1;
cmapstruct.enablecolorbar=0;
cmapstruct.cmin=0;
cmapstruct.cmax=2;
bm_file='mri/orig.mgz';


disp('Processing brain model...');

if(exist(fullfile(workspace_path,'brain_model_raw.mat'),'file') == 0)
    disp('Starting to load neccessary information from freesurfer... please specify the freesurfer segmentation root directory for the subject!');
    fs_root=uigetdir(pathToFsInstallDirectory,'Freesurfer root directory');
    
    pathToLhPial=fullfile(fs_root,'surf/lh.pial');
    pathToRhPial=fullfile(fs_root,'surf/rh.pial');

    [LHtempvert, LHtemptri] = read_surf(pathToLhPial);
    [RHtempvert, RHtemptri] = read_surf(pathToRhPial);
    cortex.vert=[LHtempvert; RHtempvert];

    LHtemptri = LHtemptri + 1;
    RHtemptri = RHtemptri + 1;

    adjustedRHtemptri = RHtemptri + size(LHtempvert, 1);
    cortex.tri = [LHtemptri; adjustedRHtemptri];
   

    save(fullfile(workspace_path,'brain_model_raw.mat'),'cortex','fs_root');
else
    load(fullfile(workspace_path,'brain_model_raw.mat'),'cortex','fs_root');
    disp('Loading brain model from workspace directory...');
end



disp('...done');
disp(' ');
disp(' ');

disp('Processing electrode locations.. ')
if(exist(fullfile(workspace_path,'electrode_locations.mat'),'file') == 0)
    
    xfrm_matrices = loadXFRMMatrix(workspace_path,pathToFsInstallDirectory,fs_root);
    Norig = xfrm_matrices(1:4, :);
    Torig = xfrm_matrices(5:8, :);
    disp('Please specify electrode location path file');
    [fname,path ]= uigetfile('*.dat','elecPointSet data file');
    elecMatrix=importelectrodes(fullfile(path,fname));
    elecMatrix_projected=(Torig*inv(Norig)*[elecMatrix(:, 1), elecMatrix(:, 2), elecMatrix(:, 3), ones(size(elecMatrix, 1), 1)]')';
    elecMatrix_projected=elecMatrix_projected(:, 1:3);
    save(fullfile(workspace_path,'electrode_locations.mat'),'elecMatrix','elecMatrix_projected');
    
else
    disp('Loading electrode locations from workspace directory');
    load(fullfile(workspace_path,'electrode_locations.mat'),'elecMatrix','elecMatrix_projected');
end

disp('...done');
disp(' ');
disp(' ');


tala.electrodes=elecMatrix_projected;
tala.activations=zeros(size(elecMatrix_projected,1),1);    

disp('Projecting electrodes onto cortex... ')
cortexcoarser = coarserModel(cortex, 10000);

origin = [0 20 40];
smoothrad = 25;
mult = 0.5;
[cortexsmoothed] = smoothModel(cortexcoarser, smoothrad,[0 10 20], mult);
cortex_hulled = hullModel(cortexsmoothed);
normdist = 45;
[ tala ] = projectElectrodes( cortex_hulled, tala, normdist);
disp('done');

kernel = 'linear';
param = 10;
cutoff = 10;

disp('Calculating dummy contributions... ')
[vcontribs ] = electrodesContributions( cortex, tala, kernel, param, cutoff);
disp('done');
disp(' ');
disp(' ');
save(fullfile(workspace_path,'electrode_locations.mat'),'elecMatrix','elecMatrix_projected');

end

