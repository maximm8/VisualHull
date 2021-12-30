%% Initialize Voxels
%  
%  input:   xlim                - min and max volume limit in X axis
%           ylim                - min and max volume limit in Y axis
%           zlim                - min and max volume limit in Z axis
%           voxel_size          - size of voxel in 3D
% 
%  output:  voxel               - array of voxel  coordinates VoxelsNbx4
%                                 each line represents coordinates of a
%                                 voxel center [X, Y, Z, 1]
%           voxel3Dx            - 3D grid coordinates of X dimension
%           voxel3Dy            - 3D grid coordinates of Y dimension
%           voxel3Dz            - 3D grid coordinates of Z dimension
%           voxels_number_act   - number of created voxels
function [voxel, voxel3Dx, voxel3Dy, voxel3Dz, voxels_number_act] = InitializeVoxels(xlim, ylim, zlim, voxel_size)


voxels_number(1) = abs(xlim(2)-xlim(1))./voxel_size(1);
voxels_number(2) = abs(ylim(2)-ylim(1))./voxel_size(2);
voxels_number(3) = abs(zlim(2)-zlim(1))./voxel_size(3);
voxels_number_act = floor(voxels_number);
total_number = round(prod(voxels_number_act));

voxel = ones(total_number, 4, 'single');

sx = xlim(1);
ex = xlim(1) + (voxels_number_act(1)-1)*voxel_size(1);
sy = ylim(1);
ey = ylim(1) + (voxels_number_act(2)-1)*voxel_size(2);
sz = zlim(1);
ez = zlim(1) + (voxels_number_act(3)-1)*voxel_size(3);

if(ex>sx)
    x_step = voxel_size(1);
else
    x_step = -voxel_size(1);
end

if(ey>sy)
    y_step = voxel_size(2);
else
    y_step = -voxel_size(2);
end

if(ez>sz)
    z_step = voxel_size(3);
else
    z_step = -voxel_size(3);
end


[voxel3Dx, voxel3Dy, voxel3Dz] = meshgrid(sx:x_step:ex, ...
                                          sy:y_step:ey, ...
                                          sz:z_step:ez);
                                      
voxel(:,1) = voxel3Dx(:);
voxel(:,2) = voxel3Dy(:);
voxel(:,3) = voxel3Dz(:);


