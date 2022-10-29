% ----------------------------------------------------------------------------------------------
% -- Title       : VocalMat
% -- Project     : VocalMat - A Tool for Automated Mouse Vocalization Detection and Classification
% ----------------------------------------------------------------------------------------------
% -- File        : VocalMat.m
% -- Group       : Dietrich Lab - Department of Comparative Medicine @ Yale University
% -- Standard    : <MATLAB 2018a>
% ----------------------------------------------------------------------------------------------
% -- Copyright (c) 2020 Dietrich Lab - Yale University
% ----------------------------------------------------------------------------------------------

clear all

user_settings = struct;
% ----------------------------------------------------------------------------------------------
% -- USER DEFINED PARAMETERS
% ----------------------------------------------------------------------------------------------
% ----------------------------------------------------------------------------------------------
% -- VocalMat Identifier
% ----------------------------------------------------------------------------------------------
% -- save the output from the identifier, in case you only want to rerun the classifier
user_settings.save_output_files = 0;
% -- max_interval: maximum allowed interval between points to be considered part of one vocalization
user_settings.max_interval = 20;
% -- minimum_size: minimum number of points to be considered a vocalization
user_settings.minimum_size = 6;
% ----------------------------------------------------------------------------------------------
% -- VocalMat Classifier
% ----------------------------------------------------------------------------------------------
% -- 0 = off; 1 = on.
user_settings.save_plot_spectrograms    = 0; % plots the spectograms with axis
user_settings.save_excel_file           = 1; % save output excel file with vocalization stats
user_settings.save_summary_excel        = 1; % saves all samples classification to Excel
user_settings.scatter_step              = 3; % plot every third point overlapping the vocalization (segmentation)
user_settings.axes_dots                 = 1; % show the dots overlapping the vocalization (segmentation)
user_settings.bin_size                  = 300; % in seconds

disp('[vocalmat]: starting VocalMat.')
% -- add paths to matlab and setup for later use
appinfo = struct;
appinfo.root_path       = fileparts(mfilename('fullpath')); %Set this path to VocalMat's root folder
appinfo.classifier_path = fullfile(appinfo.root_path, 'vocalmat_classifier');
appinfo.analysis_path = fullfile(appinfo.root_path, 'vocalmat_analysis');
appinfo.gui.fig = uifigure('visible', 'off');
addpath(genpath(appinfo.root_path));

try
    % -- check for updates
    vocalmat_github_version = strsplit(webread('https://github.com/ahof1704/VocalMat/raw/master/README.md'));
    vocalmat_github_version = vocalmat_github_version{end-2};
    vocalmat_local_version  = strsplit(fscanf(fopen(fullfile(appinfo.root_path,'README.md'), 'r'), '%c'));
    vocalmat_local_version  = vocalmat_local_version{end-2};
    if ~strcmp(vocalmat_local_version, vocalmat_github_version)    

        opts.Interpreter = 'tex';
        opts.Default     = 'Continue';
        btnAnswer        = questdlg('There is a new version of VocalMat available. For more information, visit github.com/ahof1704/VocalMat', ...
                                    'New Version of VocalMat Available', ...
                                    'Continue', 'Exit', opts);
        switch btnAnswer
            case 'Exit'
                error('[vocalmat]: there is a new version of VocalMat available. For more information, visit our <a href="https://github.com/ahof1704/VocalMat/tree/master">GitHub page</a>. ') 
            case 'Continue'
                warning('[vocalmat]: there is a new version of VocalMat available. For more information, visit our <a href="https://github.com/ahof1704/VocalMat/tree/master">GitHub page</a>. ') 
        end
    end
catch
    % -- could not check for updates
    disp('[vocalmat]: checking for updates failed. Verify if you have internet connection.');
end

disp('[vocalmat]: choose the audio file to be analyzed.');
[appinfo.vfilename_arr,appinfo.vpathname] = uigetfile({'*.wav'},'Select the sound track', 'MultiSelect', 'on');
appinfo.vfilename_arr = cellstr(appinfo.vfilename_arr);
appinfo.summary_excel = "";
appinfo.gui.fig.Visible = 'on';
appinfo.gui.progressbar = uiprogressdlg(appinfo.gui.fig,'Title','Please wait','Cancelable','on');

for filei=1:length(appinfo.vfilename_arr)
	appinfo.gui.progressbar.Value = filei/length(appinfo.vfilename_arr);
	appinfo.gui.progressbar.Message = strcat("Processing ", appinfo.vfilename_arr{filei});
	disp(fullfile(appinfo.vpathname, appinfo.vfilename_arr{filei}))
	vfilename = appinfo.vfilename_arr{filei};
	% -- handle execution over to the identifiehoor
	disp(['[vocalmat]: starting VocalMat Identifier...'])
	run('vocalmat_identifier.m')

	% -- handle execution over to the classifier
	disp(['[vocalmat]: starting VocalMat Classifier...'])
	run('vocalmat_classifier.m')

	% -- handle execution over to the diffusion maps
	disp(['[vocalmat]: starting VocalMat Analsyis...'])
	sigma=0.5;
	t=2; % diffusion coefficient
	m=3; % dimension of embedded space
	plot_diff_maps=1; % 1: plot embedding, 0: do not plot
	% cd(appinfo.analysis_path); run('diffusion_maps.m')

	% -- (optional) handle execution over to the diffusion maps and performs alignment for
	% two groups defined by the variable 'keyword'
	% work_dir = 'path_to_folder_with_groups_to_be_compared';
	% keyword{1} = 'Control'; keyword{2} = 'Treatment'; % tags for the groups
	% cd(appinfo.analysis_path); run('kernel_alignment.m')
    clearvars -except user_settings appinfo
	close all
	if appinfo.gui.progressbar.CancelRequested
		break
    end
end

close(appinfo.gui.progressbar);
close(appinfo.gui.fig)
disp(['[vocalmat]: finished!'])
