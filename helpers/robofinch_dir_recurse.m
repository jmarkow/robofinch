function FILES=robofinch_dir_recurse(DIR,FILTER,MAXDEPTH,MAXDATE,TAG_NAME,TAG_FILE,FILES,DEPTH,SKIP) 

if nargin<9, SKIP=[]; end
if nargin<8 | isempty(DEPTH), DEPTH=0; end

if nargin<7
	FILES=[];
end

if nargin<6, TAG_FILE={}; end
if nargin<5, TAG_NAME=[]; end 
if nargin<4 | isempty(MAXDATE), MAXDATE=inf; end
if nargin<3 | isempty(MAXDEPTH), MAXDEPTH=inf; end
if nargin<2, FILTER=''; end
if nargin<1, DIR=pwd; end

if DEPTH>MAXDEPTH
	return;
end

DEPTH=DEPTH+1;

% did we find a config file along the way?

raw_listing=dir(DIR);

if ~isempty(TAG_NAME)

	if isempty(TAG_FILE)	
		for j=1:length(TAG_NAME)
			TAG_FILE{j}='';
		end
	end

	for i=1:length(raw_listing)
		for j=1:length(TAG_NAME)
			if strcmp(raw_listing(i).name,TAG_NAME(j).filename) 
				if TAG_NAME(j).multi
					if ~isempty(TAG_FILE{j})
						TAG_FILE{j}{end+1}=fullfile(DIR,raw_listing(i).name);
					else
						TAG_FILE{j}{1}=fullfile(DIR,raw_listing(i).name);
					end
				else
					TAG_FILE{j}=fullfile(DIR,raw_listing(i).name);
				end
			end
		end
	end

end

% assign fields

filter_listing=dir(fullfile(DIR,FILTER));
for i=1:length(filter_listing)
	if filter_listing(i).name(1)~='.'& ~filter_listing(i).isdir
		
		FILES(end+1).name=fullfile(DIR,filter_listing(i).name);	
		
		for j=1:length(TAG_NAME)
			FILES(end).(TAG_NAME(j).field)=TAG_FILE{j};
		end

		FILES(end).depth=DEPTH;

	end
end

% recurse if we find a directory

for i=1:length(raw_listing)
    
    skip_flag=false;
	if ~isempty(SKIP)
        for j=1:length(SKIP)
            if ~isempty(strfind(raw_listing(i).name,SKIP{j}))
                skip_flag=true;
            end
        end
    end
    
    if skip_flag
        continue;
    end

	if raw_listing(i).name(1)~='.' & raw_listing(i).isdir & ((daysdif(raw_listing(i).datenum,now))<MAXDATE)
		FILES=robofinch_dir_recurse(fullfile(DIR,raw_listing(i).name),FILTER,MAXDEPTH,MAXDATE,TAG_NAME,TAG_FILE,FILES,DEPTH,SKIP);
	end
end
