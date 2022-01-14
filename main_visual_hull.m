clear all

%dataset path
data_dir = 'templeSparseRing/'; 
% data_dir = 'dinoSparseRing/'; 

% paremeters 
silhouette_thresold = 20;
voxel_grid_size_xyz = [100, 100, 100];

%load data
DL = DataLoader(data_dir);
DL = DL.LoadCameraParams();
DL = DL.LoadImages();
DL = DL.CalcFOVUnion();

%calc visual hull
VH = VisualHull(DL);
VH = VH.ExtractSilhoueteFromImages(silhouette_thresold);
VH = VH.CreateVoxelGrid(voxel_grid_size_xyz);
VH = VH.ProjectVoxelsToSilhouette();

% show results
figure; 
VH.ShowVH3D();
% hold on;
% DL.PlotFOV([1 2 3]);

figure; 
VH.ShowVH3D();
hold on;
DL.PlotFOV([], 'blue', 0.1);
DL.PlotBoudningVolume('green', 1);

figure; VH.ShowVH2DGrid(180);

% save results to stl file
% VH.SaveGeoemtry2STL()