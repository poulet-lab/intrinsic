classdef subsystemGeneric < handle & matlab.mixin.CustomDisplay
    
    properties (GetAccess = protected, SetAccess = immutable)
        Parent
    end
    
    properties (Abstract, Constant = true, Access = protected)
        MatPrefix
    end
    
    events
        Update
    end
    
    methods
        function self = subsystemGeneric(parent)
            validateattributes(parent,{'intrinsic'},{'scalar'});
            self.Parent = parent;
        end
        
        function out = struct(self)
            props = properties(self);
            out = struct();
            for ii = 1:numel(props)
                out.(props{ii}) = self.(props{ii});
            end
        end
        
%         function out = properties(obj)
%             if nargout == 0
%                 disp(builtin('properties',obj));
%             else
%                 out = sort(builtin('properties',obj));
%             end
%         end
%         
%         function out = fieldnames(obj)
%             out = sort(builtin('fieldnames',obj));
%         end
    end
       
    methods (Access = protected)
        function out = loadVar(self,var,default)
            out = self.Parent.loadVar([self.MatPrefix var],default);
        end
        
        function saveVar(self,varName,data)
            self.Parent.saveVar([self.MatPrefix varName],data);
        end
        
%         function out = getPropertyGroups(obj)
%             out = matlab.mixin.util.PropertyGroup(properties(obj));
%         end
    end
end