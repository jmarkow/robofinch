function [AGG,TO_DEL]=robofinch_add_data(AGG,DATA_TYPE,NEW_DATA,IDX)
%
%
%

TO_DEL=0;
% what are the field names for the aggregated data


data_types=fieldnames(AGG);
ntypes=length(data_types);

% make sure dimensions match, etc.

for i=1:ntypes

	if ~isfield(NEW_DATA,data_types{i})
		TO_DEL=1;
		break;
	end

	% map according to data type

	curr_type=NEW_DATA.(data_types{i});


	if DATA_TYPE(i)==1

		if isstruct(curr_type) & isfield(curr_type,'data')

			[nsamples,nchannels]=size(curr_type.data);
			[agg_nsamples,~,agg_nchannels]=size(AGG.(data_types{i}).data);

			if nsamples~=agg_nsamples | nchannels~=agg_nchannels
				TO_DEL=1;
				return;
			end

			AGG.(data_types{i}).data(:,IDX,:)=curr_type.data;

		else
			TO_DEL=1;
			return;
		end


	elseif DATA_TYPE(i)==2

		if isnumeric(curr_type) & length(curr_type)==1
			AGG.(data_types{i})(IDX)=curr_type;
		else
			TO_DEL=1;
			return;
		end

	else
	
		AGG.(data_types{i}){IDX}=curr_type;

	end
end
