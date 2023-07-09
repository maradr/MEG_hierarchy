function [true_base_frequency, true_oddball_frequency] = SSEP_compute_exact_frequency(cfg)
prev_folder = pwd;
cd(cfg.directory)
all_files = dir('*.mat');


true_base_frequency = nan(length(all_files),1);
true_oddball_frequency  = nan(length(all_files),1);

for subject = 1:length(all_files)
    load(all_files(subject).name);
    
    df    = diff(E.Screen.vblBlocks,1,2); % compute inter-flip interval
    timeW = E.Screen.vblBlocks(:,1:(cfg.refresh_rate/cfg.nominal_base_frequency):end);
    timeT = timeW(:,2:2:end);
    
    dfw = diff(timeW,1,2);
    dft = diff(timeT,1,2);    
   % delay = sum(df(2:end) > (1/refresh_rate)+0.0001); % Test for frame delays. First frame is ignored as is usually delayed
   % if any(delay); disp(['Participant ',all_files(subject).name,' has ',num2str(delay),' delayed frames.']); end
    
    true_base_frequency(subject) = 1/nanmean(dfw(:));
    true_oddball_frequency(subject) = 1/nanmean(dft(:));
end

%%
true_base_frequency = mean(true_base_frequency);
true_oddball_frequency = mean(true_oddball_frequency);

display(['Empirical Base Frequency = ',num2str(true_base_frequency),' Empirical Oddball Frequency = ',num2str(true_oddball_frequency)]);
cd(prev_folder);
end