function robofinch_mark_dirs(FILELIST,TEMPLATELIST,TO_CLUST,SIGNAL)
%
%
%
%

% grab all files, get unique directories, write change signals

% files

file_idx=unique(TO_CLUST(:,1));

% templates

template_idx=unique(TO_CLUST(:,2));

files={FILELIST(file_idx).name};
templates={TEMPLATELIST(template_idx).cluster_dir};

nfiles=length(files);
basedir=cell(1,nfiles);

for i=1:length(files)
	[pathname,~,~]=fileparts(files{i});
	basedir{i}=pathname;
end

uniq_dirs=unique(basedir);

for i=1:length(uniq_dirs)
	for j=1:length(templates)
		fid=fopen(fullfile(uniq_dirs{i},templates{j},SIGNAL),'w');
		fclose(fid);
	end
end
