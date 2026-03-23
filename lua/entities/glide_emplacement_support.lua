AddCSLuaFile()

DEFINE_BASECLASS( "base_anim" )
ENT.PrintName = "Turret Support"
ENT.Spawnable = false 

if SERVER then 
    function ENT:Initialize()
        self.supportParams = {
            supportModel = "models/props_phx/construct/metal_plate2x2.mdl",
            mass = 500
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
            params.mass = t.mass or 500

            self:SetModel( params.supportModel )
            self:PhysicsInit( SOLID_VPHYSICS )    
            self:SetMoveType( MOVETYPE_VPHYSICS )
            self:SetSolid( SOLID_VPHYSICS )
            self:SetCollisionGroup( COLLISION_GROUP_DEBRIS )

            self:GetPhysicsObject():SetMass( params.mass )
        end            
    end
end


