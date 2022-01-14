classdef VisualHull
    %VisualHull - allows to construct visual hull from a set of images
    
    properties
        data_dir = '';
        file_base = '';
        N = 0;
        
        silhouettes = [];
        DataLoader = [];
        
        voxels = [];
        voxel3Dx = [];
        voxel3Dy = [];
        voxel3Dz = [];
        voxels_number = [];
        voxels_voted = [];
    end
    
    methods
        function obj = VisualHull(data_loader)
            %VisualHull - constructs visual hull from a set of images
            obj.DataLoader = data_loader;
        end
        
        function [obj] = ExtractSilhoueteFromImages(obj, silhouette_threshold)
            %ExtractSilhoueteFromImages - extract an object silhouette from
            %images loaded by data loader using image thresholding

            for i=1:obj.DataLoader.N
                img = obj.DataLoader.imgs(:,:,:,i);
                ch1 = img(:,:,1) > silhouette_threshold;
                ch2 = img(:,:,2) > silhouette_threshold;
                ch3 = img(:,:,3) > silhouette_threshold;
                obj.silhouettes(:,:,i) = (ch1+ch2+ch3)>0;
            end
        end
        
        function obj = CreateVoxelGrid(obj, voxel_nb)
            %CreateVoxelGrid crerate a grid of voxels using bounds estimated
            %from interesction of cameras FOV

            xlim = [obj.DataLoader.MinBound(1) obj.DataLoader.MaxBound(1)];
            ylim = [obj.DataLoader.MinBound(2) obj.DataLoader.MaxBound(2)];
            zlim = [obj.DataLoader.MinBound(3) obj.DataLoader.MaxBound(3)];

            if ~exist('voxel_nb', 'var')
                voxel_nb = [100, 100, 100];
            end
            
            voxel_size = [diff(xlim)/voxel_nb(1), diff(ylim)/voxel_nb(2), diff(zlim)/voxel_nb(3)];
            [obj.voxels, obj.voxel3Dx, obj.voxel3Dy, obj.voxel3Dz, obj.voxels_number] = InitializeVoxels(xlim, ylim, zlim, voxel_size);
        end
        
        function obj = ProjectVoxelsToSilhouette(obj, disp_proj_voxels)
            %ProjectVoxelsToSilhouette - project voxels to each object
            %silhouette and accumlate all the votes
            
            if ~exist('display_projected_voxels', 'var')
                disp_proj_voxels = 0;
            end
            
            disp_proj_voxels = 0;
            camera_depth_range = [-1 1];
            K = obj.DataLoader.K(:,:,1);
            M = obj.DataLoader.M;
            
            [obj.voxels_voted] = CreateVisualHull(obj.silhouettes, obj.voxels, K, M, camera_depth_range, disp_proj_voxels);
        end

        function [] = ShowVH3D(obj, error_amount)
            %ShowVH3D show visula hull in 3D
              
            if ~exist('error_amount', 'var')
                error_amount = 5;
            end
            maxv = max(obj.voxels_voted(:,4));
            iso_value = maxv - round(((maxv)/100)*error_amount)-0.5;
            disp(['max number of votes:' num2str(maxv)])
            disp(['threshold for marching cube:' num2str(iso_value)]);
            
            [voxel3D] = ConvertVoxelList2Voxel3D(obj.voxels_number, obj.voxels_voted);
            [faces, verts, colors]  = isosurface(obj.voxel3Dx, obj.voxel3Dy, obj.voxel3Dz, voxel3D, iso_value, obj.voxel3Dz);

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
            % axis off
            grid on

            cameratoolbar('Show')
            cameratoolbar('SetMode','orbit')
            cameratoolbar('SetCoordSys','y')
        end
        
        
        function [fv] = CalcIsosurface(obj, error_amount)
            %CalcIsosurface - extract isosurface data from voxel grid using
            % maximum nuber of votes - error amount
                
            maxv = max(obj.voxels_voted(:,4));
            iso_value = maxv - round(((maxv)/100)*error_amount)-0.5;
            
            disp(['max number of votes:' num2str(maxv)])
            disp(['threshold for marching cube:' num2str(iso_value)]);

            [voxel3D] = ConvertVoxelList2Voxel3D(obj.voxels_number, obj.voxels_voted);
            fv  = isosurface(obj.voxel3Dx, obj.voxel3Dy, obj.voxel3Dz, voxel3D, iso_value, obj.voxel3Dz);
        end
        
        function [] = ShowVH2DGrid(obj, img_rot_angle)
        %ShowVH2DGrid - show slices of a voxel grid one at a time
                    
            if ~exist('img_rot_angle', 'var')
                img_rot_angle = 0;
            end

            %display voxel grid
            voxels_voted1 = (reshape(obj.voxels_voted(:,4), size(obj.voxel3Dx)));
            maxv = max(obj.voxels_voted(:));
%             fid = figure;
            for j=1:size(voxels_voted1,3)
%                 figure(fid), 
                img = (squeeze(voxels_voted1(:,:,j)));
                if img_rot_angle >0
                    img  = imrotate(img, img_rot_angle);
                end
                imagesc(img, [0 maxv]), title([num2str(j), ' - press any key to continue']), axis equal, 
                pause,
            end
        end
        
        function [] = SaveGeoemtry2STL(obj, filename, error_amount)
        %SaveGeoemtry2STL  - save geometry to stl file
        
            if ~exist('display_projected_voxels', 'var')
                cdate = datestr(now, 'yyyy.mm.dd');
                filename = [obj.DataLoader.PathBase '_VH_' cdate '.stl'];
            end
            
            if ~exist('error_amount', 'var')
                error_amount = 5;
            end
            fv = CalcIsosurface(obj, error_amount);
            patch2stl(filename, fv);
        end
         
    end
end

