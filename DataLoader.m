classdef DataLoader
    %DATALOADER Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        data_dir = '';
        file_base = '';
        PathBase = '';
        N = 0;
        imgs = [];
        K = [];
        M = [];
        KM = [];
    end
    
    methods
        function obj = DataLoader(data_dir)
            %DATALOADER Construct an instance of this class
            %   Detailed explanation goes here
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
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
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
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            for i=1:obj.N
                obj.imgs(:,:,:,i) = imread([obj.data_dir obj.file_base num2str(i, '%04i') '.png']);
            end
            
        end
        
        
        
    end
end

