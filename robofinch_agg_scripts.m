function robofinch_sound_score(DIR,varargin) 

if nargin<1 | isempty(DIR), DIR=pwd; end

%%%% recurse through all sub-directories, looking for files to process

%
%
% defaults
%

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs');
end

max_depth=7; % how many levels of sub-directories to search through
max_date=inf;

% sound scoring parameters, make sure these match your template

parameter_file='robofinch_parameters.txt';
clust_ext='roboextract';
extract_dir='roboaggregate';
extract_file='roboaggregate.mat';
extract_marker='robofinch_aggtrigger';

% scan for intan_frontend files, prefix songdet1

for i=1:2:nparams
	switch lower(varargin{i})
		case 'max_depth'
			max_depth=varargin{i+1};
		case 'file_ext'
			file_ext=varargin{i+1};
		case 'filename_filter'
			filename_filter=varargin{i+1};
		case 'filename_exclude'
			exclude=varargin{i+1};
		case 'recurse_files'
			recurse_files=varargin{i+1};
		case 'extract_marker'
			extract_marker=varargin{i+1};
	end
end

% clusters all files that can be scored

disp('Collecting files...');
all_files=robofinch_dir_recurse(DIR,extract_marker,max_depth,max_date);

% load parameters and run all scripts on aggregated data

for i=1:length(uniq_dirs)


	% todo, integrate fluolab script, almost there...

end



