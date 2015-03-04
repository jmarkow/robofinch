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

max_depth=5; % how many levels of sub-directories to search through
max_date=inf;
file_ext='auto'; % automatically determine file type
filename_filter='songdet1*.mat';
filename_exclude={}; % anything to exclude

% sound scoring parameters, make sure these match your template

len=34;
overlap=33;
downsampling=5;
song_band=[3e3 9e3];
norm_amp=1;
filter_scale=10;
padding=[.2 .2];

export_spectrogram=1;
export_wav=1;

template_file='template_data.mat';
classify_file='classify_data.mat';

score_dir='syllable_data'; %
score_ext='_score'; % 

parameter_file='robofinch_parameters.txt';

recurse_files(1).field='config';
recurse_files(1).filename=parameter_file;

audio_load='';
data_load='';
clust_dir_ext='_roboextract'; % add to cluster directory so we know it's been auto-clustered

change_file='robofinch_fileadd';

% scan for intan_frontend files, prefix songdet1

for i=1:2:nparams
	switch lower(varargin{i})
		case 'export_spectrogram'
			export_spectrogram=varargin{i+1};
		case 'export_wav'
			export_wav=varargin{i+1};
		case 'template_file'
			template_file=varargin{i+1};
		case 'classify_file'
			classify_file=varargin{i+1};
		case 'score_dir'
			score_dir=varargin{i+1};
		case 'score_ext'
			score_ext=varargin{i+1};
		case 'max_depth'
			max_depth=varargin{i+1};
		case 'file_ext'
			file_ext=varargin{i+1};
		case 'filename_filter'
			filename_filter=varargin{i+1};
		case 'audio_load'
			audio_load=varargin{i+1};
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

filename_exclude{end+1}=score_ext;

default_params=struct('len',len,'overlap',overlap,'downsampling',downsampling,'song_band',song_band,...
	'filter_scale',filter_scale,'norm_amp',norm_amp,'audio_load',audio_load,'data_load',data_load,...
	'padding',padding);

% clusters all files that can be scored

disp('Collecting files...');
all_files=robofinch_dir_recurse(DIR,filename_filter,max_depth,max_date,recurse_files);

% now split and get the first directory for all files

first_dir=cell(1,length(all_files));
for i=1:length(all_files)
	tokens=regexp(all_files(i).name,filesep,'split');
	ntokens=length(regexp(DIR,filesep,'split')); % first token after DIR
	first_dir{i}=tokens{ntokens+1};
end

[uniq_dirs,~,uniq_idx]=unique(first_dir);

for i=1:length(uniq_dirs)

	% where are the templates

	curr_dir=fullfile(DIR,uniq_dirs{i});
	template_files=robofinch_dir_recurse(curr_dir,template_file,3);

	for j=1:length(template_files)
		[pathname,filename,ext]=fileparts(template_files(j).name);
		tokens=regexp(pathname,filesep,'split');
		template_files(j).cluster_dir=[ tokens{end} clust_dir_ext ];
		template_files(j).classify_file=fullfile(pathname,classify_file);

		if exist(fullfile(pathname,parameter_file),'file')
			template_files(j).parameter_file=fullfile(pathname,parameter_file);
		else
			template_files(j).parameter_file='';
		end

	end

	if isempty(template_files)
		continue;
	end

	% which files have been scored

	dir_files=all_files(uniq_idx==i);
	to_score=robofinch_to_score({dir_files(:).name},score_dir,score_ext);
	files_to_clust=dir_files(to_score==0);

	% exclude files that we don't want to clust (syllable_data, etc.)

	to_exclude=[];
	for j=1:length(filename_exclude)
		flag=~cellfun(@isempty,strfind({files_to_clust(:).name},filename_exclude{j}));
		to_exclude=[to_exclude find(flag)];
	end

	files_to_clust(to_exclude)=[];

	% sort the files to clust by their corresponding configuration file, be sure this matches the template before clusting

	[config_files,~,config_idx]=unique({files_to_clust(:).config});
	nconfigs=length(config_files);

	% parse by configuration, run batch score on each

	for j=1:nconfigs
	
		curr_batch=files_to_clust(config_idx==j);

		% non-standard config?

		new_params=default_params;

		% strip out all files that have been clustered by all templates
		
		to_clust=zeros(1,length(curr_batch));
		for k=1:length(curr_batch)

			[pathname,filename,ext]=fileparts(curr_batch(k).name);

			for l=1:length(template_files)

				cluster_dir=fullfile(pathname,template_files(l).cluster_dir);
				cluster_signal=fullfile(cluster_dir,['.' filename ext]);

				if ~exist(cluster_signal,'file')
					to_clust(k)=1;
					break;
				end
			end
		end
	
		clust_idx=find(to_clust);	

		if isempty(clust_idx)
			continue;
		end

		curr_batch=curr_batch(clust_idx);

		if ~isempty(curr_batch(1).config)	
			
			tmp=robofinch_read_config(curr_batch(1).config);
			new_param_names=fieldnames(tmp);

			% assign field names to variables

			for k=1:length(new_param_names)
				disp(['Setting parameter ' new_param_names{k} ':  ' num2str(tmp.(new_param_names{k})) ]);
				new_params.(new_param_names{k})=tmp.(new_param_names{k});
			end

			if isfield(tmp,'audio_load')
				eval([new_params.audio_load]);
			end

			if isfield(tmp,'data_load')
				eval([new_params.data_load]);
			end

		end

		if isempty(audio_load)
			error('Need audio loading function to continue...');
		end
	
		% for each template, check configuration against template

		disp('Making sure file configuration matches template...');

		to_clust=[];

		% initialize progress bar

		reverse_string='';
		count=1;
		total=length(curr_batch)*length(template_files);

		% load in the templates

		template={};
		for k=1:length(template_files)
			tmp=load(template_files(l).name,'template');
			template{k}=tmp.template;
		end

		for k=1:length(curr_batch)

			% accordingly, don't want to load all soundfiles ntemplate times
	
			[pathname,filename,ext]=fileparts(curr_batch(k).name);
			feature_file=fullfile(pathname,score_dir,[ filename score_ext '.mat' ]);
			load(feature_file,'parameters');
			feature_names=fieldnames(parameters);

			for l=1:length(template_files)

				% first, have we clustered this before?

				% the done signal is a dot file in the cluster directory
			
				cluster_dir=fullfile(pathname,template_files(l).cluster_dir);
				cluster_signal=fullfile(cluster_dir,['.' filename ext]);

				if ~exist(cluster_dir,'dir')
					mkdir(cluster_dir);
				end

				% text progress bar

				percent_complete=100 * (count/total);
				msg=sprintf('Percent done: %3.1f',percent_complete);
				fprintf([reverse_string,msg]);
				reverse_string=repmat(sprintf('\b'),1,length(msg));	
				count=count+1;

				if exist(cluster_signal,'file')
					continue;
				end

				if isfield(parameters,'fs')
					rate_match=(template{l}.fs==parameters.fs);
				else
					warning('Could not find sampling rate of file, skipping...');
					rate_match=0;
				end

				% short circuit of the sampling rates don't match

				if ~rate_match
					
					% print done signal so we don't check again
					
					fid=fopen(cluster_signal,'w');
					fclose(fid);
					continue;
				end

				% make sure feature parameters match between template and sound

				feature_match=robofinch_parameter_check(parameters,template{l}.feature_parameters,feature_names);

				% check sampling rates
			
				if ~feature_match 

					% print done signal so we don't check again
					
					fid=fopen(cluster_signal,'w');
					fclose(fid);
					continue;
				end

				% if we've made it to this point, we're clear to clust file k with template l, add to batch

				to_clust=[to_clust;k l];

			end
		end

		fprintf('\n');

		if isempty(to_clust)
			continue;
		end

		disp('Clustering...');

		for k=1:length(template_files)

			% find sound files to score with this template file

			load(template_files(k).name,'template');
			load(template_files(k).classify_file,'class_fun','cluster_choice','features_used');

			% if we find any parameters in the template directory, *they override other parameters*

			if ~isempty(template_files(k).parameter_file)

				tmp=robofinch_read_config(template_files(k).parameter_file);
				new_param_names=fieldnames(tmp);

				% assign field names to variables

				for l=1:length(new_param_names)
					disp(['Setting parameter ' new_param_names{l} ':  ' num2str(tmp.(new_param_names{l})) ]);
					new_params.(new_param_names{l})=tmp.(new_param_names{l});
				end

				if isfield(tmp,'audio_load')
					eval([new_params.audio_load]);
				end

				if isfield(tmp,'data_load')
					eval([new_params.data_load]);
				end

			end

			template_size=length(template.data);
			idx=to_clust(find(to_clust(:,2)==k),1);

			[hits.locs,hits.features,hits.file_list]=zftftb_template_match(template.features,{curr_batch(idx).name});
			[feature_matrix,file_id,peak_order]=zftftb_hits_to_mat(hits);

			% pass the feature_matrix to the clustering algorithm

			labels=class_fun(feature_matrix(:,features_used));

			% find where labels==selection, add the extraction points, be done with this...

			hits.ext_pts=zftftb_add_extractions(hits,labels,cluster_choice,file_id,peak_order,template.fs,template_size,...
				'padding',new_params.padding,'downsampling',new_params.downsampling,'len',new_params.len,'overlap',new_params.overlap);

			% extract the hits, write done signals

			robofinch_extract_data(hits.ext_pts,hits.file_list,template_files(k).cluster_dir,'audio_load',audio_load,'data_load',data_load);

		end

		% reset loading functions

		audio_load=default_params.audio_load;
		data_load=default_params.data_load;

		% mark the directories with added cluster files for agg_data

		robofinch_mark_dirs(curr_batch,template_files,to_clust,change_file);

	end
end

