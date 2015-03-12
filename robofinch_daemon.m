function robofinch_daemon(DIR,varargin) 
%
%
%

if nargin<1, DIR=pwd; end

while 1==1
	robofinch_sound_score(DIR,varargin{:});
	robofinch_sound_clust(DIR,varargin{:});
	robofinch_agg_data(DIR,varargin{:});
end

