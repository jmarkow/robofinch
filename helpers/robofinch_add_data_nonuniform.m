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
            
			if nchannels~=agg_nchannels

				% if we're not blanking or we can't form a channel map, return

				if ~BLANK | ~isfield(AGG.(data_types{i}),'labels')
					TO_DEL=1;
					return;
				end
			end

			map=zeros(nchannels,2);
            
			if isfield(AGG.(data_types{i}),'labels')

				% make sure labels match if they exist

				% if agg has labels but new data does not, bail

				if ~isfield(curr_type,'labels')
					TO_DEL=1;
					return;
				end

				nlabels=length(curr_type.labels);
				agg_nlabels=length(AGG.(data_types{i}).labels);

				if nlabels~=agg_nlabels
					TO_DEL=1;
					return;
				end

				% if there are names, be sure they match

				if isfield(curr_type,'names') & isfield(AGG.(data_types{i}),'names')
					if length(curr_type.names)==nlabels & length(AGG.(data_types{i}).names)==agg_nlabels
						for j=1:nlabels
							if ~strcmpi(curr_type.names{j},AGG.(data_types{i}).names{j})
								TO_DEL=1;
								return;
							end
						end
					end
				end

				% if both have labels, we can form a channel map

				ismap=1;

				for j=1:nlabels

					idx1=zeros(1,nlabels);
					idx2=zeros(1,nlabels);

					idx1(curr_type.labels(j)==AGG.(data_types{i}).labels)=1;

					if isfield(AGG.(data_types{i}),'ports') & isfield(curr_type,'ports')
						idx2(curr_type.ports(j)==AGG.(data_types{i}).ports)=1;
					else
						idx2=ones(1,nlabels);
					end

					hit=find(idx1&idx2);

					% if hit is empty we've found a novel combination

					if isempty(hit)
						map(j,:)=[0 j];
					else
						map(j,:)=[hit j];
					end

				end

			end

			% if we have a map, use it, otherwise don't

            ismatch=all(map(:,1)==map(:,2));
            
            % audio is an exception, presumably one channel (crossed
            % fingers)
            
			if (ismap & ismatch) | strcmp(data_types{i},'audio')
				AGG.(data_types{i}).data=[AGG.(data_types{i}).data;curr_type.data];
            else
                disp('crah')
				TO_DEL=1;
				return;
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
