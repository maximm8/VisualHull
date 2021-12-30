%% Convert voxel list to 3D grid
%  
%  input:   voxels_number    - number of voxels in each dimension
%           voxel_size       - size of the voxel in each dimension
%           voxel            - List of voxels Nx4
% 
%  output:  voxel3D          - 3D grid of voxels
function [voxel3D] = ConvertVoxelList2Voxel3D(voxels_number, voxel)
voxel3D = reshape(voxel(:,4),voxels_number([2,1,3]));