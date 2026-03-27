AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_emplacement"
ENT.Author = "unender"
ENT.PrintName = "SPG-9 'Spear' "

DEFINE_BASECLASS( "base_glide_emplacement" )

ENT.GlideCategory = "UNENDER_EMPLACEMENTS"
ENT.ChassisModel = "models/glide/glide_emplacements/w_spg9.mdl"

ENT.MaxChassisHealth = 200
ENT.ChassisMass = 1000

function ENT:SetupDataTables()
    -- Call the base class' `SetupDataTables`
    -- to let it setup required network variables.
    BaseClass.SetupDataTables( self )

    self:NetworkVar( "Bool", "FiringGun" )

    -- Store our turret entity, as well as the seat that controls it.
    self:NetworkVar( "Entity", "Turret" )
    self:NetworkVar( "Entity", "TurretSeat" )
end

function ENT:GetSpawnColor()
    return Color( 255, 255, 255)
end

function ENT:GetPlayerSitSequence( seatIndex )
    return "ACT_HL2MP_IDLE_CROUCH"
end

if CLIENT then
    ENT.CameraOffset = Vector( -60, 0, 50 )
    ENT.CameraAngleOffset = Angle( 0, 0, 0 )

    ENT.WeaponInfo = {
        [1] = { name = "Propelled Grenade" }
    }

    -- Temporary variables to move/rotate the turret's bones and seat.
    local ang = Angle()
    local matrix = Matrix()

    function ENT:OnActivateMisc()
        -- Let the base class do some initialization
        BaseClass.OnActivateMisc( self )

        -- Store the bones that control the turret's base and weapon
        self.turretBaseBone = self:LookupBone( "BarrelRotate" )
        self.turretWeaponBone = self:LookupBone( "Barrel" )
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
        ang[2] = bodyAng[2]
        ang[3] = 0
        self:ManipulateBoneAngles( self.turretBaseBone, ang )

        ang[1] = 0
        ang[2] = 0
        ang[3] = bodyAng[1]
        self:ManipulateBoneAngles( self.turretWeaponBone, ang )

        function self:GetFirstPersonOffset( seatIndex, localEyePos )
            local Camera = Glide.Camera
            local vehicle = Camera.vehicle
            local rad = math.rad( bodyAng[2] ) -- The angle we're using as reference
            localEyePos = vehicle:WorldToLocal( self:GetPos() ) 
            localEyePos[3] = localEyePos[3] + 40
            localEyePos[2] = localEyePos[2] + math.cos( rad ) * 10
            localEyePos[1] = localEyePos[1] + math.sin( rad ) * -10

            return localEyePos
        end
    end

    -- Override the default camera type for the turret seat
    function ENT:GetCameraType( seatIndex )
        return 1
    end

    function ENT:OnLocalPlayerEnter( seatIndex )
        self:DisableCrosshair()
        -- Enable the crosshair when a player enters the turret seat
        self:EnableCrosshair( { iconType = "dot", color = Color( 255, 255, 255), size = 0.03 })
        -- Let the base class handle it
        BaseClass.OnLocalPlayerEnter( self, seatIndex )
    end

    function ENT:OnLocalPlayerExit()
        self:DisableCrosshair()
    end

    local SEAT_1_POSE = {
        ["ValveBiped.Bip01_Pelvis"] = Angle( 0, 0, 0 )
    }

    function ENT:GetSeatBoneManipulations( seatIndex )
        return SEAT_1_POSE
    end

    -- This function runs every frame when the crosshair is enabled.
    function ENT:UpdateCrosshairPosition()
        -- Put right at the local player's camera aim position.
        self.crosshair.origin = Glide.GetCameraAimPos()
    end

    -- Don't muffle sounds while sitting on the turret seat,
    -- or on the rear exterior seats.
    function ENT:AllowFirstPersonMuffledSound( seatIndex )
        return false 
    end

end

if SERVER then
    ENT.SpawnPositionOffset = Vector( 0, 0, 45 )
    ENT.ChassisMass = 500

    ENT.FallOnCollision = true
    ENT.FallWhileUnderWater = true

    -- Allow the passengers of seats created after
    -- the turret seat to fall off the vehicle.
    function ENT:CanFallOnCollision( seatIndex )
        return true 
    end

    function ENT:CreateFeatures()

        self:CreateWeapon( "emplacement_propelled_grenade_launcher", {
            MaxAmmo = 1,
            FireDelay = 1.0,
            ReloadDelay = 8.0,
            ProjectileDamageMult = 10,
            ProjectileOffsets = {Vector( -12.5, 0, 33.7 )},
            EnableReloadSequence = true,
            ReloadStartSound = "glide/glide_emplacement_base/glide_spg9/reload.wav",
            SingleShotSound = "glide/glide_emplacement_base/glide_spg9/fire.wav",
            MissileModel = "models/glide/glide_emplacements/pg9.mdl",
            MissileBodygroupDelay = 0.25,
            MissileBodyGroup = { 1, 1 },
            FiringAnimation = "fire"
        } )

        local turretSeat = self:CreateSeat( Vector( 0, 0, 0 ), Angle( 0, 270, 0 ), Vector( -80, -100, 0 ), true  )
        local turret = self:CreateFakeTurret( self, Vector( -0, 0, 0 ), Angle() )
        turret:SetMinYaw( -18 )
        turret:SetMaxYaw( 18 )
        turret:SetMinPitch( -3 )
        turret:SetMaxPitch( 3 )
        turret:SetFireDelay( 8 )
        turret:SetEnableFiringEffect( true )
        turret:SetEffectType( "cannon" ) -- Selecting what sort of effect we want, check the github / decomp this and look in fake_glide_turret/shared for examples
        turret:SetEffectOffset( Vector ( -30, 0, 35 ) )
        turret:SetEffectDirection( self:GetForward() * -1 )
        turret:SetViewpunchMultiplier( 80 )

        Glide.HideEntity( turret, true )
        Glide.HideEntity( turret:GetGunBody(), true )

        -- Store the turret to be used client-side
        self:SetTurret( turret )
        -- Store the seat to be used client-side
        self:SetTurretSeat( turretSeat )

    end

    function ENT:OnUpdateFeatures() -- Due to weird jittering effects on moving the seat in client, im doing it here.
        local turret = self:GetTurret()
        if IsValid( turret ) then
            -- The player on our "turret seat" should be the user of the actual turret entity
            turret:UpdateUser( self:GetSeatDriver( 1 ) )
        end
        
        local bodyAng = turret:GetLastBodyAngle() 
        local seat = self:GetTurretSeat()

        local offset = Vector()
        local radius = 10 -- You dont HAVE to make a separate variable for the radius, just putting this here for anyone needing help reading
        
        if IsValid( seat ) then
            local rad = math.rad( bodyAng[2] ) -- The angle we're using as reference ( yaw  )
            local forward = bodyAng:Forward() -- Getting the forward so that bring the seat slightly back to line up w the model's sights

            offset[1] = math.sin( rad ) * -radius --  You may have to fiddle with the radius value and the order of the sin/cos stuff to get it perfectly behind something. Math BS
            offset[2] = math.cos( rad ) * radius -- ^^^^
            offset[3] = -5 -- Sets the seat on the "ground".

            local LTWVector = LocalToWorld( Vector( offset ) + forward * -40, bodyAng, self:GetPos(), self:GetAngles() )
            seat:SetPos( LTWVector )
        end
    end
    
end

