function [AGG,DATA_TYPE]=robofinch_prepare_agg(NEW_DATA,NFILES,NONUNIFORM)
%
%
%

fields=fieldnames(NEW_DATA);
nfields=length(fields);
DATA_TYPE=zeros(1,nfields);

% initialize data types

for i=1:nfields

	curr_type=NEW_DATA.(fields{i});

	if isstruct(curr_type) & isfield(curr_type,'data')
		[nsamples,nchannels]=size(curr_type.data);
		AGG.(fields{i})=curr_type;
		if NONUNIFORM
			AGG.(fields{i}).data=[];
		else
			AGG.(fields{i}).data=zeros(nsamples,NFILES,nchannels,'single');
		end
		DATA_TYPE(i)=1;
	elseif isnumeric(curr_type) & length(curr_type)==1
		AGG.(fields{i})=zeros(1,NFILES);
		DATA_TYPE(i)=2;
	else
		AGG.(fields{i})=cell(1,NFILES);
		DATA_TYPE(i)=3;
	end

end
