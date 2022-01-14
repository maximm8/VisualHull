classdef DataLoader
    %DATALOADER - loads images and camera params jhkj  lkj  kjjnl 

    properties
        data_dir = '';
        file_base = '';
        PathBase = '';
        N = 0;
        imgs = [];
        K = [];
        M = [];
        KM = [];

        MinBound = [];
        MaxBound = [];
    end

    methods
        function obj = DataLoader(data_dir)
            %DATALOADER - loads images and camera params
            obj.data_dir = data_dir;

            params_str = '_par.txt';
            files = dir([data_dir '*' params_str]);
            if length(files) ~= 1
                disp('Cannot find parametrs files')
                return;
            end
            obj.file_base = files(1).name(1:end-length(params_str));

            obj.PathBase = [obj.data_dir obj.file_base];
        end

        function obj = LoadCameraParams(obj)
            %LoadCameraParams - loads intrinsi and extrinsic parameters of
            % each camera from file

            fid = fopen([obj.PathBase '_par.txt'], 'r');
            res = textscan(fid,'%d');
            obj.N = res{1,1};
            for i=1:obj.N
                textscan(fid,'%s',1);
                res = textscan(fid,'%f', 21);
                tmp =res{1}';
                obj.K(:,:,i) = reshape(tmp(1:9), 3, 3)';
                R = reshape(tmp(10:18), 3, 3)';
                t = tmp(19:21)';
                obj.M(:,:,i) = [R t];
                obj.KM(:,:,i) = obj.K(:,:,i)*[R t];
            end
            fclose(fid);

        end

        function obj = LoadImages(obj)
            %LoadImages - loads images from disk

            for i=1:obj.N
                obj.imgs(:,:,:,i) = imread([obj.data_dir obj.file_base num2str(i, '%04i') '.png']);
            end

        end


        function [obj] = CalcFOVUnion(obj, xx, yy, zz)
        %CalcFOVUnion - calc intersection of cameras field of view (FOV)

            nGrid = 101;
            if ~exist('xx', 'var')
                xx = linspace(-1, 1, nGrid);
            end

            if ~exist('yy', 'var')
                yy = linspace(-1, 1, nGrid);
            end

            if ~exist('zz', 'var')
                zz = linspace(-1, 1, nGrid);
            end

            [X, Y, Z] = meshgrid(xx, yy, zz);
            QP = [X(:) Y(:) Z(:)];
            index_intersect = ones([size(QP,1), 1]);

            % iterate over each view
            for camera_ind=1:obj.N
                r = obj.M(1:3, 1:3, camera_ind);
                t = obj.M(1:3, 4, camera_ind);

                fx = obj.K(1, 1, camera_ind);
                fy = obj.K(2, 2, camera_ind);
                ox = obj.K(1, 3, camera_ind);
                oy = obj.K(2, 3, camera_ind);

                img_size = double([size(obj.imgs,1) size(obj.imgs,2)]);
                x_px = [0 0            img_size(2)  img_size(2)];
                y_px = [0 img_size(1)    0          img_size(1)];

                cc = -(r')* t;
                verts = cc';

                % iterate over each corner of the image plane
                for i=1:length(x_px)
                    P0 = [];
                    P0(1,1) = (x_px(i)-ox)/fx;
                    P0(2,1) = (y_px(i)-oy)/fy;
                    P0(3,1) = 1;

                    P1 = r'* P0 -r'* t;
                    verts = [verts; P1(1), P1(2), P1(3)];
                end

                P = verts;
                T = [1 2 3 4;1 3 4 5];
                TR = triangulation(T, P);
                index_intersect = (~isnan(pointLocation(TR, QP))) & index_intersect;
            end

            obj.MinBound =  min(QP(index_intersect,:));
            obj.MaxBound =  max(QP(index_intersect,:));

        end

       function [] = PlotBoudningVolume(obj, face_color, face_alpha)
        %PlotBoudningVolume - plot minimal cube that copntains intersection
        %of all FOVs

           if ~exist('face_color', 'var')
                face_color = 'green';
            end

            if ~exist('face_alpha', 'var')
                face_alpha = 0.1;
            end

            minb = obj.MinBound;
            maxb = obj.MaxBound;

            verts = [minb(1), minb(2), minb(3);
                     maxb(1), minb(2), minb(3);
                     maxb(1), maxb(2), minb(3);
                     minb(1), maxb(2), minb(3);

                     minb(1), minb(2), maxb(3);
                     maxb(1), minb(2), maxb(3);
                     maxb(1), maxb(2), maxb(3);
                     minb(1), maxb(2), maxb(3);];

            faces = [1 2 3;
                     1 3 4;

                     5 6 7;
                     5 7 8;

                     1 4 8;
                     1 8 5;

                     2 3 7;
                     2 7 6;

                     1 2 6;
                     1 6 5;

                     4 3 7;
                     4 7 8;
                     ];

             h = patch('Vertices', verts, 'Faces', faces,'FaceColor', face_color, 'FaceAlpha', face_alpha);
       end


        function [] = PlotFOV(obj, inds, face_color, face_alpha)
        %PlotFOV - displays camera field ofview

            if ~exist('inds', 'var')
                inds = [1:obj.N];
            else
                if isempty(inds)
                    inds = [1:obj.N];
                end
            end

            if ~exist('face_color', 'var')
                face_color = 'blue';
            end

            if ~exist('face_alpha', 'var')
                face_alpha = 0.25;
            end

            % iterate over each view
            for camera_ind=inds
                r = obj.M(1:3, 1:3, camera_ind);
                t = obj.M(1:3, 4, camera_ind);

                fx = obj.K(1, 1, camera_ind);
                fy = obj.K(2, 2, camera_ind);
                ox = obj.K(1, 3, camera_ind);
                oy = obj.K(2, 3, camera_ind);

                img_size = double([size(obj.imgs,1) size(obj.imgs,2)]);
                x_px = [0 0            img_size(2)  img_size(2)];
                y_px = [0 img_size(1)    0          img_size(1)];

                cc = -(r')* t;

                plot3(cc(1), cc(2), cc(3), 'sb');
                text(cc(1), cc(2), cc(3), num2str(camera_ind), 'FontSize', 22, 'Color', 'r');
                verts = cc';

                % iterate over each corner of the image plane
                for i=1:length(x_px)
                    P0 = [];
                    P0(1,1) = (x_px(i)-ox)/fx;
                    P0(2,1) = (y_px(i)-oy)/fy;
                    P0(3,1) = 1;

                    P1 = r'* P0 -r'* t;

                    line([cc(1) P1(1)], [cc(2) P1(2)], [cc(3) P1(3)], 'Color', 'b', 'LineWidth', 2);
                    verts = [verts; P1(1), P1(2), P1(3)];
                end

                faces = [0 1 3; 0 1 2; 0 2 4; 0 4 3]+1;
                h= patch('Vertices', verts, 'Faces', faces,'FaceColor', face_color);
                set(h,'FaceAlpha', face_alpha);
                axis equal
            end

        end

    end
end

