function robofinch_fluolab(FILE,PARAMETER_FILE,varargin)

if nargin<2, PARAMETER_FILE=[]; end

save_dir='robofluolab';
colors='jet';
blanking=[.2 .2];
normalize='m';
dff=1;
classify_trials='ttl';
channel=1;
daf_level=.05;
trial_cut=2;
newfs=100;
tau=.1;
detrend_win=.3;
save_file='robofluolab.mat';
ylimits=[.2 .7];

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
		case 'blanking'
			blanking=varargin{i+1};
		case 'normalize'
			normalize=varargin{i+1};
		case 'dff'
			dff=varargin{i+1};
		case 'classify_trials'
			classify_trials=varargin{i+1};
		case 'save_dir'
			save_dir=varargin{i+1};
		case 'channel'
			channel=varargin{i+1};
		case 'daf_level'
			daf_level=varargin{i+1};
		case 'trial_cut'
			trial_cut=varargin{i+1};
		case 'newfs'
			newfs=varargin{i+1};
		case 'tau'
			tau=varargin{i+1};
		case 'detrend_win'
			detrend_win=varargin{i+1};
		case 'ylimits'
			ylimits=varargin{i+1};
	end
end

% if a parameter file is provided, use new parameter


if ~isempty(PARAMETER_FILE)
	tmp=robofinch_read_config(PARAMETER_FILE);
	new_param_names=fieldnames(tmp);

	for i=1:length(new_param_names)


		if any(strcmp(param_names,new_param_names{i}))
			% map variable to the current workspace
			
			disp(['Setting parameter ' new_param_names{i} ' to:  ' num2str(tmp.(new_param_names{i}))]);
			feval(@()assignin('caller',new_param_names{i},tmp.(new_param_names{i})));
		end
	end
end


load(FILE,'adc','ttl','audio');
[path,file,ext]=fileparts(FILE);

[raw,regress,trials]=fluolab_fb_proc(adc,audio,ttl,'blanking',blanking,'normalize',normalize,'dff',dff,'classify_trials',classify_trials,...
	'channel',channel,'daf_level',daf_level,'trial_cut',trial_cut,'newfs',newfs,'tau',tau,'detrend_win',detrend_win);

if isempty(trials.fluo_include.all)
	disp('Found no trials skipping...');
	return;
end

%tmp=ttl;
%tmp.data=tmp.data(:,trials.include);
%raw=fluolab_fb_proc_window(raw,tmp,'blanking',blanking);
%trials.all_class=fluolab_classify_trials(ttl.data,ttl.fs);

fignums=fluolab_fb_plots(audio,raw,ttl,trials,'visible','off','blanking',blanking,'colors',colors,...
	'ylimits',ylimits); %
fig_names=fieldnames(fignums);

for i=1:length(fig_names)

	% save figs

	if ~isempty(save_dir) & ~exist(fullfile(path,save_dir),'dir')
		mkdir(fullfile(path,save_dir))
	end

	markolab_multi_fig_save(fignums.(fig_names{i}),fullfile(path,save_dir),fig_names{i},'eps,png,fig');
	close([fignums.(fig_names{i})]);

end

save(fullfile(path,save_dir,save_file),'raw','regress','trials');

