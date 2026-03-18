AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

DEFINE_BASECLASS( "base_glide" )

ENT.ChassisModel = "models/props_phx/construct/metal_plate1.mdl"

function ENT:OnPostInitialize()
    self.supports = {} 
    self.supportCount = 0
end

function ENT:CreateSupport( offset, angle, params  ) -- Made specifically for the emplacement base, helps with models that dont have proper physics on the tripod/bipod, or models that are just the gun lol.
    params = params or {}

    local pos = self:LocalToWorld( offset )
    local ang = self:LocalToWorldAngles( angle )
    
    local supportBase = ents.Create( "glide_emplacement_support" )
    supportBase:SetPos( pos )
    supportBase:SetAngles( ang )
    supportBase:Spawn()
    supportBase:SetupSupport( params )
    
    local index = self.supportCount + 1
    self.supportCount = index
    self.supports[index] = supportBase

    self:DeleteOnRemove( supportBase )

    return supportBase
end

--- Implement this base class function.
function ENT:OnDriverExit()
    local keepOn = IsValid( self.lastDriver ) and self.lastDriver:KeyDown( IN_WALK )

    if not self.hasTheDriverBeenRagdolled and not keepOn then
        self:TurnOff()
    end
end

--- Override this base class function.
function ENT:Repair()
    BaseClass.Repair( self )
end

--- Implement this base class function.
function ENT:OnSeatInput( seatIndex, action, pressed )
    if not pressed or seatIndex > 1 then return end
end
