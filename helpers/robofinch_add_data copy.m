function robofinch_write_done(FILENAME,EXPORTDIR)
%
%
%

% write the done signal for sound_clust

[pathname,filename,ext]=fileparts(filename);
export_file=fullfile(pathname,exportdir,[ '.' filename ext]);

fid=fopen(export_file,'w');
fclose(fid);
