function PARAMETERS=robofinch_read_config(FILE)
%
%
%
%
%


fid=fopen(FILE,'r');
readdata=textscan(fid,'%s%[^\n]','commentstyle','#');
fclose(fid);

for i=1:length(readdata{1})

	PARAMETERS.(readdata{1}{i})=str2double(readdata{2}{i});

	% if this returns NaN, then the parameter value was specified as a string,
	% read as such

	if isnan(PARAMETERS.(readdata{1}{i}))

		if strcmp(readdata{2}{i},'[]')
			PARAMETERS.(readdata{1}{i})=str2num(readdata{2}{i});
		else
			PARAMETERS.(readdata{1}{i})=readdata{2}{i};
		end

	end

	% if we returned a string but it's enclosed by brackets, we're looking at a vector

	if ischar(PARAMETERS.(readdata{1}{i})) 
		if PARAMETERS.(readdata{1}{i})(1)=='[' & PARAMETERS.(readdata{1}{i})(end)==']'
			PARAMETERS.(readdata{1}{i})=str2num(PARAMETERS.(readdata{1}{i}));
		end
	end

end





