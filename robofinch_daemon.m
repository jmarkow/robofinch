function robofinch_daemon(DIR,varargin) 
%
%
%

interval=300;
skip{1}='mat_ttl'; % skip these directories
skip{2}='MANUALCLUST';

if nargin<1, DIR=pwd; end

while 1==1
	robofinch_sound_score(DIR,varargin{:},'skip',skip);
	robofinch_sound_clust(DIR,varargin{:},'skip',skip);
	robofinch_agg_data(DIR,varargin{:},'skip',skip);
	robofinch_agg_scripts(DIR,varargin{:},'skip',skip);
	pause(interval);
end

