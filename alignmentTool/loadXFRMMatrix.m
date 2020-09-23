function [xfrm_matrices] = loadXFRMMatrix(workspace_path,pathToFsInstallDirectory,fs_subj_dir)
%LOADXFRMMATRIX Summary of this function goes here
%   Detailed explanation goes here
wspace_dir=dir(workspace_path);

    

if(~any(contains({wspace_dir.name},'xfrm_matrices')))

    disp('To correctly convert Freeview data point coordinates, the MRI used by freeview or the tranformation matrix is required!');
    if(nargin < 3)
    [freesurfer_file,freesurfer_file_path ]= uigetfile('*.mgz','Original Brain Model');
    else
        if(exist(fullfile(fs_subj_dir,'mri/orig.mgz'),'file') ~= 0)
            disp('Found MRI in freesurfer segmentation folder!')
            freesurfer_file_path=fullfile(fs_subj_dir,'mri/');
            freesurfer_file='orig.mgz';
            
        else
            disp('Could not find orig.mgz in freesurfer path, please specify MRI data');
            [freesurfer_file,freesurfer_file_path ]= uigetfile('*.mgz','Original Brain Model');
        end
    end
    shellcommand = ['./get_xfrm_matrices.sh ' pathToFsInstallDirectory ' ' fullfile(freesurfer_file_path,freesurfer_file) ' '  workspace_path '&'];
    system(shellcommand);
    pause(3);
    wspace_dir=dir(workspace_path);
    if(~any(contains({wspace_dir.name},'xfrm_matrices')))
        error('xfrm matrices script failed: Make sure that the get_xfrm_matrices.sh script has execution permission... run: chmod +x get_xfrm_matrices.sh');
    end
else
    disp('loaded xfrm matrix from workspace directory!');
end

xfrm_matrices = importdata(fullfile(workspace_path,'xfrm_matrices'));
end

