function CHECK=robofinch_parameter_check(PARAMS1,PARAMS2,PARAM_NAMES)
%
%
%

CHECK=1;
for i=1:length(PARAM_NAMES)
	if ~iscell(PARAMS1.(PARAM_NAMES{i}))
		tmp=fieldnames(PARAMS2);
		idx=find(~cellfun(@isempty,strfind(tmp,PARAM_NAMES{i})));

		if isempty(idx)
			check=0;
			break;
		end

		flag=all(PARAMS2.(tmp{idx})==PARAMS1.(PARAM_NAMES{i}));

		if ~flag
			check=0;
			break;
		end
	end
end


