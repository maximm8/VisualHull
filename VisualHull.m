classdef VisualHull
    %VISUALHULL Summary of this class goes here
    %   Detailed explanation goes here
    
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
        
%         fv = [];
    end
    
    methods
        function obj = VisualHull(data_loader)
            %VISUALHULL Construct an instance of this class
            %   Detailed explanation goes here
%             obj.data_dir = data_dir;
            obj.DataLoader = data_loader;
            
%             params_str = '_par.txt'; 
%             files = dir([data_dir '*' params_str]);
%             if length(files) ~= 1
%                 disp('Cannot find parametrs files')
%                 return;
%             end
%             obj.file_base = files(1).name(1:end-length(params_str));
        end
        
%         function outputArg = LoadCameraParams(obj, inputArg)
%             %METHOD1 Summary of this method goes here
%             %   Detailed explanation goes here
%             
%             fid = fopen([obj.data_dir obj.file_base '_par.txt'], 'r');
%             res = textscan(fid,'%d');
%             obj.N = res{1,1};
%             for i=1:obj.N
%                 textscan(fid,'%s',1);
%                 res = textscan(fid,'%f', 21);
%                 tmp =res{1}';
%                 K = reshape(tmp(1:9), 3, 3)';
%                 R = reshape(tmp(10:18), 3, 3)';
%                 t = tmp(19:21)';
%                 M(:,:,i) = [R t];
%                 KM(:,:,i) = K*[R t];
%             end
%             fclose(fid);
% 
%             
% %             outputArg = obj.Property1 + inputArg;
%         end
        
%         function outputArg = LoadImages(obj, inputArg)
%             %METHOD1 Summary of this method goes here
%             %   Detailed explanation goes here
%             
%             for i=1:obj.N
%                 obj.imgs(:,:,:,i) = imread([obj.data_dir obj.file_base num2str(i, '%04i') '.png']);
%             end
% 
%             
% %             outputArg = obj.Property1 + inputArg;
%         end
        
        function [obj] = ExtractSilhoueteFromImages(obj, silhouette_threshold)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            for i=1:obj.DataLoader.N
                img = obj.DataLoader.imgs(:,:,:,i);
                ch1 = img(:,:,1) > silhouette_threshold;
                ch2 = img(:,:,2) > silhouette_threshold;
                ch3 = img(:,:,3) > silhouette_threshold;
                obj.silhouettes(:,:,i) = (ch1+ch2+ch3)>0;
            end
        end
        
        function obj = CreateVoxelGrid(obj, voxel_nb)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            switch obj.DataLoader.file_base
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
                xlim = [-0.15 0.05];
                ylim = [-0.05 0.2];
                zlim = [-0.1 0.1];

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

            if ~exist('voxel_nb', 'var')
                voxel_nb = [100, 100, 100];
            end
            
            voxel_size = [diff(xlim)/voxel_nb(1), diff(ylim)/voxel_nb(2), diff(zlim)/voxel_nb(3)];
            [obj.voxels, obj.voxel3Dx, obj.voxel3Dy, obj.voxel3Dz, obj.voxels_number] = InitializeVoxels(xlim, ylim, zlim, voxel_size);

%             outputArg = obj.Property1 + inputArg;
        end
        
        function obj = ProjectVoxelsToSilhouette(obj, display_projected_voxels)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here

            if ~exist('display_projected_voxels', 'var')
                display_projected_voxels = 0;
            end
            
            display_projected_voxels = 0;
            camera_depth_range = [-1 1];
            K = obj.DataLoader.K(:,:,1);
            M = obj.DataLoader.M;
            
            [obj.voxels_voted] = CreateVisualHull(obj.silhouettes, obj.voxels, K, M, camera_depth_range, display_projected_voxels);
        end

        function [] = ShowVH3D(obj, error_amount)
            %METHOD1 Summary of this method goes here
                %   Detailed explanation goes here

            if ~exist('error_amount', 'var')
                error_amount = 5;
            end
            maxv = max(obj.voxels_voted(:,4));
            iso_value = maxv - round(((maxv)/100)*error_amount)-0.5;
            disp(['max number of votes:' num2str(maxv)])
            disp(['threshold for marching cube:' num2str(iso_value)]);
% 
%             [voxel3D] = ConvertVoxelList2Voxel3D(obj.voxels_number, obj.voxels_voted);
% 
%             [obj.fv]  = isosurface(obj.voxel3Dx, obj.voxel3Dy, obj.voxel3Dz, obj.voxel3D, iso_value, obj.voxel3Dz);
            [voxel3D] = ConvertVoxelList2Voxel3D(obj.voxels_number, obj.voxels_voted);
%             fv = CalcIsosurface(obj, error_amount);
            [faces, verts, colors]  = isosurface(obj.voxel3Dx, obj.voxel3Dy, obj.voxel3Dz, voxel3D, iso_value, obj.voxel3Dz);
            
            %fid = figure; 

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
            %METHOD1 Summary of this method goes here
                %   Detailed explanation goes here
            maxv = max(obj.voxels_voted(:,4));
            iso_value = maxv - round(((maxv)/100)*error_amount)-0.5;
            disp(['max number of votes:' num2str(maxv)])
            disp(['threshold for marching cube:' num2str(iso_value)]);

            [voxel3D] = ConvertVoxelList2Voxel3D(obj.voxels_number, obj.voxels_voted);

            fv  = isosurface(obj.voxel3Dx, obj.voxel3Dy, obj.voxel3Dz, voxel3D, iso_value, obj.voxel3Dz);
        end
        
        function [] = ShowVH2DGrid(obj, img_rot_angle)
        %METHOD1 Summary of this method goes here
                    %   Detailed explanation goes here
                    
                    
            
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
        
% %         function outputArg = ShowVoxelGrid3D(obj, inputArg)
% %         %METHOD1 Summary of this method goes here
% %                     %   Detailed explanation goes here
% % 
% %         display_projected_voxels = 0;
% %         camera_depth_range = [-1 1];
% %         [voxels_voted] = CreateVisualHull(silhouettes, voxels, K, M, camera_depth_range, display_projected_voxels);
% % 
% %         %             outputArg = obj.Property1 + inputArg;
% %         end
% %         
%         function outputArg = ShowVoxelsImages(obj, inputArg)
%         %METHOD1 Summary of this method goes here
%                     %   Detailed explanation goes here
% 
%         display_projected_voxels = 0;
%         camera_depth_range = [-1 1];
%         [voxels_voted] = CreateVisualHull(silhouettes, voxels, K, M, camera_depth_range, display_projected_voxels);
% 
%         %             outputArg = obj.Property1 + inputArg;
%         end
        
        function [] = SaveGeoemtry2STL(obj, filename, error_amount)
        %METHOD1 Summary of this method goes here
        %   Detailed explanation goes here
        
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

