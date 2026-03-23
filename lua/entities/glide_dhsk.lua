AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_glide_emplacement"
ENT.Author = "unender"
ENT.PrintName = "DShK M1938"

DEFINE_BASECLASS( "base_glide_emplacement" )

ENT.GlideCategory = "UNENDER_EMPLACEMENTS"
ENT.ChassisModel = "models/glide/glide_emplacements/dshkm tripod.mdl"

ENT.MaxChassisHealth = 200

function ENT:SetupDataTables()
    -- Call the base class' `SetupDataTables`
    -- to let it setup required network variables.
    BaseClass.SetupDataTables( self )

    -- Store our turret entity, as well as the seat that controls it.
    self:NetworkVar( "Entity", "Turret" )
    self:NetworkVar( "Entity", "TurretSeat" )
end

function ENT:GetSpawnColor()
    return Color( 255, 255, 255)
end

if CLIENT then
    ENT.CameraOffset = Vector( -60, 20, 20 )
    ENT.CameraAngleOffset = Angle( 0, 0, 0 )

    local Camera = Glide.Camera
    -- Temporary variables to move/rotate the turret's bones and seat.
    local ang = Angle()
    local matrix = Matrix()

    function ENT:OnLocalPlayerEnter( seatIndex )
        self:DisableCrosshair()
        -- Enable the crosshair when a player enters the turret seat
        self:EnableCrosshair( { iconType = "dot", color = Color( 255, 0, 0), size = 0.02 })
        -- Let the base class handle it
        BaseClass.OnLocalPlayerEnter( self, seatIndex )
    end

    function ENT:OnLocalPlayerExit()
        self:DisableCrosshair()
    end

    -- This function runs every frame when the crosshair is enabled.
    function ENT:UpdateCrosshairPosition()
        -- Put right at the local player's camera aim position.
        self.crosshair.origin = Glide.GetCameraAimPos()
    end

    function ENT:OnActivateMisc()
        -- Let the base class do some initialization
        BaseClass.OnActivateMisc( self )

        -- Store the bones that control the turret's base and weapon
        self.turretBaseBone = self:LookupBone( "mount_rot" )
        self.turretWeaponBone = self:LookupBone( "mount_elev" )
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
            local vehicle = Camera.vehicle
            local rad = math.rad( bodyAng[2] ) -- The angle we're using as reference
            local rad2 = math.rad( bodyAng[1] ) -- The angle we're using as reference ( for pitch )
            localEyePos = vehicle:WorldToLocal( self:GetPos() ) 
            localEyePos[3] = localEyePos[3] + 18 + math.tan( rad2 ) * 20  -- Pseudo ADS
            localEyePos[2] = localEyePos[2] + math.sin( rad ) * -29
            localEyePos[1] = localEyePos[1] + math.cos( rad ) * -29

            return localEyePos
        end
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
    ENT.ChassisMass = 500
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

        local turret = self:CreateEmplacementTurret( self, Vector( 0, 0, 0 ), Angle() )
        turret:SetFireDelay( 0.13 )
        turret:SetBulletOffset( Vector( 45, 0, 11 ) )
        turret:SetShellCasingsOffsetY( 54 )
        turret:SetMinPitch( -40 )
        turret:SetMaxPitch( 30 )
        turret:SetViewpunchMultiplier( 5 )
        turret:SetShootLoopSound( "glide/glide_emplacement_base/glide_dhsk/dshk_loop.wav" )
        turret:SetShootStopSound( "glide/glide_emplacement_base/glide_dhsk/dshk_lastshot.wav" )

        turret.BulletDamage = 40
        Glide.HideEntity( turret, true )
        Glide.HideEntity( turret:GetGunBody(), true )

        -- Store the turret to be used client-side
        self:SetTurret( turret )

    end

    function ENT:OnUpdateFeatures() -- Due to weird jittering effects on moving the seat in client, im doing it here. Sorry!
        local turret = self:GetTurret()
        if IsValid( turret ) then
            -- The player on our "turret seat" should be the user of the actual turret entity.
            turret:UpdateUser( self:GetSeatDriver( 1 ) )
        else return end
        local bodyAng = turret:GetLastBodyAngle() 
        local seat = self:GetTurretSeat()

        local offset = Vector()
        local radius = 40 -- You dont HAVE to make a separate variable for the radius, just putting this here for anyone needing reference.
        
        if IsValid( seat ) then
            local rad = math.rad( bodyAng[2] ) -- The angle we're using as reference
            offset[1] = math.cos( rad ) * -radius --  You may have to fiddle with the radius value and the order of the sin/cos stuff to get it perfectly behind something. Math BS
            offset[2] = math.sin( rad ) * -radius -- ^^^^
            offset[3] = -48 -- Sets the seat on the "ground"
            local LTWVector = LocalToWorld( Vector( offset ), bodyAng, self:GetPos(), self:GetAngles() ) -- Fixes the offset to be from the world to local
            seat:SetPos( LTWVector )
        end
    end
end