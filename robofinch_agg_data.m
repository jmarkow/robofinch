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
change_file='robofinch_fileadd';
extract_marker='robofinch_aggtrigger';
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
		case 'skip'
			skip=varargin{i+1};
	end
end

% wrap in a daemon for continuous scoring

filename_filter=[ '*' clust_ext '*.mat' ];

% clusters all files that can be scored

disp('Collecting files...');
all_files=robofinch_dir_recurse(DIR,filename_filter,max_depth,max_date,[],[],[],[],skip);

% now split and get the first directory for all files

first_dir=cell(1,length(all_files));
for i=1:length(all_files)
	[pathname,filename,ext]=fileparts(all_files(i).name);
	first_dir{i}=pathname;
end

% with the directories, determine which ones to aggregate

[uniq_dirs,~,uniq_idx]=unique(first_dir);

for i=1:length(uniq_dirs)

	% within each directory, load the first file, these variables will be used to bootstrap the process
	
	% load the first file
	
	output_dir=fullfile(uniq_dirs{i},extract_dir);
	
	% if nothing has changed and we already processed, skip...

	if ~exist(fullfile(uniq_dirs{i},'..',change_file),'file') & exist(fullfile(output_dir,extract_file),'file')
		continue;
	end

	disp(['Aggregating directory:  ' uniq_dirs{i}]);

	curr_batch=all_files(uniq_idx==i);
	nfiles=length(curr_batch);

	template_data=load(curr_batch(1).name);
	
	% prepare the aggregated data

	[agg,data_type]=robofinch_prepare_agg(template_data,nfiles);	

	to_del=zeros(1,nfiles);

	% map new data to agg data

	reverse_string='';
	
	for j=1:nfiles

		% text progress bar

		percent_complete=100 * (j/nfiles);
		msg=sprintf('Percent done: %3.1f',percent_complete);
		fprintf([reverse_string,msg]);
		reverse_string=repmat(sprintf('\b'),1,length(msg));

		% actual data aggregation

		new_data=load(curr_batch(j).name);
		[agg,to_del(j)]=robofinch_add_data(agg,data_type,new_data,j);
	end

	fprintf('\n');
	disp([ num2str(sum(to_del)) ' errors']);
	
	if ~exist(output_dir,'dir')
		mkdir(output_dir);
	end

	% now remove the change_file 

	if exist(fullfile(uniq_dirs{i},'..',change_file),'file')
		delete(fullfile(uniq_dirs{i},'..',change_file));
	end

	save(fullfile(output_dir,extract_file),'-struct','agg');

	% trigger analysis scripts

	fid=fopen(fullfile(output_dir,extract_marker),'w');
	fclose(fid);

end


