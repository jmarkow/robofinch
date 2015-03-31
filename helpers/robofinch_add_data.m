function [AGG,TO_DEL]=robofinch_add_data(AGG,DATA_TYPE,NEW_DATA,IDX,BLANK)
%

TO_DEL=0;

if nargin<5
	BLANK=1;
end

% what are the field names for the aggregated data

data_types=fieldnames(AGG);
ntypes=length(data_types);

% make sure dimensions match, etc.

for i=1:ntypes

	ismap=0;

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

			if nsamples~=agg_nsamples			       
				TO_DEL=1;
				return;
			end

			if nchannels~=agg_nchannels
				TO_DEL=1;

				% if we're not blanking or we can't form a channel map, return

				if ~BLANK | ~isfield(AGG.(data_types{i}),'labels')
					return;
				end
			end

			map=zeros(1,agg_nchannels);

			if isfield(AGG.(data_types{i}),'labels')

				% make sure labels match if they exist

				% if agg has labels but new data does not, bail

				if ~isfield(curr_type,'labels')
					TO_DEL=1;
					return;
				end

				nlabels=length(curr_type.labels);
				agg_nlabels=length(AGG.(data_types{i}).labels);
				
				% if both have labels, we can form a channel map

				ismap=1;

				for j=1:agg_nlabels
					map(j)=find(curr_type.labels==AGG.(data_types{i}).labels(j));
				end

			end


			% if we have a map, use it, otherwise don't

			if ismap
				for j=1:nchannels
					if map(j)~=0
						AGG.(data_types{i}).data(:,IDX,j)=curr_type.data(:,map(j));
					else
						AGG.(data.types{i}).data(:,IDX,j)=nan(agg_nsamples,1);
						TO_DEL=1;
					end
				end
			else
				AGG.(data_types{i}).data(:,IDX,:)=curr_type.data;
			end

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
