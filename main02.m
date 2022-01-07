clear all

%dataset path
% data_dir = 'templeRing/';
data_dir = 'templeSparseRing/'; 
% data_dir = 'dinoRing/'; 
% data_dir = 'dinoSparseRing/'; 

% paremeters 
silhouette_thresold = 20;
voxel_grid_size_xyz = [100, 100, 100];

%load data
DL = DataLoader(data_dir);
DL = DL.LoadCameraParams();
DL = DL.LoadImages();

%calc visual hull
VH = VisualHull(DL);
VH = VH.ExtractSilhoueteFromImages(silhouette_thresold);
VH = VH.CreateVoxelGrid(voxel_grid_size_xyz);
VH = VH.ProjectVoxelsToSilhouette();

% show results
figure; VH.ShowVH3D();
figure; VH.ShowVH2DGrid(180);

% save results to stl file
VH.SaveGeoemtry2STL()