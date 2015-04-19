function robofinch_fluolab(FILE,PARAMETER_FILE,varargin)

if nargin<2, PARAMETER_FILE=[]; end

% TODO: figure out what's going on in new dataset

save_dir='robopitchlab';
colors='jet';
blanking=[.2 .2];
normalize='m';
dff=1;
classify_trials='ttl';
channel=1;
daf_level=.02;
trial_cut=2;
newfs=100;
tau=.1;
detrend_win=.3;
hist_order=1e2;
ylim_order=1e2;
bin_res=5;
smooth_trials=100;
pitch_target=[];
pitch_threshold=[]; % pitch threshold in Hz
pitch_condition=''; % 'gt' is greater than 'lt is less than (as in noise in this condition)
cf=[1e3:1e3:1e3*5];

save_file='robopitchlab.mat';

% parameter are all values that begin with lowercase letters

nparams=length(varargin);

if mod(nparams,2)>0
	error('Parameters must be specified as parameter/value pairs');
end


param_names=who('-regexp','^[a-z]');

% scan for intan_frontend files, prefix songdet1

for i=1:2:nparams
	switch lower(varargin{i})
		case 'colors'
			colors=varargin{i+1};
		case 'classify_trials'
			classify_trials=varargin{i+1};
		case 'save_dir'
			save_dir=varargin{i+1};
		case 'daf_level'
			daf_level=varargin{i+1};
		case 'ylimits'
			ylimits=varargin{i+1};
		case 'daf_level'
			daf_level=varargin{i+1};
		case 'bin_res'
			bin_res=varargin{i+1};
		case 'pitch_order'
			pitch_order=varargin{i+1};
		case 'hist_order'
			hist_order=varargin{i+1};
		case 'smooth_trials'
			smooth_trials=varargin{i+1};
		case 'pitch_target'
			pitch_target=varargin{i+1};
		case 'pitch_threshold'
			pitch_threshold=varargin{i+1};
		case 'pitch_condition'
			pitch_condition=varargin{i+1};
		case 'cf'
			cf=varargin{i+1};

	end
end

% if a parameter file is provided, use new parameter

if ~isempty(PARAMETER_FILE)

	for i=1:length(PARAMETER_FILE)

		tmp=robofinch_read_config(PARAMETER_FILE{i});
		new_param_names=fieldnames(tmp);

		for j=1:length(new_param_names)
			if any(strcmp(param_names,new_param_names{j}))

				% map variable to the current workspace

				disp(['Setting parameter ' new_param_names{j} ' to:  ' num2str(tmp.(new_param_names{j}))]);
				feval(@()assignin('caller',new_param_names{j},tmp.(new_param_names{j})));
			end
		end
	end

end

if ~exist('pitch_target','var') | isempty(pitch_target)
	disp('No pitch target, skipping...');
	return;
end

load(FILE,'ttl','audio','file_datenum');
[path,file,ext]=fileparts(FILE);

trials=fluolab_classify_trials(ttl,audio,'method',classify_trials,'daf_level',daf_level);

if isempty(trials.all.catch)
	disp('Found no trials skipping...');
	return;
end

% check for matching syllable extraction

audio.data=audio.data(:,trials.all.catch);
pitch=fluolab_fb_pitch_proc(audio,pitch_target,'cf',cf);

fignums=fluolab_fb_pitch_plots(mean(pitch.target.mat,3),'visible','off','blanking',blanking,'colors',colors,...
	'hist_order',hist_order,'smooth_trials',smooth_trials,'ylim_order',ylim_order,'hist_order',hist_order,...
	'bin_res',bin_res,'datenums',file_datenum(trials.all.catch),'pitch_threshold',pitch_threshold,'pitch_condition',pitch_condition); 

fig_names=fieldnames(fignums);

for i=1:length(fig_names)

	% save figs

	if ~isempty(save_dir) & ~exist(fullfile(path,save_dir),'dir')
		mkdir(fullfile(path,save_dir))
	end

	markolab_multi_fig_save(fignums.(fig_names{i}),fullfile(path,save_dir),fig_names{i},'eps,png,fig');
	close([fignums.(fig_names{i})]);

end

save(fullfile(path,save_dir,save_file),'pitch','trials');

