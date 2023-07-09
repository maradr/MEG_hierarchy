%% BF for Suff vs HFE
% upload each experimental and its baseline
% pick only the data of interest (vertices, frequency band(s), sensors)
% save structure with relevant info and TXT - and at source, also the
% summary of the stats per ROI

% SL26 - SISSA+CIMeC FPVS_morphemes, July 2021
clear all; close all; clc

%% sensor level BF
SetPaths;


files = dir([freq_dir 'grand_average_condition*.mat']);
for i = 1:length(files)
    load(files(i).name);
end
%
load grad % general coordinates
load grad_cmb % coordinates for combined gradiometers

for looping = 1:5
    condition_code1         = looping;            % 1 - 10
    condition_code2         = looping + 5;            % 0 - 10
    freq_of_interest        = 'odd';        % 'odd 'or 'base
    % 'meggrad' or 'megmag'
    har = 1;
   
        %% Compute empirical frequency based on refresh rates
        
        cfg = [];
        cfg.refresh_rate = 120;
        cfg.nominal_base_frequency = 6;
        cfg.directory = behav_dir;
        [true_base_frequency, true_oddball_frequency] = SSEP_compute_exact_frequency(cfg);
        
        
        eval(['dataset_1 = grand_average_condition' num2str(condition_code1) ';']);
        
        if condition_code2 ~= 0
            eval(['dataset_2 = grand_average_condition' num2str(condition_code2) ';'])
        else
            eval(['dataset_2 = grand_average_condition' num2str(condition_code1) ';']);
            dataset_2.BC = zeros(size(dataset_1.BC));
        end
        
        %% set output
        output_name = ['BFanalysis_Sensors_' num2str(condition_code1) 'vs' num2str(condition_code2) '.txt'];
        fileID = fopen(output_name,'w');
        fprintf(fileID, 'Bayesian Analysis at Sensor Level\n');
    for sensor = 1:2
            
            if sensor == 1
                sensor_type             = 'meggrad';
            else
                sensor_type             = 'megmag';
            end
            
        %% Subset data according to the parameters (frequency, sensors)
        
        cfg = [];
        if strcmpi(freq_of_interest, 'odd')
            cfg.frequency = true_oddball_frequency*har;
        elseif strcmpi(freq_of_interest,'base')
            cfg.frequency=true_base_frequency;
        end
        cfg.channel = sensor_type;
        
        dataset_1 = ft_selectdata(cfg, dataset_1);
        dataset_2 = ft_selectdata(cfg, dataset_2);
        
        %% Combine gradiometers (depending on sensor type)
        
        if strcmpi(sensor_type, 'meggrad')
            dataset_1 = SL26_combineplanarAVG(dataset_1);
            dataset_2 = SL26_combineplanarAVG(dataset_2);
        end
        
        [~,~,~,stats] = ttest(dataset_1.BC,dataset_2.BC);
        [h,p] = ttest(dataset_1.BC,dataset_2.BC);
        bf10 = nan(size(dataset_1.label));
        
        for channel = 1:length(dataset_1.label)
            bf10(channel) = t1smpbf(stats.tstat(channel),size(dataset_1.BC,1)); % Script originally writen by Sam Schwarzkopf (Twitter: @sampendu)
        end
        
        clc
        positive_BFs = find(bf10>3);
        fprintf(fileID, ['Sensor Type: ' sensor_type '\n']);
        fprintf(fileID, 'Channels with BF10 > 3: %2.f\n',numel(positive_BFs));
        positive_BFs = find(bf10<1/3);
        fprintf(fileID, 'Channels with BF10 < 1/3: %2.f\n',numel(positive_BFs));
        
        
    end
    
    fclose(fileID);
end

clear all; close all; clc
SetPaths;

%% source level BF

for looping = 1:5
    which_condition_to_test = looping; % 1= NW in PF; 2 = PW in NW; 3 = HFE in PW; 4 = SUFF in HFE; 5 = W in SUFF
    cd(sources_dir)
    
    condition_code1         = which_condition_to_test;            % 1 - 10
    condition_code2         = which_condition_to_test +5;            % 0 - 1:10
    freq_of_interest        = 'odd';        % 'odd 'or 'base
    har = 1;%1:2:5;
    
    %% load files
    
    
    load(['C' num2str(condition_code1) '.mat']);
    eval(['C' num2str(condition_code1) '= BC;']);
    
    load(['C' num2str(condition_code2) '.mat']);
    eval(['C' num2str(condition_code2) '= BC;']);
    
    
    
    % ROIs and Neighbours
    load ROIs; load worldNeighbours
    
    
    %% Compute empirical oddball frequency based on refresh rate
    
    cfg = [];
    cfg.refresh_rate = 120; % bin width 0.361
    cfg.nominal_base_frequency = 6;
    cfg.directory = behav_dir;
    [true_base_frequency, true_oddball_frequency] = SSEP_compute_exact_frequency(cfg);
    
    fI = true_oddball_frequency*har';
    [~,odd_bin] = min(abs(repmat(Freqs,[length(fI),1]) - repmat(fI,[1,length(Freqs)])),[],2);
    
    %% set output
    output_name = ['BFanalysis_Sources_' num2str(condition_code1) 'vs' num2str(condition_code2) '.txt'];
    fileID = fopen(output_name,'w');
    fprintf(fileID, 'Bayesian Analysis on ROIs, source level - single vertices\n');
    
    
    %% set up file for fieldtrip
    
    for roi = 1:length(ROIs)
        
        % select vertices for a specific ROI
        vertices = ROIs(roi).iVertices;
        presentROI = ROIs(roi).Label;
        number_of_vertices = length(vertices);
        
        output_name_stats = [ strrep(presentROI,' ','') '_BFanalysis_' num2str(condition_code1) 'vs' num2str(condition_code2)];
        eval(['temp = C' num2str(condition_code1) ';']);
        temp = temp(vertices,:,odd_bin);
        
        dataset_1.BC =  permute(temp,[2 1 3]); % sort dimensions
        dataset_1.freq = Freqs(odd_bin);
        dataset_1.label = cellstr(string(vertices));
        dataset_1.dimord = 'subj_chan_freq';
        clear temp
        
        
        eval(['temp = C' num2str(condition_code2) ';']);
        
        temp = temp(vertices,:,odd_bin);
        dataset_2.BC =  permute(temp,[2 1 3]); % sort dimensions
        dataset_2.freq = Freqs(odd_bin);
        dataset_2.label =cellstr(string(vertices));
        dataset_2.dimord = 'subj_chan_freq';
        clear temp
        
        [~,~,~,stats] = ttest(dataset_1.BC,dataset_2.BC);
        [h,p] = ttest(dataset_1.BC,dataset_2.BC);
        bf10 = nan(number_of_vertices,1);
        
        for channel = 1:number_of_vertices
            bf10(channel) = t1smpbf(stats.tstat(channel),size(dataset_1.BC,1)); % Script originally writen by Sam Schwarzkopf (Twitter: @sampendu)
        end
        
        clc
        positive_BFs = find(bf10>3);
        fprintf(fileID, ['ROI: ' presentROI  ', number of vertices: ' num2str(number_of_vertices) '\n']);
        fprintf(fileID, 'Vertices with BF10 > 3: %2.f\n',numel(positive_BFs));
        positive_BFs = find(bf10<1/3);
        fprintf(fileID, 'Vertices with BF10 < 1/3: %2.f\n',numel(positive_BFs));
        
        
        save(fullfile(output_name_stats), 'bf10')
        
    end
    
    
    fclose(fileID);
    
end

