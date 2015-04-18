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

max_depth=4; % how many levels of sub-directories to search through
max_date=inf;
file_ext='auto'; % automatically determine file type
filename_filter='songdet1*.mat';
filename_exclude={'sleep'}; % anything to exclude

% sound scoring parameters, for clustering make sure your template uses same parameters

len=34;
overlap=33;
downsampling=5;
song_band=[3e3 9e3];
norm_amp=0;
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
recurse_files(1).multi=1; % allow for multiple configurations to be associated with a single file
audio_load='';
skip=[];

% scan for intan_frontend files, prefix songdet1

param_names=who('-regexp','^[a-z]');

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
		case 'skip'
			skip=varargin{i+1};
	end
end

% wrap in a daemon for continuous scoring

filename_exclude{end+1}=score_ext;

for i=1:length(param_names)
	default_params.(param_names{i})=eval([param_names{i}]);
end

% do we have any templates

%template_listing=robofinch_get_templates(listing{i},template_file,classify_file);

% recurse the directory 
% TODO: prevent recursion in old directories

all_files=robofinch_dir_recurse(DIR,filename_filter,max_depth,max_date,recurse_files,[],[],[],skip);

% which files need to be processed?

to_score=robofinch_to_score({all_files(:).name},score_dir,score_ext);
files_to_score=all_files(to_score==1);

to_exclude=[];
for i=1:length(filename_exclude)
	flag=~cellfun(@isempty,strfind({files_to_score(:).name},filename_exclude{i}));
	to_exclude=[to_exclude find(flag)];
end

files_to_score(to_exclude)=[];
to_exclude=[];

for i=1:length(files_to_score)

	curr_batch=files_to_score(i);

	% non-standard config?

	new_params=default_params;

	% assign parameters hierarchically
	% TODO: write parameters to a structure array then compute features in large batch

	if ~isempty(curr_batch.config)
		for j=1:length(curr_batch.config)

			tmp=robofinch_read_config(curr_batch.config{j});
			new_param_names=fieldnames(tmp);

			% assign field names to variables

			for k=1:length(new_param_names)
				if any(strcmp(param_names,new_param_names{k}))
					new_params.(new_param_names{k})=tmp.(new_param_names{k});
				end
			end

			if isfield(new_params,'audio_load') & ~isempty(new_params.audio_load)
				new_params.audio_load_fun=eval([new_params.audio_load]);
			else
				to_del=[to_exclude i];
			end

		end
	end
	
	params(i)=new_params;

	% score the file

end

files_to_score(to_exclude)=[];
params(to_exclude)=[];

if length(files_to_score)>0

	zftftb_batch_features({files_to_score(:).name},'len',cat(1,params(:).len),'overlap',...
		cat(1,params(:).overlap),'downsampling',cat(1,params(:).downsampling),'filter_scale',cat(1,params(:).filter_scale),...
		'norm_amp',cat(1,params(:).norm_amp),'song_band',cat(1,params(:).song_band),'audio_load',{params(:).audio_load_fun},'spec_sigma',cat(1,params(:).spec_sigma));
end
