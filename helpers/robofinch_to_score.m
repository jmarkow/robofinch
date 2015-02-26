function TO_SCORE=robofinch_to_score(FILES,SCORE_DIR,SCORE_EXT)
%
%

TO_SCORE=ones(1,length(FILES))*NaN;

for i=1:length(FILES)
	[path,filename,ext]=fileparts(FILES{i});
	score_file=fullfile(path,SCORE_DIR,[filename SCORE_EXT '.mat']);
	TO_SCORE(i)=~exist(score_file,'file');
end
