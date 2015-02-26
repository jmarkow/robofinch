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

max_depth=6; % how many levels of sub-directories to search through
file_ext='auto'; % automatically determine file type
filename_filter='songdet1*.mat';
filename_exclude={}; % anything to exclude

% sound scoring parameters, for clustering make sure your template uses same parameters

len=34;
overlap=33;
downsampling=5;
song_band=[3e3 9e3];
norm_amp=1;
filter_scale=10;
spec_sigma=1.5;

export_spectrogram=1;
export_wav=1;

template_file='template_data.mat';
classify_file='classify_data.mat';
score_dir='syllable_data'; %
score_ext='_score'; % 

recurse_files(1).field='config';
recurse_files(1).filename='robofinch_parameters.txt';

audio_load='';

% scan for intan_frontend files, prefix songdet1


for i=1:2:nparams
	switch lower(varargin{i})
		case 'len'
			len=varargin{i+1};
		case 'overlap'
			overlap=varargin{i+1};
		case 'spec_sigma'
			spec_sigma=varargin{i+1};
		case 'filter_scale'
			filter_scale=varargin{i+1};
		case 'downsampling'
			downsampling=varargin{i+1};
		case 'norm_amp'
			norm_amp=varargin{i+1};
		case 'song_band'
			song_band=varargin{i+1};
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
	end
end

% wrap in a daemon for continuous scoring

filename_exclude{end+1}=score_ext;

default_params=struct('len',len,'overlap',overlap,'downsampling',downsampling,'song_band',song_band,...
	'filter_scale',filter_scale,'norm_amp',norm_amp,'audio_load',audio_load,'spec_sigma',spec_sigma);

% do we have any templates

%template_listing=robofinch_get_templates(listing{i},template_file,classify_file);

% recurse the directory 

all_files=robofinch_dir_recurse(DIR,filename_filter,max_depth,recurse_files);

% which files need to be processed?

to_score=robofinch_to_score({all_files(:).name},score_dir,score_ext);
files_to_score=all_files(to_score==1);

to_exclude=[];
for i=1:length(filename_exclude)
	flag=~cellfun(@isempty,strfind({files_to_score(:).name},filename_exclude{i}));
	to_exclude=[to_exclude find(flag)];
end

files_to_score(to_exclude)=[];
[config_files,~,config_idx]=unique({files_to_score(:).config});

% score files first, then move on to clustering

nconfigs=length(config_files);

% parse by configuration, run batch features on each

for i=1:nconfigs

	curr_batch=files_to_score(config_idx==i);

	% non-standard config?

	new_params=default_params;

	if ~isempty(curr_batch(1).config)	
		tmp=robofinch_read_config(curr_batch(1).config);
		new_param_names=fieldnames(tmp);

		% assign field names to variables

		for j=1:length(new_param_names)
			disp(['Setting parameter...']);
			new_params.(new_param_names{j})=tmp.(new_param_names{j});
		end

		if isfield(tmp,'audio_load')
			eval([new_params.audio_load]);
		end
	end

	if isempty(audio_load)
		error('Need audio loading function to continue...');
	end

	% score the files

	zftftb_batch_features({curr_batch(:).name},'len',new_params.len,'overlap',...
		new_params.overlap,'downsampling',new_params.downsampling,'filter_scale',new_params.filter_scale,...
		'norm_amp',new_params.norm_amp,'song_band',new_params.song_band,'audio_load',audio_load,'spec_sigma',spec_sigma);

	% reset loading functions (all other parameters are set in the structure)

	audio_load=default_params.audio_load;

end
