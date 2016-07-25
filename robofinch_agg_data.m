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

max_depth=0; % how many levels of sub-directories to search through
max_date=inf;

% sound scoring parameters, make sure these match your template

parameter_file='robofinch_parameters.txt';
clust_ext='';
extract_dir='roboaggregate';
extract_file='roboaggregate.mat';
change_file='robofinch_fileadd';
extract_marker='robofinch_aggtrigger';
skip='';
blanking=1;
parse_position=0;
force=0;
nonuniform=0;
segments=1;
custom_load=[];

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
		case 'blanking'
			blanking=varargin{i+1};
		case 'parse_position'
			parse_position=varargin{i+1};
		case 'force'
			force=varargin{i+1};
		case 'nonuniform'
			nonuniform=varargin{i+1};
		case 'clust_ext'
			clust_ext=varargin{i+1};
    case 'segments'
      segments=varargin{i+1};
		case 'custom_load'
			custom_load=varargin{i+1};
	end
end

fprintf('%s%s%s\n',repmat('=',[1 20]),'robofinch_agg_data',repmat('=',[1 23]));

filename_filter=[ '*' clust_ext '*.mat' ];

% cluster all files that can be scored

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

fprintf('%g potential directories to aggregate\n',length(uniq_dirs));

for i=1:length(uniq_dirs)

	% within each directory, load the first file, these variables will be used to bootstrap the process

	% load the first file

	output_dir=fullfile(uniq_dirs{i},extract_dir);

	% if nothing has changed and we already processed, skip...

	if ~exist(fullfile(uniq_dirs{i},'..',change_file),'file') & exist(fullfile(output_dir,extract_file),'file') & ~force
		continue;
	end

	fprintf('Aggregating directory:  %s\n',uniq_dirs{i});

	curr_batch=all_files(uniq_idx==i);
	nfiles=length(curr_batch);

	if isempty(custom_load)
		template_data=load(curr_batch(1).name);
	else
		template_data=custom_load(curr_batch(1).name);
	end
	% prepare the aggregated data

	if parse_position

		fprintf('Parsing motif positions...\n');
		[template_data.bout_number,template_data.motif_number,template_data.file_number]=...
		robofinch_parse_position(curr_batch(1).name);
    end

	template_data.extract_filename=curr_batch(1).name;

	tmp=regexprep(curr_batch(1).name,'\_roboextract_\d+\.mat$','\.mat');
	[pathname,filename,ext]=fileparts(tmp);
	template_data.source_filename=fullfile(pathname,'..','..',[filename ext]);


	% map new data to agg data

	segments=min(nfiles,segments);

	fprintf('Mapping data with %g split(s)...\n',segments);
	reverse_string='';

	splits=unique([0:ceil(nfiles/segments):nfiles nfiles]);

	for j=1:length(splits)-1

		nfiles_split=length(splits(j)+1:splits(j+1));

		[agg,data_type]=robofinch_prepare_agg(template_data,nfiles_split,nonuniform);
		to_del=zeros(1,nfiles);

		for k=splits(j)+1:splits(j+1)


			% text progress bar

			percent_complete=100 * ((k-splits(j))/nfiles_split);
			msg=sprintf('Percent done: %3.1f',percent_complete);
			fprintf([reverse_string,msg]);
			reverse_string=repmat(sprintf('\b'),1,length(msg));

			% actual data aggregation

			if isempty(custom_load)
				new_data=load(curr_batch(k).name);
			else
				new_data=custom_load(curr_batch(k).name);
			end

			if parse_position
				[new_data.bout_number,new_data.motif_number,new_data.file_number]=...
				robofinch_parse_position(curr_batch(k).name);
			end

			new_data.extract_filename=curr_batch(k).name;

			tmp=regexprep(curr_batch(k).name,'\_roboextract_\d+\.mat$','\.mat');
			[pathname,filename,ext]=fileparts(tmp);
			new_data.source_filename=fullfile(pathname,'..','..',[filename ext]);

			if ~nonuniform
				[agg,to_del(k)]=robofinch_add_data(agg,data_type,new_data,k-splits(j),blanking);
            else
				[agg,to_del(k)]=robofinch_add_data_nonuniform(agg,data_type,new_data,k-splits(j),blanking);
			end

			if length(splits)>2
				% enumerate output directory if we have multiple splits
				use_output_dir=[output_dir '_' sprintf('%04g',j) ];
			else
				use_output_dir=output_dir;
			end


		end

		if ~exist(use_output_dir,'dir')
			mkdir(use_output_dir);
		end

		save(fullfile(use_output_dir,extract_file),'-struct','agg','-v7.3');

		% trigger analysis scripts

		fid=fopen(fullfile(use_output_dir,extract_marker),'w');
		fclose(fid);

	end

	% now remove the change_file

	fprintf('\n');
	disp([ num2str(sum(to_del)) ' errors']);

	if exist(fullfile(uniq_dirs{i},'..',change_file),'file')
		delete(fullfile(uniq_dirs{i},'..',change_file));
	end

end
