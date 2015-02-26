function TEMPLATES=robofinch_get_templates(DIR,TEMPLATE_FILE,CLASSIFY_FILE,TEMPLATE_DIR)
%

if nargin<4, TEMPLATE_DIR='templates'; end

TEMPLATE=[];

if exist(fullfile(DIR,TEMPLATE_DIR),'dir')
	
	listing=dir(fullfile(DIR,TEMPLATE_DIR));

	for i=1:length(listing)
		if listing(i).isdir & listing(i).name(1)~='.'
			flag1=exist(fullfile(DIR,TEMPLATE_DIR,listing(i).name,CLASSIFY_FILE),'file')>0;
			flag2=exist(fullfile(DIR,TEMPLATE_DIR,listing(i).name,TEMPLATE_FILE),'file')>0;

			if flag1 & flag2
				TEMPLATES(end+1).template_file=fullfile(DIR,TEMPLATE_DIR,listing(i).name,TEMPLATE_FILE);
				TEMPLATES(end).classify_file=fullfile(DIR,TEMPLATE_DIR,listing(i).name,CLASSIFY_FILE);
				tokens=regexp(TEMPLATE.filename{end},filesep,'split');
				TEMPLATES(end).name=tokens{end};
			end
		end
	end
end
