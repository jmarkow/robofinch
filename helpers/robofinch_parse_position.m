function [BOUT_NUMBER,MOTIF_NUMBER,FILE_NUMBER]=robofinch_parse_position(FILENAME)
%
%

[pathname,filename,ext]=fileparts(FILENAME);

tmp=regexp(filename,'.*chunk_(\d+).*','tokens');
BOUT_NUMBER=str2num(tmp{1}{1});

tmp=regexp(filename,'.*roboextract_(\d+).*','tokens');
MOTIF_NUMBER=str2num(tmp{1}{1});

% get base filenames

tmp=dir(fullfile(pathname,'*.mat'));
listing={tmp(:).name};

% strip

tmp=regexp(listing,'(.*)\_chunk.*','tokens');
base_listing=cell(1,length(tmp));
for i=1:length(tmp)
	base_listing{i}=tmp{i}{1}{1};
end

% get stripped current name

tmp=regexp(filename,'(.*)\_chunk.*','tokens');

% idx

idx=find(strcmp(base_listing,tmp{1}{1}));

[uniq_files,~,uniq_pos]=unique(base_listing);

FILE_NUMBER=uniq_pos(idx(1));


