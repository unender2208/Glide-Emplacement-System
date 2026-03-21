AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )
ENT.PrintName = "Turret Support"
ENT.Spawnable = false 

if SERVER then 
    function ENT:Initialize()
        self.supportParams = {
            supportModel = "models/props_phx/construct/metal_plate2x2.mdl",
            scale = 1,
            mass = 5
        }
        self:SetupSupport()
    end

    function ENT:SetupSupport( t )
        if self:IsValid() then
            t = t or {}
            local params = self.supportParams 
            if type( t.supportModel ) == "string" then
                params.supportModel = t.supportModel or "models/props_phx/construct/metal_plate2x2.mdl"
                self:SetModel( params.supportModel )
            end

            params.scale = t.scale or 1  

            self:SetModel( params.supportModel )
            self:PhysicsInit( SOLID_VPHYSICS )    
            self:SetMoveType( MOVETYPE_VPHYSICS )
            self:SetSolid( SOLID_VPHYSICS )
            self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )
        end            
    end
end


