%% Preprocessing
% Create a subfolder for each subject
% Define trials (onset = 1 - offset = 0) for ech condition (1 to 10)
% Gather info from photodiode, tracking half cycle (166ms/2)
% General filtering (HP= 0.1Hz, LP=100Hz)
% Specific filtering for eye movements and heartbit (in separated
% cell-arrays)
% Realign trials based on the photodiode
% Downsaple to 250Hz and save the outputs (3 x subject)

% M. De Rosa
% SL26 - SISSA+CIMeC Entrainment to regularities, Jan 2021


clear all; close all; clc;
SetPaths

for i =1:length(fif_folders) %loop across participants
    sbj_name                = fif_folders(i); % create ad-hoc folder
    dirname                 = strcat(preproc_dir,sbj_name.name);
    
    if exist(dirname, 'dir') == 0
        mkdir(dirname); %create the directory with all the files of this subject
        addpath(dirname)%add the directory to the path
    else
        disp('----------------------------------------------------------')
        prompt = 'Subject directory already exists. Do you want to continue? [Y/N]';
        s = input(prompt, 's');
        
        if isempty(s) || strcmpi(s,'y')
            disp(' ')
            disp('OK, continuing')
        else 
            disp(' ')
            disp('Stopping')            
            return           
        end        
    end
      
   
    cd(strcat(fif_dir,fif_folders(i).name)); %move into folder of single subject
    sbj = dir('*.fif');%how many fif files are in it?
    
    %% Trial definition    
    for k = 1:length(sbj)       
        %Read events
        cfg                     = [];
        cfg.dataset             = sbj(k).name;
        cfg.block               = k;
        cfg.fif_dir             = fif_dir;
        cfg.eventformat         = 'neuromag_fif';
        cfg.trialdef.eventtype  = 'STI101';
        cfg.trialfun            = strcat('SSEP_TrialFuntion_StimCond_VIS'); %%Trial function
        cfg                     = ft_definetrial(cfg);
        
        %% Correct photodiode               
        cfg.diode               = cfg;
        cfg.diode.triggers      = cfg.trl(:,4);
        cfg.show                = 0;
        cfg.diode.blackonwhite  = 1;
        cfg.diode.channel       ='MISC008'; %diode channel
        cfg.diode.tolerance     = .15;
        cfg.diode.dataformat    = 'meg';
        [tmp,diode]             = SSEP_correct_diode(cfg);        
        
        %% HP and LP filtering
        % HP is already subsumed under MaxFilter, but for the sake of it
        % we're launching it again here.
        cfg                     = [];
        cfg.dataset             = sbj(k).name;
        cfg.continuous          = 'yes';
        cfg.hpfilter            = 'yes';
        cfg.hpfreq              = 0.1;
        cfg.hpfiltord           = 1;
        cfg.lpfilter            = 'yes';
        cfg.lpfreq              = 100;
        %filter all channels
        data_all                = ft_preprocessing(cfg);
        
        %% Separate MEG, EOG and ECG channels
        cfg                    = [];
        cfg.channel            = {'MEG'}; % 306 channels
        data_raw               = ft_selectdata(cfg,data_all);
        % EOG
        cfg                    = [];
        cfg.channel            = {'EOG061', 'EOG062'};
        data_EOG               = ft_selectdata(cfg,data_all);
        cfg                    = [];
        cfg.bpfilter           = 'yes';
        cfg.bpfreq             = [1 15];
        data_EOG               = ft_preprocessing(cfg,data_EOG);   
        % ECG - Here coded as EOG63
        cfg                    = [];
        cfg.channel            = {'EOG063'};
        data_ECG               = ft_selectdata(cfg,data_all); 
        cfg                    = [];
        cfg.lpfilter           = 'yes';
        cfg.lpfreq             = 10;
        data_ECG               = ft_preprocessing(cfg,data_ECG);       
        clear data_all
        
        %% Redefine trials (based on diode rialignment output)
        cfg                 = [];
        cfg.trl             = tmp.trl; %tmp_trial is file to redefine trials in raw_data file
        data_raw            = ft_redefinetrial(cfg, data_raw);
        data_EOG            = ft_redefinetrial(cfg, data_EOG);
        data_ECG            = ft_redefinetrial(cfg, data_ECG);
        
        %% Downsample the data rate
        cfg                 = [];
        cfg.resamplefs      = 250; %frequency at which we are resampling
        cfg.detrend         = 'no';
        
        data_blocks{k}      = ft_resampledata(cfg, data_raw);
        data_blocks_EOG{k}  = ft_resampledata(cfg, data_EOG);
        data_blocks_ECG{k}  = ft_resampledata(cfg, data_ECG);
        clear data_raw data_EOG data_ECG
        
    end %preprocessing blocks
    
    
    %% Append and save
    dirname  = strcat(preproc_dir,sbj_name.name);
    cd(dirname)
    
    data_tot                = ft_appenddata([],data_blocks{:});
    data_tot_EOG            = ft_appenddata([],data_blocks_EOG{:});
    data_tot_ECG            = ft_appenddata([],data_blocks_ECG{:});
    data_tot.cfg            = [];
    
    outputname              = strcat(dirname,'\',sbj_name.name);
    outputnameEOG           = strcat(outputname,'_EOG');
    outputnameECG           = strcat(outputname,'_ECG');
    
    save(outputname,'data_tot','-v7.3')
    save(outputnameEOG,'data_tot_EOG','-v7.3')
    save(outputnameECG,'data_tot_ECG','-v7.3')
    
    clear data_blocks data_blocks_EOG data_blocks_ECG data_tot  
end 

clear all