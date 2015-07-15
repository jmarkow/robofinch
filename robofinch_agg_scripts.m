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
clust_ext='roboextract';
extract_dir='roboaggregate';
extract_file='roboaggregate.mat';
extract_marker='robofinch_aggtrigger';
script_dir='~/Desktop/agg_scripts'; % default agg_script directory, all functions in this dir will be run
skip='';

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
		case 'script_dir'
			script_dir=varargin{i+1};
		case 'skip'
			skip=varargin{i+1};
	end
end

recurse_files(1).field='config';
recurse_files(1).filename=parameter_file;
recurse_files(1).multi=1;

recurse_files(2).field='data';
recurse_files(2).filename=extract_file;
recurse_files(2).multi=0;

tmp=what(script_dir);
fun_names={};

if isempty(tmp)
	warning('Directory %s not found',script_dir);
	return;
end

if length(tmp.m)<1
	warning('No scripts found in directory %s',script_dir);
	return;
end

for i=1:length(tmp.m)
	[path,file,ext]=fileparts(tmp.m{i});
	fun_names{i}=file;
end

% clusters all files that can be scored

disp('Collecting files...');
all_files=robofinch_dir_recurse(DIR,extract_marker,max_depth,max_date,recurse_files,[],[],[],skip);

% load parameters and run all scripts on aggregated data

for i=1:length(all_files)

	% todo, integrate fluolab script, almost there...

	for j=1:length(fun_names)
		disp(['Evaluating: ' fun_names{j} ' for ' all_files(i).data]);
		feval(fun_names{j},all_files(i).data,all_files(i).config);
	end

	% delete the trigger file, move on...
	
	delete([all_files(i).name]);

end



