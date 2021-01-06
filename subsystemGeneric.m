classdef subsystemGeneric < handle
    
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
    end
       
    methods (Access = protected)
        function out = loadVar(self,var,default)
            out = self.Parent.loadVar([self.MatPrefix var],default);
        end
        
        function saveVar(self,varName,data)
            self.Parent.saveVar([self.MatPrefix varName],data);
        end
    end
end