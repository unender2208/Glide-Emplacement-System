AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )

include( "shared.lua" )

util.AddNetworkString( "CrosshairAimPos" )

ENT.aimPos = nil

function ENT:Initialize()
    self:SetModel( "models/glide/weapons/homing_rocket.mdl" )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:PhysicsInit( SOLID_VPHYSICS )
    self:DrawShadow( false )

    local phys = self:GetPhysicsObject()

    if IsValid( phys ) then
        phys:Wake()
        phys:SetAngleDragCoefficient( 1 )
        phys:SetDragCoefficient( 0 )
        phys:EnableGravity( false )
        phys:SetMass( 20 )
        phys:SetVelocityInstantaneous( self:GetForward() * 500 )

        self:StartMotionController()
    end

    self.radius = 350
    self.damage = 1500
    self.lifeTime = CurTime() + 10
    self.acceleration = 8000
    self.maxSpeed = 4000 -- This appears to be the default limit of the physics engine
    self.turnRate = 80 -- degrees/s
    self.missThreshold = 0

    self.target = NULL
    self.speed = 0
    self.aimDir = nil

    self.applyThrust = true
    self.flareExplodeRadius = 200 * 200

    self:SetEffectiveness( 0 )
end

local IsValid = IsValid

function ENT:SetupMissile( attacker, parent )
    -- Set which player created this missile
    self.attacker = attacker

    -- Don't collide with our parent entity
    self:SetOwner( parent )
end

function ENT:Explode()
    if self.hasExploded then return end

    -- Don't let stuff like collision events call this again
    self.hasExploded = true

    Glide.CreateExplosion( self, self.attacker, self:GetPos(), self.radius, self.damage, -self:GetForward(), Glide.EXPLOSION_TYPE.MISSILE )

    self.attacker = nil
    self:Remove()
end

function ENT:PhysicsCollide( data )
    -- Silently remove this missile when hitting the skybox
    if data.TheirSurfaceProps == 76 then
        self:Remove()
        return
    end

    self:Explode()
end

function ENT:OnTakeDamage( dmginfo )
    if not self.hasExploded and not dmginfo:IsExplosionDamage() then
        self:Explode()
    end
end

local FrameTime = FrameTime
local Approach = math.Approach
local TraceHull = util.TraceHull

local ray = {}

local traceData = {
    output = ray,
    filter = { NULL, NULL },
    mask = MASK_PLAYERSOLID,
    maxs = Vector(),
    mins = Vector()
}

function ENT:Think()
    net.Receive("CrosshairAimPos", function ()
        self.aimPos = net.ReadVector()
    end)
    
    local t = CurTime()
    if t > self.lifeTime then
        self:Explode()
        return
    end
    self:NextThink( t )

    local phys = self:GetPhysicsObject()

    if not self.applyThrust or not IsValid( phys ) then
        return true
    end

    if self:WaterLevel() > 0 then
        self.applyThrust = false
        phys:EnableGravity( true )
        return true
    end

    local dt = FrameTime()

    self:SetEffectiveness( Approach( self:GetEffectiveness(), 1, dt  ) )

    -- Point towards the target
    local myPos = self:GetPos()
    local fw = self:GetForward()
    local targetPos = self.aimPos or Vector()
    local dir = targetPos - myPos
    dir:Normalize()

    -- If the target is outside our FOV, stop tracking it
    if math.abs( dir:Dot( fw ) ) < self.missThreshold then
        self.target = nil
        self.aimDir = nil
    else
        -- Let PhysicsSimulate handle this
        self.aimDir = dir
    end
    
    traceData.start = myPos
    traceData.endpos = myPos + self:GetVelocity() * dt * 2
    traceData.filter[1] = self
    traceData.filter[2] = self:GetOwner()

    -- Trace result is stored on `ray`
    TraceHull( traceData )

    if not ray.HitSky and ray.Hit then
        self:Explode()
    end

    return true
end

local ApproachAngle = math.ApproachAngle
local ZERO_VEC = Vector()

function ENT:PhysicsSimulate( phys, dt )
    if not self.applyThrust then return end

    -- Accelerate to reach maxSpeed
    if self.speed < self.maxSpeed then
        self.speed = self.speed + self.acceleration * dt
    end

    if self.aimDir then
        local myAng = self:GetAngles()
        local targetAng = self.aimDir:Angle()
        local rate = self.turnRate * dt

        myAng[1] = ApproachAngle( myAng[1], targetAng[1], rate )
        myAng[2] = ApproachAngle( myAng[2], targetAng[2], rate )
        myAng[3] = ApproachAngle( myAng[3], targetAng[3], rate )

        phys:SetAngles( myAng )
    end

    phys:SetAngleVelocityInstantaneous( ZERO_VEC )
    phys:SetVelocityInstantaneous( self:GetForward() * self.speed )
end
