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
				
				% if both have labels, we can form a channel map

				ismap=1;
	
				for j=1:nlabels
			
					idx1=zeros(1,nlabels);
					idx2=ones(1,nlabels);
	
					idx1(curr_type.labels(j)==AGG.(data_types{i}).labels)=1;

					if isfield(AGG.(data_types{i}),'ports') & isfield(curr_type,'ports')
						idx2(curr_type.ports(j)==AGG.(data_types{i}).ports)=1;
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

			if ismap
				for j=1:nchannels
					if map(j,1)~=0
						AGG.(data_types{i}).data(:,IDX,map(j,1))=curr_type.data(:,map(j,2));
					else

						% if map(j,1)==0 then we need to expand the data matrix, add labels, etc.



						AGG.(data_types{i}).data(:,IDX,end+1)=curr_type.data(:,map(j,2));
						AGG.(data_types{i}).labels(end+1)=curr_type.labels(map(j,2));
					
						% sort by labels

						%[val idx]=sort(AGG.(data.types{i}).labels);

						%AGG.(data_types{i}).data=AGG.(data_types{i}).data(:,:,idx);
						%AGG.(data_types{i}).labels=AGG.(data_types{i}).labels(idx);

						if isfield(curr_type,'ports')
							AGG.(data_types{i}).ports(end+1)=curr_type.ports(map(j,2));
							%AGG.(data_types{i}).ports=AGG.(data_types{i}).ports(idx);
						end

						if isfield(curr_type,'names')
							AGG.(data_types{i}).names{end+1}=curr_type.names{map(j,2)};
							%AGG.(data_types{i}).names=AGG.(data_types{i}).names(idx);
						end

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
