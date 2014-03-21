function patch2stl(filename,p,mode)
%PATCH2STL   Write STL file from patch (vertices/faces) data.
%   PATCH2STL('filename',p) writes a stereolithography (STL) file
%   for a patch mesh defined by P. P must be a structure with 'VERTICES'
%   and 'FACES' fields.
%
%   PATCH2STL(...,'mode') may be used to specify the output format.
%
%     'binary' - writes in STL binary format (default)
%     'ascii'  - writes in STL ASCII format
%
%   Example:
%
%       tmpvol = zeros(20,20,20);       % Empty voxel volume
%       tmpvol(8:12,8:12,5:15) = 1;     % Turn some voxels on
%       fv = isosurface(tmpvol, 0.99);  % Create the patch object
%       patch2stl('test.stl',fv)        % Save to binary .stl

%   Based on surf2stl by Bill McDonald
%
%   Author: Sven Holcombe, 07-30-08

error(nargchk(2,3,nargin));

if (ischar(filename)==0)
    error( 'Invalid filename');
end

if (nargin < 3)
    mode = 'binary';
elseif (strcmp(mode,'ascii')==0)
    mode = 'binary';
end

if (~(isfield(p,'vertices') && isfield(p,'faces')))
    error( 'Variable p must be a faces/vertices structure' );
end

if strcmp(mode,'ascii')
    % Open for writing in ascii mode
    fid = fopen(filename,'w');
else
    % Open for writing in binary mode
    fid = fopen(filename,'wb+');
end

if (fid == -1)
    error('patch2stl:cannotWriteFile', 'Unable to write to %s', filename);
end

title_str = sprintf('Created by patch2stl.m %s',datestr(now));

if strcmp(mode,'ascii')
    fprintf(fid,'solid %s\r\n',title_str);
else
    str = sprintf('%-80s',title_str);    
    fwrite(fid,str,'uchar');         % Title
    fwrite(fid,0,'int32');           % Number of facets, zero for now
end

nfacets = 0;
% Main loop
for i=1:length(p.faces)
    p123 = p.vertices(p.faces(i,:),:);
    val = local_write_facet(fid,p123(1,:),p123(2,:),p123(3,:),mode);
    nfacets = nfacets + val;
end

if strcmp(mode,'ascii')
    fprintf(fid,'endsolid %s\r\n',title_str);
else
    fseek(fid,0,'bof');
    fseek(fid,80,'bof');
    fwrite(fid,nfacets,'int32');
end

fclose(fid);

disp( sprintf('Wrote %d facets',nfacets) );


% Local subfunctions

function num = local_write_facet(fid,p1,p2,p3,mode)

if any( isnan(p1) | isnan(p2) | isnan(p3) )
    num = 0;
    return;
else
    num = 1;
    n = local_find_normal(p1,p2,p3);
    
    if strcmp(mode,'ascii')
        
        fprintf(fid,'facet normal %.7E %.7E %.7E\r\n', n(1),n(2),n(3) );
        fprintf(fid,'outer loop\r\n');        
        fprintf(fid,'vertex %.7E %.7E %.7E\r\n', p1);
        fprintf(fid,'vertex %.7E %.7E %.7E\r\n', p2);
        fprintf(fid,'vertex %.7E %.7E %.7E\r\n', p3);
        fprintf(fid,'endloop\r\n');
        fprintf(fid,'endfacet\r\n');
        
    else
        
        fwrite(fid,n,'float32');
        fwrite(fid,p1,'float32');
        fwrite(fid,p2,'float32');
        fwrite(fid,p3,'float32');
        fwrite(fid,0,'int16');  % unused
        
    end
    
end


function n = local_find_normal(p1,p2,p3)

v1 = p2-p1;
v2 = p3-p1;
v3 = cross(v1,v2);
n = v3 ./ sqrt(sum(v3.*v3));
