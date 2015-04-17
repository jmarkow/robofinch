function robofinch_extract_data(EXT_PTS,FILENAMES,CLUSTER_DIR,varargin)
%
% walk through files, extract and write done signal

% make gif/mat/wav
% export spect and wav if user specifies
% write data to mat and done signal to base
%
%

export_wav=1;
export_spectrogram=1;
disp_band=[1 9e3];
colors='hot';
nparams=length(varargin);
data_load='';
audio_load='';

if mod(nparams,2)>0
	error('ephysPipeline:argChk','Parameters must be specified as parameter/value pairs!');
end

for i=1:2:nparams
	switch lower(varargin{i})
		case 'export_spectrogram'
			export_spectrogram=varargin{i+1};
		case 'export_wav'
			export_wav=varargin{i+1};
		case 'disp_band'
			disp_band=varargin{i+1};
		case 'colors'
			colors=varargin{i+1};
		case 'audio_load'
			audio_load=varargin{i+1};
		case 'data_load'
			data_load=varargin{i+1};
	end
end

% data load works a bit differently, 
% return structure with all variables to carry 
% over to the clustered file

y2=[];


reverse_string='';
	
for i=1:length(EXT_PTS)

	percent_complete=100 * (i/length(EXT_PTS));
	msg=sprintf('Percent done: %3.1f',percent_complete);
	fprintf([reverse_string,msg]);
	reverse_string=repmat(sprintf('\b'),1,length(msg));

	% check for extraction points in each file, if we find some, save to cluster_dir
	% 
	
	[pathname,filename,ext]=fileparts(FILENAMES{i});
	export_dir=fullfile(pathname,CLUSTER_DIR);

	wav_dir=fullfile(export_dir,'wav');
	mat_dir=fullfile(export_dir,'mat');
	gif_dir=fullfile(export_dir,'gif');

	if ~exist(export_dir,'dir')
		mkdir(export_dir);
	end

	if ~exist(wav_dir,'dir')
		mkdir(wav_dir);
	end

	if ~exist(mat_dir,'dir')
		mkdir(mat_dir);
	end

	if ~exist(gif_dir,'dir')
		mkdir(gif_dir);
	end

	if length(EXT_PTS{i})<1
		fid=fopen(fullfile(export_dir,[ '.' filename ext]),'w');
		fclose(fid);
		continue;
	end

	% y is audio data y2 contains a structure with all data variables
	

	% load in audio data

	switch lower(ext)

		case '.wav'

			[y,fs]=wavread(FILENAMES{i});

		case '.mat'

			if ~isempty(audio_load)
				[y,fs]=audio_load(FILENAMES{i});
			else
				error('No custom loading function detected for .mat files.');
			end

			if ~isempty(data_load)
				y2=data_load(FILENAMES{i});
				data_vars=fieldnames(y2);
			else
				y2=[];
				data_vars=[];
			end

	end

	% form the audio data
	
	len=length(y);

	% make the full spectrogram, mark extraction points

	if export_spectrogram

		[im_full,f,t_full]=zftftb_pretty_sonogram(y,fs,'len',16.7,'overlap',3.3,'zeropad',0,'filtering',500,'clipping',[-2 2],'norm_amp',1);
		
		startidx=max([find(f<=disp_band(1))]);
		stopidx=min([find(f>=disp_band(2))]);

		im_full=im_full(startidx:stopidx,:)*62;
		im_full=flipdim(im_full,1);

		sonogram_filename=fullfile(export_dir,'gif',[filename '.gif']);

	end

	filecount=1;

	for j=1:size(EXT_PTS{i},1)

		export_file=fullfile([filename '_roboextract_' num2str(filecount)]);
		
		startpoint=EXT_PTS{i}(j,1);
		endpoint=EXT_PTS{i}(j,2);

		if startpoint<1 | endpoint>len
			continue;
		end

		% if we're here, time to extract
	
		audio.data=y(startpoint:endpoint);
		audio.fs=fs;
		audio.t=[1:len]'/fs;

		% now loop through data variables, checking for non-empty data-field
	
		ext_data=y2;

		if ~isempty(ext_data)
			for k=1:length(data_vars)
				if isfield(ext_data.(data_vars{k}),'data')
					if ~isempty(ext_data.(data_vars{k}).data)

						fs_conv=ext_data.(data_vars{k}).fs/fs;
						startpoint=round(startpoint*fs_conv);
						endpoint=round(endpoint*fs_conv);

						tmp=length(startpoint:endpoint);

						ext_data.(data_vars{k}).data=ext_data.(data_vars{k}).data(startpoint:endpoint,:);
						ext_data.(data_vars{k}).t=[1:tmp]'/fs;

					end
				end
			end
			save(fullfile(export_dir,'mat',[ export_file '.mat']),'-struct','ext_data');
		else
			save(fullfile(export_dir,'mat',[ export_file '.mat']),'audio');
		end


		% data extracted, now save

		if export_wav

			tmp=audio.data;
			min_audio=min(tmp);
			max_audio=max(tmp);

			if min_audio + max_audio < 0
				tmp=tmp/(-min_audio);
			else
				tmp=tmp/(max_audio*(1+1e-3));
			end

			audiowrite(fullfile(export_dir,'wav',[ export_file '.wav' ]),tmp,round(audio.fs));
		end

		if export_spectrogram

			[im,f,t]=zftftb_pretty_sonogram(audio.data,audio.fs,'len',16.7,'overlap',14,'zeropad',0,'filtering',500,'clipping',[-2 2],'norm_amp',1);

			startidx=max([find(f<=disp_band(1))]);
			stopidx=min([find(f>=disp_band(2))]);

			im=im(startidx:stopidx,:)*62;
			im=flipdim(im,1);
			[f,t]=size(im);

			% mark the full spectrogram at the extraction points

			imwrite(uint8(im),colormap([ colors '(63)']),fullfile(export_dir,'gif',[ export_file '.gif']),'gif');

			[~,left_edge]=min(abs(t_full-EXT_PTS{i}(j,1)/fs));
			[~,right_edge]=min(abs(t_full-EXT_PTS{i}(j,2)/fs));

			if isempty(left_edge), left_edge=1; end
			if isempty(right_edge), right_edge=length(t_full); end

			im_full(1:10,left_edge:right_edge)=62;

		end

		filecount=filecount+1;

	end

	% export the file's spectrogram with extraction points marked

	if export_spectrogram
		reformatted_im=markolab_im_reformat(im_full,(ceil((length(y)/fs)/10)));
		imwrite(uint8(reformatted_im),colormap([ colors '(63)']),sonogram_filename,'gif');
	end

	% write the done signal
	
	fid=fopen(fullfile(export_dir,[ '.' filename ext]),'w');
	fclose(fid);

	clearvars y y2 fs ext_data;

end

fprintf('\n');
