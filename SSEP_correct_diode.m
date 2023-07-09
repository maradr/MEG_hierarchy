function [ cfg , diode] = SSEP_correct_diode( cfg )
% CIMEC_CORRECT_DIODE Corrects the trl structure taking into account the
% photodiode.
%
% Call this function as:
%     cfg = obob_correct_diode(cfg)
%
% where cfg is the configuration structure returned by ft_definetrial
% extended by these parameters:
%
% cfg.diode.triggers       = Triggers to correct. (i.e. [1 3 5 7] will
%                            search for occurences of these 4 triggers and
%                            then search for photodiode onset afterwards
%                            and correct the trl entries of those).
%
% cfg.diode.blackonwhite   = Set to true, when you have a white background
%                            and stimulus onset is marked with a black
%                            square. Set to false if you have a black
%                            background and stimulus onset is marked by a
%                            white square. (default = true)
%
% cfg.diode.channel        = The name of the photo diode channel. (default
%                            = 'MISC005')
%
% cfg.diode.lpfreq         = Cutoff frequency for the lowpass filter.
%                            (default = 10)
%
% cfg.diode.tolerance      = Timearea to search for diode onset after
%                            trigger onset (i.e. the maximum delay) in seconds.
%                            (default = 0.1)
%                            Note: if you set a negative value here this
%                            function will look for a diode onset BEFORE
%                            the trigger

% Copyright (c) 2012-2016, Thomas Hartmann
%
% This file is part of the obob_ownft distribution, see: https://gitlab.com/obob/obob_ownft/
%
%    obob_ownft is free software: you can redistribute it and/or modify
%    it under the terms of the GNU General Public License as published by
%    the Free Software Foundation, either version 3 of the License, or
%    (at your option) any later version.
%
%    obob_ownft is distributed in the hope that it will be useful,
%    but WITHOUT ANY WARRANTY; without even the implied warranty of
%    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%    GNU General Public License for more details.
%
%    You should have received a copy of the GNU General Public License
%    along with obob_ownft. If not, see <http://www.gnu.org/licenses/>.
%
%    Please be aware that we can only offer support to people inside the
%    department of psychophysiology of the university of Salzburg and
%    associates.

% do some initialization...
%ft_defaults
%ft_preamble help
%ft_preamble provenance
ft_preamble trackconfig

% check cfg...
ft_checkconfig(cfg.diode, 'triggers', 'required');
cfg.diode.channel = ft_getopt(cfg.diode, 'channel', 'MISC005');
cfg.diode.lpfreq = ft_getopt(cfg.diode, 'lpfreq', 40);
cfg.diode.tolerance = ft_getopt(cfg.diode, 'tolerance', .1);
cfg.diode.blackonwhite = ft_getopt(cfg.diode, 'blackonwhite', true);
trlold = cfg.trl;

% check for negative tolerance value and if so print warning
if cfg.diode.tolerance < 0 
  warning('obob_ownft:negative_diode_tolerance', ['You defined a negative tolerance value, '...
    'that means you are looking for a diode onset BEFORE the trigger.\nIs that your intention?'])
end

% read header...
hdr = ft_read_header(cfg.headerfile, 'headerformat', cfg.headerformat);
[sel1, channr] = match_str(cfg.diode.channel, hdr.label);

% read in the raw data from the diode channel
diode = ft_read_data(cfg.dataset, 'header', hdr, 'chanindx', channr, 'dataformat', cfg.dataformat, 'headerformat', cfg.headerformat);

% apply lowpass filter
diode = ft_preproc_lowpassfilter(abs(diode), hdr.Fs, cfg.diode.lpfreq);

% the rest of the function assumes a black background and a white marker appearing on the screen.
% if this is not the case, we turn the signal around.
if cfg.diode.blackonwhite == 1
  diode = abs(max(diode) - diode);
end %if

% the detection threshold for the diode signal will be in the middle between the highest and lowest values.
% these are to be restricted between the first and last trial because you might have a different
% luminance outside of your experiment.

%diode_max = max(diode(cfg.trl(1, 1):cfg.trl(end, 1)));
%diode_min = min(diode(cfg.trl(1, 1):cfg.trl(end, 1)));
%diode_middle = mean([diode_max diode_min]);
limit     = median(diode)+(std(diode)/2);

%METHOD 1
% create a binary mask: 1 -> stimulus present
diode_tmp = diode >= limit; % before >= limit

% find out, when it changes to get the onset.
flanks_samples = find(diff(diode_tmp) > 0); 

% convert to seconds
flanks_time = flanks_samples / hdr.Fs;

% %METHOD 2
% % find peak using signal processing toolbox function
% [~,peak_time] = findpeaks(diode, 'MinPeakWidth',cfg.on_off_distance*hdr.Fs, 'MinPeakHeight',limit);
% peak_time = peak_time/hdr.Fs;
% 
% % Check the difference between the two methods
% 
% detection = [peak_time' flanks_time'];
% for i = 1:length(detection)
%     detection(i,3) = detection(i,1)-detection(i,2); 
% end
% 
% flk = zeros(1,length(diode));
% pek = zeros(1,length(diode));
% flk(flanks_samples) = 1;
% pek(peak_time* hdr.Fs) = 1;
% 
% plot(diode(1:200000),'k')
% hold on
% plot(flk(1:200000),'b')
% plot(pek(1:200000),'g')


not_corrected = 0;

% iterate over all trl entries and look for those we can correct...
trl = cfg.trl;
for i=1:size(cfg.trl,1)
    % check whether we shall correct this trigger
    if ~any(cfg.trl(i, 4) == cfg.diode.triggers)
        warning('no triggers were found in the cfg')
        continue;
    end %if
    
    % find current trigger time
    starttime = (cfg.trl(i, 1) - cfg.trl(i, 3)) / hdr.Fs;
    % calculate difference between trigger and stim onset
    difference_in_time = flanks_time - starttime;
    
    if cfg.diode.tolerance < 0
        % if the tolerance is below zero we have to search before the
        % trigger but within the given time interval i.e., larger than that)
        idx = find((difference_in_time) < 0 & difference_in_time >= cfg.diode.tolerance);
        shift = max(difference_in_time(idx));
    else
        idx = find((difference_in_time) > 0 & (difference_in_time) < cfg.diode.tolerance);
        shift = min(difference_in_time(idx));
    end

    if isempty(idx) % nothing to correct
        not_corrected = not_corrected + 1;
        continue;
    end %if
    
    fprintf('Shifting trigger number %d by %dmsec from %f to %f.\n', i, int16(shift*hdr.Fs), starttime, flanks_time(idx));
    trl(i, 1) = flanks_samples(idx) + cfg.trl(i, 3);
    trl(i, 2) = cfg.trl(i, 2) + shift*hdr.Fs;
end %for

fprintf('Correction failed for %d triggers...\n', not_corrected);

if cfg.show
    figure
    for z = 1:size(trl,1)
        subplot(size(trl,1), 1, z)
        h = plot(linspace(trl(z,1) / hdr.Fs, (trl(z,1)+2000)/hdr.Fs, length(trl(z,1):trl(z,1)+2000)), ...
            diode(1,trl(z,1):trl(z,1)+2000), 'k');
        hold on
        myvline((trlold(z,1) - trlold(z,3)) / hdr.Fs, 'r')
        myvline((trl(z,1) - trl(z,3)) / hdr.Fs, 'g')
        xlim([trl(z,1)/hdr.Fs+abs(trl(1,3)/3)/hdr.Fs (trl(z,1)+2000)/hdr.Fs])
    end
    xlabel('Time (sec)', 'FontSize', 12);
    subplot_title('Photodiode correction - red: old time; green: corrected time');
end
end

function [ax,h]=subplot_title(text)
%Centers a title over a group of subplots.
ax=axes('Units','Normal','Position',[.075 .075 .88 .88],'Visible','off');
set(get(ax,'Title'),'Visible','on', 'FontSize', 15)
title(text);
if (nargout < 2)
    return
end
h=get(ax,'Title');
end

function myvline(x, color)
    y=get(gca,'ylim');
    plot([x x],y, color, 'LineWidth', 2);
end



