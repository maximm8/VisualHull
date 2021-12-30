%% Create Visual Hull
%  
%  input:   silhouettes                 - object silhouettes
%           voxels                      - array of voxel  coordinates VoxelsNbx4
%                                         each line represents coordinates of a voxel center 
% 										  [X, Y, Z, 1]
%           K                           - intrinsic parameters of the camera
%           M                           - array of poses of 3x4xFramesNumber
%           depth_range                 - min and max distance of the
%                                         accepted voxels wrt camera
%           display_projected_voxels    - draw projected voxels on the silhouet image 
%                                         default - 0
% 
%  output:  voxels                      - array of voxels data VoxelsNbx4
%                                         each line represents
%                                         coordinates (X, Y, Z)
%                                         of a voxel center and
%                                         a accumulated image data
%           cumulCount                  - column vector containing how many
%                                         intensity values were acccumulated
%                                         for each voxel [VoxelsNbx1] 
function [voxels, cumulCount] = CreateVisualHull(silhouettes, voxels, K, M, depth_range, display_projected_voxels)

if ~exist('display_projected_voxels', 'var')
    display_projected_voxels = 0;
end

if(display_projected_voxels == 1)
    fid = figure;
else
    fid = -1;
end

object_points3D = [voxels(:,1)'; voxels(:,2)'; voxels(:,3)'; ones(1, length(voxels))];
voxels(:, 4) = zeros(size(voxels(:, 4)));

voxel_inds = {};
img_vals = {};

dmin = depth_range(1);
dmax = depth_range(2);

img_size = size(silhouettes);

% parfor(i = 1:size(M,3))
for i = 1:size(M,3)

    r = M(1:3, 1:3, i);
    t = M(1:3, 4, i);    

    if t == [0;0;0]
        continue;
    end
    
    center = [-(r')* t; 1]; % center of field curvature set to camera center
%     center = [(r')*([35;0;40]-t); 1]; % actual center of field curvature

    cam_center = repmat(center, 1, size(object_points3D,2));
  
    KM = [K]*M(1:3, 1:4, i);

    % projecting voxels centers to image    
    points2D = KM*object_points3D;
    points2D = points2D./[points2D(3,:); points2D(3,:); points2D(3,:)];
    
    cur_silhouette = silhouettes(:,:,i);
    
    % mask to locate bright pixels
    pixThresh = mean(cur_silhouette(:)) + std(cur_silhouette(:));
    cur_mask = cur_silhouette > pixThresh;
    saliencyFlag = zeros(1,size(points2D,2),'logical');
    for ii = 1:size(points2D,2)
        if points2D(2,ii) > 1 && points2D(2,ii) < img_size(1) && ...
           points2D(1,ii) > 1 && points2D(1,ii) < img_size(2)
            saliencyFlag(ii) = cur_mask(round(points2D(2,ii)),round(points2D(1,ii)));
        end
    end
    
    % bypass saliency test
    saliencyFlag = ones(1,size(points2D,2),'logical');
    
    d = sqrt(sum((cam_center - object_points3D).^2, 1));
    pts_ind = find(... %d > dmin & d < dmax ...
        points2D(2,:) > 1 & points2D(2,:) < img_size(1) ...
        & points2D(1,:) > 1 & points2D(1,:) < img_size(2) ...
        & saliencyFlag);

     pi = points2D(1,pts_ind);
     pj = points2D(2,pts_ind);
    
    
    [img_val, ind, object_points_cam] = GetSilhouetVals([pi;pj],  cur_silhouette);
    
    ind = pts_ind(ind);

    voxel_inds{i} = ind;
    img_vals{i} = img_val;

%     display_projected_voxels = 1;
    if(display_projected_voxels)
        figure(fid), 
        imagesc(cur_silhouette);title(i);hold on
        plot(object_points_cam(1,:), object_points_cam(2,:), '.g');hold off
        pause;
    end
end

cumulCount = zeros(size(voxels,1),1);

for i=1:size(voxel_inds,2)
    ind = voxel_inds{i};
    img_val = img_vals{i};
    voxels(ind, 4) = voxels(ind, 4) + img_val;
    cumulCount(ind) = cumulCount(ind) + 1;
%     voxels(ind, 4) = max(voxels(ind, 4), img_val);
end

end

function [img_val, ind, object_points_cam] = GetSilhouetVals(points2D, silhouette)
    img_size = size(silhouette);    
    
    pi = floor(points2D(1,:));
    pj = floor(points2D(2,:));
    a = (points2D(1,:) - pi)';
    b = (points2D(2,:) - pj)';
    
    object_points_cam = floor([points2D(1,:); points2D(2,:)]); 
   
    ind_bad = [];

    % increase counter of each voxel for object pixel
    ind_img = int32(sub2ind(img_size(1:2), object_points_cam(2,:)', object_points_cam(1,:)'));
    ind_img(ind_bad) = [];
    img_val = silhouette(uint32(ind_img));
    
    ind_img2 = int32(sub2ind(img_size(1:2), object_points_cam(2,:)'+1, object_points_cam(1,:)'));
    ind_img2(ind_bad) = [];
    img_val2 = silhouette(uint32(ind_img2));
    
    ind_img3 = int32(sub2ind(img_size(1:2), object_points_cam(2,:)', object_points_cam(1,:)'+1));
    ind_img3(ind_bad) = [];
    img_val3 = silhouette(uint32(ind_img3));
    
    ind_img4 = int32(sub2ind(img_size(1:2), object_points_cam(2,:)'+1, object_points_cam(1,:)'+1));
    ind_img4(ind_bad) = [];
    img_val4 = silhouette(uint32(ind_img4));
%     
    ind = 1:size(object_points_cam, 2);
    ind(ind_bad) = [];
    img_val = (1-a(ind)).*(1-b(ind)).*img_val+...
                (a(ind)).*(1-b(ind)).*img_val3+...
                (1-a(ind)).*(b(ind)).*img_val2+...
                (a(ind)).*(b(ind)).*img_val4;
               

end

