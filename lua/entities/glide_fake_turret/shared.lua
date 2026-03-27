AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Fake Vehicle Turret" -- Used soley for the angle / rotation stuff, effects, & viewpunch. Useful for VSWEP's or anything that dosent fire the traditional bullet

ENT.Spawnable = false
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

function ENT:SetupDataTables()
    self:NetworkVar( "Bool", "IsFiring" )
    self:NetworkVar( "Float", "FireDelay" )
    self:NetworkVar( "Entity", "GunUser" )
    self:NetworkVar( "Entity", "GunBody" )
    self:NetworkVar( "Angle", "LastBodyAngle" )

    self:NetworkVar( "Int", "ViewpunchMultiplier" )
    self:NetworkVar( "Bool", "EnableFiringEffect" )
    self:NetworkVar( "Vector", "EffectOffset" )  
    self:NetworkVar( "Vector", "EffectDirection" )  -- Sets the direction of our effect, has to be a normal vector
    self:NetworkVar( "String", "EffectType" ) 

    self:NetworkVar( "Float", "MinPitch" )
    self:NetworkVar( "Float", "MaxPitch" )
    self:NetworkVar( "Float", "MinYaw" )
    self:NetworkVar( "Float", "MaxYaw" )
end

local IsValid = IsValid
local CurTime = CurTime

function ENT:Think()
    local t = CurTime()

    if SERVER then
        self:NextThink( t )
    end

    if CLIENT then
        self:SetNextClientThink( t )
    end

    local parent = self:GetParent()
    local body = self:GetGunBody()

    if IsValid( parent ) and IsValid( body ) then
        self:UpdateTurret( parent, body, t )
    end

    return true
end

local Clamp = math.Clamp
local LocalPlayer = LocalPlayer
local CanUseWeaponry = Glide.CanUseWeaponry

function ENT:UpdateTurret( parent, body, t )
    local user = self:GetGunUser()

    -- Only let the server and the current user's client to run the logic below.
    if not SERVER and not ( CLIENT and LocalPlayer() == user ) then return end

    if IsValid( user ) then
        self:SetIsFiring( user:KeyDown( 1 ) and CanUseWeaponry( user ) ) -- IN_ATTACK

        local fromPos = body:GetPos() + body:GetUp() * self:GetEffectOffset()[3]
        local aimPos = SERVER and user:GlideGetAimPos() or Glide.GetCameraAimPos()
        local dir = aimPos - fromPos
        dir:Normalize()

        local ang = parent:WorldToLocalAngles( dir:Angle() )

        ang[1] = Clamp( ang[1], self:GetMinPitch(), self:GetMaxPitch() )

        local minYaw, maxYaw = self:GetMinYaw(), self:GetMaxYaw()

        if minYaw ~= -1 and maxYaw ~= -1 then
            ang[2] = Clamp( ang[2], minYaw, maxYaw )
        end

        ang[3] = 0

        body:SetLocalAngles( ang )

        if SERVER or LocalPlayer() == user then
            self:SetLastBodyAngle( ang )
        end

        if CLIENT then
            self.nextPunch = self.nextPunch or 0

            if self:GetIsFiring() and t > self.nextPunch then
                self.nextPunch = t + self:GetFireDelay()
                Glide.Camera:ViewPunch( -0.05 * self:GetViewpunchMultiplier(), math.Rand( -0.02, 0.02 ), 0 )
            end
        end
    end

    self.nextFire = self.nextFire or 0

    local isFiring = self:GetIsFiring()
    if isFiring and t > self.nextFire then
        self.nextFire = t + self:GetFireDelay()
        if self:GetEnableFiringEffect() then
            local pos = body:LocalToWorld( self:GetEffectOffset() )
            local effectDirection = self:GetEffectDirection()
            self:FireEffect( pos, effectDirection )            
        end
    end
end

function ENT:FireEffect( receivedPos, direction ) -- The ones already in here are sort of a QOL "preset" for cannons/launchers and recoiless rifles
    local eff = EffectData()
    eff:SetOrigin( receivedPos )
    eff:SetScale( 1 )
    if self:GetEffectType() == "cannon" then
        eff:SetNormal( direction )
        util.Effect( "glide_emplacement_cannon", eff ) 
    else
        eff:SetScale( 0.2 )
        util.Effect( "glide_explosion", eff )
    end
end

