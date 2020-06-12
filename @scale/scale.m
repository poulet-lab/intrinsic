classdef scale < handle
    %SCALE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Figure
        mat
        Camera
    end
    
    methods
        function obj = scale(varargin)
            % parse input arguments
            narginchk(2,2)
            p = inputParser;
            addRequired(p,'MatFile',@(n)validateattributes(n,...
                {'matlab.io.MatFile'},{'scalar'}))
            addRequired(p,'Camera',@(n)validateattributes(n,...
                {'camera'},{'scalar'}))
            parse(p,varargin{:})
            obj.mat     = p.Results.MatFile;
            obj.Camera  = p.Results.Camera;
            
        end
        
        varargout = setup(obj)
    end
end

