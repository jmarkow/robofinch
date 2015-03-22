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

max_depth=inf; % how many levels of sub-directories to search through
max_date=inf;

% sound scoring parameters, make sure these match your template

parameter_file='robofinch_parameters.txt';
extract_file='roboaggregate.mat';
extract_marker='robofinch_aggtrigger';
script_dir='agg_scripts';

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

disp('Collecting files...');
all_files=robofinch_dir_recurse(DIR,extract_file,max_depth,max_date);

% load parameters and run all scripts on aggregated data

for i=1:length(all_files)
	[path,file,ext]=fileparts(all_files(i).name);
	disp(['Tagging:  ' path]);
	fid=fopen(fullfile(path,extract_marker),'w');
	fclose(fid);
end




