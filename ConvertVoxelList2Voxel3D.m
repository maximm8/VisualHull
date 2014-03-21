function [voxel3D] = ConvertVoxelList2Voxel3D(voxels_number, voxel_size, voxel)

sx = -(voxels_number(1)/2)*voxel_size(1);
ex = voxels_number(1)/2*voxel_size(1);

sy = -(voxels_number(2)/2)*voxel_size(2);
ey = voxels_number(2)/2*voxel_size(2);
sz = 0;
ez = voxels_number(3)*voxel_size(3);
voxels_number = voxels_number+1;
voxel3D = zeros([voxels_number(2) voxels_number(1) voxels_number(3)]);

l=1;z1=1;
for z=ez:-voxel_size(3):sz
    x1=1;
    for x=sx:voxel_size(1):ex
        y1=1;
        for y=sy:voxel_size(2):ey

            voxel3D(y1, x1, z1) = voxel(l,4);

            l=l+1;
            y1 = y1+1;
        end
        x1=x1+1;
    end
    z1=z1+1;
end
