addpath(genpath('./activeBrain'));
addpath(genpath('./alignmentTool'));
addpath('/Applications/freesurfer/matlab/');


%% Load files
clc;
clearvars;

%% Settings

pathToFsInstallDirectory='/Applications';

%% 
disp('Specify Subject Output Directory (input data will be copied to this folder)');
workspace_path=uigetdir('','Workspace Directory');
wspace_dir=dir(workspace_path);
disp(['Workspace selected: ' workspace_path]);
if(numel(wspace_dir) > 2) 
    warning ('Workspace directory already contains data, to rerun complete script please delete folder content or create a new folder!');
end


if(~any(contains({wspace_dir.name},'orig_brain_model.mat')))
    answer=questdlg('Do you want to load the brain model from a complete .mat or from the freesurfer folder?','What brain model do you want to use?','Load from .mat','Load from Freesurfer','Load from .mat');
    switch(answer)
        case 'Load from Freesurfer'
            [cortex,cmapstruct,ix,tala,vcontribs,viewstruct,brainmodel_path,brainmodel_file]=loadBrainModelfromFreeSurfer(workspace_path,pathToFsInstallDirectory);
        case 'Load from .mat'
   
                disp('Load brain model .mat file');
                [brainmodel_file,brainmodel_path ]= uigetfile('*.mat','Original Brain Model');
                disp(['Loading brain from ' fullfile(brainmodel_path,brainmodel_file)]);
                load(fullfile(brainmodel_path,brainmodel_file));

                if(~(exist('cmapstruct','var') && exist('cortex','var') && exist('ix','var')&& exist('tala','var') && exist('vcontribs','var') && exist('viewstruct','var')))
                    error('Unexpected brain model file content!');
                end
                
        otherwise
            error('Stopped importing brain model!');
    end

    save(fullfile(workspace_path,'orig_brain_model.mat'),'cortex','cmapstruct','ix','tala','vcontribs','viewstruct','brainmodel_path','brainmodel_file');
else
    
    disp('Found brain model file in Workspace folder!');
    load(fullfile(workspace_path,'orig_brain_model.mat'));
end
disp('...done');
disp(' ');
disp(' ');


viewstruct.what2view={'brain','electrodes'};
figure
subplot(1,3,1)
activateBrain(cortex,vcontribs,tala,ix,cmapstruct,viewstruct);
light('Position', -viewstruct.lightpos, 'Style', 'infinite');
title(['Original brain (' fullfile(brainmodel_path,brainmodel_file) ')']);
axis on;
xlabel('x');
ylabel('y');
zlabel('z');

if(~any(contains({wspace_dir.name},'alignment_points.mat')))
    
    disp('Load alignment points folder (contains AC,PC, mid-sag). Alignment folder needs to contain 3 files with one point each');
    alignment_folder= uigetdir(brainmodel_path,'Folder to AC, PC, mid-sag files');
    files = dir(alignment_folder);
    %TODO add the possiblity to load .mat files with correctly projected
    %coordinates

    if(any(contains({files.name},'AC.dat')))
        ac_dat_file=fullfile(alignment_folder,'AC.dat');
    else
        disp('Couldnt find AC.dat, please specify file');
        [fname,path ]= uigetfile('*.*','Load AC point');
        ac_dat_file=fullfile(path,fname);
    end

    if(any(contains({files.name},'PC.dat')))
        pc_dat_file=fullfile(alignment_folder,'PC.dat');
    else
        disp('Couldnt find PC.dat, please specify file');
        [fname,path ]= uigetfile('*.*','Load PC point');
        pc_dat_file=fullfile(path,fname);
    end


    if(any(contains({files.name},'mid-sag.dat')))
        mid_sag_dat_file=fullfile(alignment_folder,'mid-sag.dat');
    else
        disp('Couldnt find mid-sag.dat, please specify file');
        [fname,path ]= uigetfile('*.*','Load mig-sag point');
        mid_sag_dat_file=fullfile(path,fname);
    end


    ac_point=importelectrodes(ac_dat_file);
    pc_point=importelectrodes(pc_dat_file);
    mid_sag_point=importelectrodes(mid_sag_dat_file);

    disp('Successfully loaded alignment points');
    
   xfrm_matrices = loadXFRMMatrix(workspace_path,pathToFsInstallDirectory);

%    move the transform matrices into their own variables
   Norig = xfrm_matrices(1:4, :);
   Torig = xfrm_matrices(5:8, :);

   ac_point   = (Torig*inv(Norig)*[  ac_point(:, 1),   ac_point(:, 2),   ac_point(:, 3), ones(size(ac_point, 1),   1)]')';
   pc_point   = (Torig*inv(Norig)*[  pc_point(:, 1),   pc_point(:, 2),   pc_point(:, 3), ones(size(pc_point, 1),   1)]')';
   mid_sag_point = (Torig*inv(Norig)*[mid_sag_point(:, 1), mid_sag_point(:, 2), mid_sag_point(:, 3), ones(size(mid_sag_point, 1), 1)]')';
    

   ac_point=ac_point(:,1:3);
   pc_point=pc_point(:,1:3);
   mid_sag_point=mid_sag_point(:,1:3);
    
    save(fullfile(workspace_path,'alignment_points.mat'),'ac_point','pc_point','mid_sag_point');

else
    disp('Found alignment points file in Workspace folder!');
    load(fullfile(workspace_path,'alignment_points.mat'))
end

disp('...done');
disp(' ');
disp(' ');

    
disp('Projecting model into talairach space!');
disp(['Initial AC position (x y z): ' num2str(round(ac_point,2))])
disp(['Initial PC position (x y z): ' num2str(round(pc_point,2))])
disp(['Initial mid-sag position (x y z): ' num2str(round(mid_sag_point,2))])

disp('aligning model ...');
answer=input('Which alignment should be performed \n ''none'' = rotation and translation only, \n ''talairach'' = resized according to talairach, \n ''mni'' = projection into talaraich space and transformation from talairach to mni?');

[newcortex,newelectrodes,new_alignment_pos]= projectToStandard(cortex,tala.electrodes,[ac_point;pc_point;mid_sag_point],answer);
disp(['AC position is now at (x y z): ' num2str(round(new_alignment_pos(1,:),2))])
disp(['PC position is now at (x y z): ' num2str(round(new_alignment_pos(2,:),2))])
disp(['mid-sag position is now at (x y z): ' num2str(round(new_alignment_pos(3,:),2))])

disp('...done');
disp(' ');
disp(' ');


newtala=tala;
newtala.electrodes=newelectrodes;

subplot(1,3,2)

cortex=newcortex;
tala=newtala;
activateBrain(newcortex,vcontribs,tala,ix,cmapstruct,viewstruct);
light('Position', -viewstruct.lightpos, 'Style', 'infinite');

save(fullfile(workspace_path,[answer '_aligned_brain_model']),'cortex','tala','ix','cmapstruct','viewstruct');
axis on;
xlabel('x');
ylabel('y');
zlabel('z');
title('Realigned and resized brain');

load('tal_brain/pial_talairach.mat')


subplot(1,3,3)
activateBrain(cortex,vcontribs,newtala,ix,cmapstruct,viewstruct);
light('Position', -viewstruct.lightpos, 'Style', 'infinite');
title('Electrode positions on standard talaraich brain');
axis on;
xlabel('x');
ylabel('y');
zlabel('z');
save(fullfile(workspace_path,[answer '_tal_brain_model']),'cortex','tala','ix','cmapstruct','viewstruct');

disp('Projected electrodes and stored mat files in workspace folder!');



