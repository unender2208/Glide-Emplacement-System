AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

DEFINE_BASECLASS( "base_glide" )

function ENT:OnPostInitialize()
    self.supports = {} 
    self.supportCount = 0
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
  --  print( action )
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

function ENT:CreateEmplacementTurret( vehicle, offset, angles ) -- Since idk how to do the whole Glide.CreateThing present in glide/server/weaponry, im setting it here
    local turret = ents.Create( "glide_emplacement_turret" )

    if not turret or not IsValid( turret ) then
        vehicle:Remove()
        error( "Failed to spawn turret! Vehicle removed!" )
        return
    end

    vehicle:DeleteOnRemove( turret )

    if vehicle.turretCount then
        vehicle.turretCount = vehicle.turretCount + 1
    end

    turret:SetParent( vehicle )
    turret:SetLocalPos( offset )
    turret:SetLocalAngles( angles )
    turret:Spawn()

    return turret    
end

function ENT:CreateFakeTurret( vehicle, offset, angles ) -- Useful for vehicles that use a VSWEP, such as the TOW and Kornet. All it does is rmeove the capabilites to fire things but still keeps the turret body for orientation purposes + the camera shake
    local turret = ents.Create( "glide_fake_turret" )

    if not turret or not IsValid( turret ) then
        vehicle:Remove()
        error( "Failed to spawn turret! Vehicle removed!" )
        return
    end

    vehicle:DeleteOnRemove( turret )

    if vehicle.turretCount then
        vehicle.turretCount = vehicle.turretCount + 1
    end

    turret:SetParent( vehicle )
    turret:SetLocalPos( offset )
    turret:SetLocalAngles( angles )
    turret:Spawn()

    return turret    
end