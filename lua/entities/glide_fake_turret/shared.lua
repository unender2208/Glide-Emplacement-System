AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Fake Vehicle Turret" -- Used soley for the angle / rotation stuff, effects, & viewpunch

ENT.Spawnable = false
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

ENT.BulletDamage = 10
ENT.BulletMaxDistance = 50000
ENT.BulletExplosionRadius = 0

function ENT:SetupDataTables()

    self:NetworkVar( "Bool", "IsFiring" )
    self:NetworkVar( "Float", "FireDelay" )
    self:NetworkVar( "Entity", "GunUser" )
    self:NetworkVar( "Entity", "GunBody" )
    self:NetworkVar( "Vector", "BulletOffset" )
    self:NetworkVar( "Angle", "LastBodyAngle" )

    self:NetworkVar( "Int", "ViewpunchMultiplier" )

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

        local fromPos = body:GetPos() + body:GetUp() * self:GetBulletOffset()[3]
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
        local pos = body:LocalToWorld( self:GetBulletOffset() )
        local ang = body:GetAngles()

        self.nextFire = t + self:GetFireDelay()
        self:FireBullet( pos, ang, user, self:GetRight() )
    end

end

function ENT:FireBullet( pos, ang, attacker, shellDir ) -- Effect stuff
  --  local dir = ang:Forward()
  --  local distance = self.BulletMaxDistance

    -- Muzzle flash & trace
   -- local eff = EffectData()
   -- eff:SetOrigin( pos )
   -- eff:SetStart( pos + dir * distance )
   -- eff:SetFlags( 0x4 )
    --eff:SetEntity( self )
   -- util.Effect( "Explosion", eff )

    -- Shells
    --eff = EffectData()
    --eff:SetOrigin( pos - dir * 30 )
    --eff:SetEntity( self )
    --eff:SetMagnitude( 1 )
    --eff:SetRadius( 5 )
    --eff:SetScale( 1 )

    -- Throw shells away from the body
    --if not shellDir then
     --   shellDir = pos - self:GetPos()
    --    shellDir:Normalize()
  --  end
   -- eff:SetAngles( shellDir:Angle() )
    --util.Effect( "RifleShellEject", eff )
end
