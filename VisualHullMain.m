clear all
% data_dir = 'templeRing/';
% data_dir = 'templeSparseRing/'; 
% data_dir = 'dinoRing/'; 
data_dir = 'dinoSparseRing/'; 
% file_base = 'templeR';
% file_base = 'templeSR';
file_base = 'dinoSR';
T = 20; %threshold to get object silhouette

%% 1 load camera params
fid = fopen([data_dir file_base '_par.txt'], 'r');
res = textscan(fid,'%d');
N = res{1,1};
for i=1:N
    textscan(fid,'%s',1);
    res = textscan(fid,'%f', 21);
    tmp =res{1}';
    K = reshape(tmp(1:9), 3, 3)';
    R = reshape(tmp(10:18), 3, 3)';
    t = tmp(19:21)';
    M(:,:,i) = K*[R t];
end
fclose(fid);

%% 2 load images
for i=1:N
    imgs(:,:,:,i) = imread([data_dir file_base num2str(i, '%04i') '.png']);
end

%% 3 compute silhouettes
for i=1:size(imgs,4)
     ch1 = imgs(:,:,1,i)>T;
     ch2 = imgs(:,:,2,i)>T;
     ch3 = imgs(:,:,3,i)>T;
     silhouettes(:,:,i) = (ch1+ch2+ch3)>0;
end

%% 4 create voxel grid
voxel_size = [0.001 0.001 0.001];

switch file_base
    case 'dinoSR'
        % dinoSR bounding box
        xlim = [-0.07 0.02];
        ylim = [-0.02 0.07];
        zlim = [-0.07 0.02];
    case 'dinoR'
        % dinoR bounding box
        xlim = [-0.03 0.06];
        ylim = [0.022 0.11];
        zlim = [-0.02 0.06];

    case 'templeSR'
        % templeSR bounding box
        xlim = [-0.08 0.03];
        ylim = [0.0 0.18];
        zlim = [-0.02 0.06];

    case 'templeR'
        % templeR bounding box
        xlim = [-0.05 0.11];
        ylim = [-0.04 0.15];
        zlim = [-0.1 0.06];
        
    otherwise
        xlim = [-0.08 0.11];
        ylim = [-0.03 0.18];
        zlim = [-0.1 0.06];
end

[voxels, voxel3Dx, voxel3Dy, voxel3Dz, voxels_number] = InitializeVoxels(xlim, ylim, zlim, voxel_size);


%% 5 project voxel to silhouette
display_projected_voxels = 0;
[voxels_voted] = CreateVisualHull(silhouettes, voxels, M, display_projected_voxels);


% % display voxel grid
% voxels_voted1 = (reshape(voxels_voted(:,4), size(voxel3Dx)));
% maxv = max(voxels_voted(:));
% fid = figure;
% for j=1:size(voxels_voted1,3), 
%     figure(fid), imagesc((squeeze(voxels_voted1(:,:,j))), [0 maxv]), title([num2str(j), ' - press any key to continue']), axis equal, 
%     pause,
% end

%% 6 apply marching cube algorithm and display the result
error_amount = 5;
maxv = max(voxels_voted(:,4));
iso_value = maxv-round(((maxv)/100)*error_amount)-0.5;
disp(['max number of votes:' num2str(maxv)])
disp(['threshold for marching cube:' num2str(iso_value)]);

[voxel3D] = ConvertVoxelList2Voxel3D(voxels_number, voxel_size, voxels_voted);

[fv]  = isosurface(voxel3Dx, voxel3Dy, voxel3Dz, voxel3D, iso_value, voxel3Dz);
[faces, verts, colors]  = isosurface(voxel3Dx, voxel3Dy, voxel3Dz, voxel3D, iso_value, voxel3Dz);

verts_min =  min(verts);
verts_max =  max(verts);
verts_diff = abs(verts_max-verts_min);

verts(:,1) = verts(:,1) - verts_min(1)-verts_diff(1)/2;
verts(:,2) = verts(:,2) - verts_min(2)-verts_diff(2)/2;

fv.vertices = verts;
verts = verts/max(verts_max);


fid = figure; 
p=patch('vertices', verts, 'faces', faces, ... 
    'facevertexcdata', colors, ... 
    'facecolor','flat', ... 
    'edgecolor', 'interp');

set(p,'FaceColor', [0.5 0.5 0.5], 'FaceLighting', 'flat',...
    'EdgeColor', 'none', 'SpecularStrength', 0, 'AmbientStrength', 0.4, 'DiffuseStrength', 0.6);

set(gca,'DataAspectRatio',[1 1 1], 'PlotBoxAspectRatio',[1 1 1],...
    'PlotBoxAspectRatioMode', 'manual');

axis vis3d;

light('Position',[1 1 0.5], 'Visible', 'on');
light('Position',[1 -1 0.5], 'Visible', 'on');
light('Position',[-1 1 0.5], 'Visible', 'on');
light('Position',[-1 -1 0.5], 'Visible', 'on'); 

ka = 0.1; kd = 0.4; ks = 0;
material([ka kd ks])

axis equal;
axis tight
axis off

%% 7 save VH to stl file
cdate = datestr(now, 'yyyy.mm.dd');
filename = [data_dir file_base '_VH_' cdate '.stl'];
patch2stl(filename, fv);