AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_emplacement"
ENT.Author = "unender"
ENT.PrintName = "M2 Browning"

DEFINE_BASECLASS( "base_glide_emplacement" )

ENT.GlideCategory = "UNENDER_EMPLACEMENTS"
ENT.ChassisModel = "models/glide/glide_emplacements/m2hb pintle.mdl"

ENT.MaxChassisHealth = 200
ENT.EnableADS = true -- Self explanitory, determines whether or not aiming down sights with right click is allowed on the emplacement

function ENT:SetupDataTables()
    -- Call the base class' `SetupDataTables`
    -- to let it setup required network variables.
    BaseClass.SetupDataTables( self )

    -- Store our turret entity, as well as the seat that controls it.
    self:NetworkVar( "Entity", "Turret" )
    self:NetworkVar( "Entity", "TurretSeat" )
    self:NetworkVar( "Bool", "ChangeAltitude" )
    self:NetworkVar( "Bool", "AimingDownSights" )
end

function ENT:GetSpawnColor()
    return Color( 255, 255, 255)
end

function ENT:UpdatePlayerPoseParameters( _ply ) -- Using this to update the seat pose altitude feature because i cant override ENT:Think or PostThink
    if self:GetChangeAltitude() then
        function self:GetPlayerSitSequence()
            return "ACT_HL2MP_IDLE_CROUCH" -- Pose for when the threshold is passed ( check ENT:OnUpdateFeatures )
        end
    else
        function self:GetPlayerSitSequence()
            return "idle_all_01" -- Pose for when the threshold isint passed ( check ENT:OnUpdateFeatures )
        end
    end
    return false -- What the default return sends back in glide_base/shared
end

if CLIENT then
    ENT.CameraOffset = Vector( -60, 20, 30 )
    ENT.CameraAngleOffset = Angle( 0, 0, 0 )

    -- Temporary variables to move/rotate the turret's bones and seat.
    local ang = Angle()
    local matrix = Matrix()

    local Camera = Glide.Camera
    local crosshairInfo = { iconType = "dot", color = Color( 255, 255, 255), size = 0.02 }

    function ENT:OnActivateMisc()
        -- Let the base class do some initialization
        BaseClass.OnActivateMisc( self )

        -- Store the bones that control the turret's base and weapon
        self.turretBaseBone = self:LookupBone( "pintle_rot" )
        self.turretWeaponBone = self:LookupBone( "pintle_elev" )
    end

    function ENT:OnUpdateAnimations()
        -- Call the base class' `OnUpdateAnimations`
        -- to automatically update the steering pose parameter.
        BaseClass.OnUpdateAnimations( self )

        local turret = self:GetTurret()
        if not IsValid( turret ) then return end

        local bodyAng = turret:GetLastBodyAngle()
        local seat = self:GetTurretSeat()

        if IsValid( seat ) then
            ang[1] = 0
            ang[2] = bodyAng[2]
            ang[3] = 0

            matrix:SetAngles( ang )
            seat:EnableMatrix( "RenderMultiply", matrix )
        end

        if not self.turretBaseBone then return end

        -- Using the turret's body angle,
        -- rotate our turret base/weapon bones.
        bodyAng[1] = math.NormalizeAngle( bodyAng[1] ) -- Stay on the -180/180 range

        ang[1] = 0
        ang[2] = 0
        ang[3] = bodyAng[2]
        self:ManipulateBoneAngles( self.turretBaseBone, ang )

        ang[1] = bodyAng[1]
        ang[2] = 0
        ang[3] = 0
        self:ManipulateBoneAngles( self.turretWeaponBone, ang )

        function self:GetFirstPersonOffset( seatIndex, localEyePos )
            if self:GetAimingDownSights() then
                self:DisableCrosshair()
                localEyePos = self:AimDownSights( 5.6, -30 ) -- Function made specifically for this entity base, first value is the up/down offset meanwhile the second value is the forward/back offset.
            elseif not self:GetChangeAltitude() then
                self:EnableCrosshair( crosshairInfo )
                localEyePos[3] = localEyePos[3] + 34
            else
                self:EnableCrosshair( crosshairInfo )
            end
            return localEyePos
        end
    end

    function ENT:OnLocalPlayerExit()
        self:DisableCrosshair()
    end

    function ENT:OnLocalPlayerEnter()
        self:EnableCrosshair( crosshairInfo )
    end

    -- This function runs every frame when the crosshair is enabled.
    function ENT:UpdateCrosshairPosition()
        -- Put right at the local player's camera aim position.
        self.crosshair.origin = Glide.GetCameraAimPos()
    end

    -- Override the default camera type for the turret seat
    function ENT:GetCameraType( seatIndex )
        return 1
    end

    -- Don't muffle sounds while sitting on the turret seat,
    -- or on the rear exterior seats.
    function ENT:AllowFirstPersonMuffledSound( seatIndex )
        return false
    end
end

if SERVER then
    ENT.SpawnPositionOffset = Vector( 0, 0, 45 )
    ENT.ChassisMass = 0
    ENT.BulletDamageMultiplier = 0.5

    ENT.FallOnCollision = true
    ENT.FallWhileUnderWater = true

    -- Allow the passengers of seats created after
    -- the turret seat to fall off the vehicle.
    function ENT:CanFallOnCollision( seatIndex )
        return true
    end

    function ENT:CreateFeatures()
        local turretSeat = self:CreateSeat( Vector( 0, 0, 0 ), Angle( 0, 270, 0 ), Vector( -80, -100, 0 ), true  )

        -- Store the seat to be used client-side
        self:SetTurretSeat( turretSeat )

        local turret = self:CreateEmplacementTurret( self, Vector( -0, 0, 20 ), Angle() )
        turret:SetFireDelay( 0.10 )
        turret:SetBulletOffset( Vector( 46, 0, 0 ) )
        turret:SetShellCasingsOffsetY( 49 )
        turret:SetMinPitch( -20 )
        turret:SetMaxPitch( 30 )
        turret:SetMinYaw( -90 )
        turret:SetMaxYaw( 90 )
        turret:SetViewpunchMultiplier( 5 )
        turret:SetShootLoopSound( "glide/glide_emplacement_base/glide_m2/m2_loop.wav" )
        turret:SetShootStopSound( "glide/glide_emplacement_base/glide_m2/m2_lastshot.wav" )

        turret.BulletDamage = 40
        Glide.HideEntity( turret, true )
        Glide.HideEntity( turret:GetGunBody(), true )

        -- Store the turret to be used client-side
        self:SetTurret( turret )

        self:CreateSupport( Vector( 0, 0, 0 ), Angle( 0, 0, 0 ), {
            supportModel = "models/glide/glide_emplacements/m3 tripod.mdl"
        } )

        for _, w in ipairs( self.supports ) do
            local weld = constraint.Weld( w, self, 0, 0, 0, true, true ) -- Connects the created support to the gun/chassis itself
            Glide.HideEntity( w, false )
        end

        self:SetBodygroup( 12, 3 )
        self:SetBodygroup( 14, 1 )
    end

    function ENT:OnUpdateFeatures()  -- Due to weird jittering effects on moving the seat in client, im doing it here. Sorry!
        local turret = self:GetTurret()
        if IsValid( turret ) then
            -- The player on our "turret seat" should be the user of the actual turret entity.
            turret:UpdateUser( self:GetSeatDriver( 1 ) )
        else return end
        local bodyAng = turret:GetLastBodyAngle() 
        local seat = self:GetTurretSeat()

        local offset = Vector()
        local radius = 50 -- You dont HAVE to make a separate variable for the radius, just putting this here for anyone needing reference.
        local altitudeTreshhold = -2 -- How low the entity has to be to enable the crouch/prone firing pose ( cool right ), you also dont need to set a separate var for this
        local altitudeTrace = util.TraceLine({
            start = self:GetPos() + self:GetForward() * -28, -- Offsetting the start & end to around where the turret handle is 
            endpos = ( self:GetPos() + self:GetForward() * -28 ) + ( self:GetUp() * altitudeTreshhold )
        })

        if IsValid( seat ) then
            local rad = math.rad( bodyAng[2] ) -- The angle we're using as reference
            local altitudeSet = 0
            if altitudeTrace.Hit then
                self:SetChangeAltitude( true )
                altitudeSet = -4 -- How low?
            else
                self:SetChangeAltitude( false )
                altitudeSet = -40 -- How high?
            end

            offset[1] = math.cos( rad ) * -radius --  You may have to fiddle with the radius value and the order of the sin/cos stuff to get it perfectly behind something. Math BS
            offset[2] = math.sin( rad ) * -radius -- ^^^^
            offset[3] = altitudeSet -- Sets the seat on the "ground"

            local LTWVector = LocalToWorld( Vector( offset ), bodyAng, self:GetPos(), self:GetAngles() )
            seat:SetPos( LTWVector )
        end
    end

    function ENT:OnSeatInput( seatIndex, action, pressed )
        if self.EnableADS then
            if action == "aim_down_sights" and pressed then
                self:SetAimingDownSights( true )
            elseif action == "aim_down_sights" and not pressed then
                self:SetAimingDownSights( false )
            end
        end
    end
end