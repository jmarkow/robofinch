function robofinch_mark_dirs(FILELIST,TEMPLATELIST,TO_CLUST,SIGNAL)
%
%
%
%
% get all unique pairings of files and directories


uniq_pairs=unique(TO_CLUST,'rows');
npairs=size(uniq_pairs,1);
paths=cell(1,npairs);

for i=1:npairs

	curr_pair=uniq_pairs(i,:);
	[pathname,~,~,]=fileparts(FILELIST(curr_pair(1)).name);

	% construct the path

	paths{i}=fullfile(pathname,TEMPLATELIST(curr_pair(2)).cluster_dir,SIGNAL);

end

uniq_paths=unique(paths);

for i=1:length(uniq_paths)
	fid=fopen(uniq_paths{i},'w');
	fclose(fid);
end
