function [trl] = SSEP_TrialFuntion_StimCond_VIS(cfg)

% always express as positive numbers
cfg.trialdef.pre  = 1; %determine the starting point of your epoches
cfg.trialdef.post = 26.7; %determine the ending point of your epoches

% read the header information and the events from the data
hdr   = ft_read_header(cfg.dataset); %reads header information from MEG files and represents the header information in a common data-independent format.
event = ft_read_event(cfg.dataset); %reads all events from an MEG dataset and returns them in a well defined structure. 

% search for "trigger" events
value  = [event(find(strcmp('STI101',{event.type}))).value]'; %it takes the trigger values
sample = [event(find(strcmp('STI101',{event.type}))).sample]'; %it takes the samples

% %% Sanity check, we want to check if onset and offset of trials is constant
% index_begin  = find(value == 11 | value == 21 | value == 31 | ...
%     value == 41 | value == 51 | value == 61| value == 71 ...
%     | value == 81 | value == 91 | value == 101);
% 
% index_end  = find(value == 10 | value == 20 | value == 30 | ...
%     value == 40 | value == 50 | value == 60 | value == 70 ...
%     | value == 80 | value == 90 | value == 100);

% %% Sanity check for trial duration 
% % for sanity_check = 1:length(index_begin)
%     
%     trial_duration(sanity_check) = sample(index_end(sanity_check))-sample(index_begin(sanity_check));
%     
% end

% now all the index that we need for trial definition
% here it takes the trigger codes of interest
index  = find(value == 253 | value == 11 | value == 21 | value == 31 | ...
    value == 41 | value == 51 | value == 61 | value == 71 ...
    | value == 81 | value == 91 | value == 101); 

% Wee have 10 conditions (5 experimental and 5 control). 
% The trial starting is indicated with: 
% 11 (Cond 1), 21 (Cond 2), 31 (Cond 3), 41 (Cond 4), 51 (Cond 5), 61 (Cond
% 6), 71 (Cond 7), 81 (Cond 8), 91 (Cond 9), 101 (Cond 10).
% The trial ending is indicated with: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 (also here
% related to the condition number).
% Trigger '253' refers to the button press.

% determine the number of samples before and after the trigger
pretrig  = -round(cfg.trialdef.pre  * hdr.Fs);
posttrig =  round(cfg.trialdef.post * hdr.Fs);

trl = [];
trl_all = [];

for j = 1:length(index)  %index contains info about the positions of triggers of interest
    
    stim_on1    = value(index(j));
    trlbegin    = sample(index(j)) + pretrig;
    trlend      = sample(index(j)) + posttrig;
    offset      = pretrig;
    
    newtrl   = [trlbegin trlend offset stim_on1];
    trl_all  = [trl_all; newtrl];
    
end

% this will change the values in those subjects where we have extra triggers
% sends two triggers in rapid (1 ms) succession
if all(diff(trl_all(:,2)) > 1)
    disp('all fine')
else
    sample_index = diff(trl_all(:,2));
    index_wrong=find(sample_index <= 1);
    disp('more triggers than expected')
    trl_all(index_wrong,:) = [];
    
end

%% define trials as two consecutive triggers
idx = find(trl_all(:,4)<102); 
%Here, you have to put all trigger related to the beginning of each trials 
%If condition are 10: you put <102 because the triggers related to the beginning are 
%11, 21, 31, 41, 51, 61, 71, 81, 91, 101 for each of the ten conditions. 

idx = [idx; length(trl_all)];

for j = 1:length(idx)-1

    count_resp = sum(trl_all(idx(j):idx(j+1),4) == 253);
    corr = (count_resp == 3); %determine here the correct number of responses to button press (the color changes 3 times for each trial).    
    new_trl_all = [trl_all(idx(j),:) count_resp corr];
    trl = [trl; new_trl_all];
    
end

trl(:,7) = cfg.block; %block

end