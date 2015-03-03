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
max_date=4;
file_ext='auto'; % automatically determine file type
filename_filter='songdet1*.mat';
filename_exclude={}; % anything to exclude

% sound scoring parameters, make sure these match your template

score_dir='syllable_data'; %
score_ext='_score'; % 

parameter_file='robofinch_parameters.txt';

recurse_files(1).field='config';
recurse_files(1).filename=parameter_file;

%clust_dir_ext='_roboextract'; % add to cluster directory so we know it's been auto-clustered

clust_ext='roboextract';

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
		case 'data_load'
			data_load=varargin{i+1};
		case 'audio_load'
			audio_load=varargin{i+1};
	end
end

% wrap in a daemon for continuous scoring

filename_filter=[ '*' clust_ext '*.mat' ];

% clusters all files that can be scored

disp('Collecting files...');
all_files=robofinch_dir_recurse(DIR,filename_filter,max_depth,max_date);

% now split and get the first directory for all files

first_dir=cell(1,length(all_files));
for i=1:length(all_files)
	tokens=regexp(all_files(i).name,filesep,'split');
	ntokens=length(regexp(DIR,filesep,'split')); % first token after DIR
	first_dir{i}=tokens{ntokens+1};
end

[uniq_dirs,~,uniq_idx]=unique(first_dir)

for i=1:length(uniq_dirs)
	uniq_dirs{i}
end


