function robofinch_convert_legacy(DIR)
%
%

if nargin<1 | isempty(DIR)
	DIR=pwd;
end

storedir=fullfile(DIR,'..','converted_data');

if ~exist(storedir,'dir')
	mkdir(storedir);
end

listing=dir(fullfile(DIR,'*.mat'));
listing={listing(:).name};

for i=1:length(listing)

	disp([listing{i}]);
	load(listing{i});

	ephys.labels=channels;
	ephys.ports=repmat('A',[1 length(ephys.labels)]);
	ephys.data=ephys_data;
	ephys.fs=fs;
	ephys.t=[1:size(ephys_data,1)]'./fs;

	audio.data=mic_data;
	audio.fs=fs;
	audio.t=[1:length(mic_data)]'./fs;

	save(fullfile(storedir,listing{i}),'ephys','audio');

end
