%% Frequency analysis
% Upload subject-wise average of trials per condition to run FFT. 
% Then compute baseline corrected amplitude for all frequency bins in all
% channels considering a window of 20 (from which we'd exclude local maxima
% and minima, and immediately adjecent bins). 
% Save grandaveraged data

% M. De Rosa
% SL26 - SISSA+CIMeC Entrainment to regularities, Jan 2021

clear all; close all; clc;
SetPaths;

%% Load files 
files = dir('avg\cond*.mat');
for i = 1:length(files)
    load(files(i).name)
end

%% Frequency Analysis
cd(freq_dir)

for condition_code = 1:length(files) % For each condition   
    within_sbj_average = eval(['cond' num2str(condition_code)]);
           
    %%  FFT on Subject-wise average of trials  
    for s = 1:length(within_sbj_average)
        %% Set parameters
        cfg           = [];
        cfg.channel   = {'MEG'}; 
        cfg.method    = 'mtmfft'; 
        cfg.taper     = 'hanning';
%       cfg.output    = 'fourier';
        subject       = within_sbj_average{s};
        
        frequency_temp{s}    = ft_freqanalysis(cfg,subject); % does not have "time" as a field because we considered the entire length of each trial.
        power                = frequency_temp{s}.powspctrm;
        frequency_temp{s}.BC = zeros(size(power));
        
        % compute baseline corrected amplitude for each frequency bin in all channels
        for channel = 1:size(power,1)
            for frequency_bin = 12:length(power)-12
                neighborhood                                    = power(channel,[frequency_bin-11:frequency_bin-2,frequency_bin+2:frequency_bin+11]); % surrounding bins, excluding adjacent
                [~, idmin]                                      = min(neighborhood);
                [~, idmax]                                      = max(neighborhood);
                neighborhood([idmin,idmax])                     = [];
                frequency_temp{s}.BC(channel,frequency_bin)     = power(channel,frequency_bin) - mean(neighborhood);
            end
        end        
    end
    
    
    %% Save outputs
    % Grandaveraged data
    cfg = [];
    cfg.parameter      = 'BC';
    cfg.keepindividual = 'yes';  
    grand_average_temp = ft_freqgrandaverage(cfg, frequency_temp{:});
    eval(['grand_average_condition' num2str(condition_code) ' = grand_average_temp;']);
    save(['grand_average_condition' num2str(condition_code)], ['grand_average_condition' num2str(condition_code)]);
    
       
    %% clear workspace
    eval(['clear freqency_band frequency_temp  grand_average_temp frequency_' num2str(condition_code) ' grand_average_condition' num2str(condition_code)]);
    clc
end