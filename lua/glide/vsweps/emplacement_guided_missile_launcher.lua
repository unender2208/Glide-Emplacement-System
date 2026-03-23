VSWEP.Base = "emplacement_vswep_base"
VSWEP.Name = "Guided Missile"
VSWEP.Icon = "glide/icons/rocket.png"

if SERVER then
    VSWEP.FireDelay = 1
    VSWEP.EnableLockOn = false

    -- If not empty, use this as the missile model
    VSWEP.MissileModel = "" 
    VSWEP.MissileBodygroup = nil -- Has to be a table because of the whole "x, y" thing in :SetBodyGroup()
    VSWEP.MissileBodygroupDelay = 0 -- Makes the bodygroup only deploy after this set delay 

    -- Missile model scale
    VSWEP.MissileModelScale = 1.0

end

if CLIENT then
    function VSWEP:DrawCrosshair()
    end
end

if SERVER then
    function VSWEP:PrimaryAttack()
        self:TakePrimaryAmmo( 1 )
        self:SetNextPrimaryFire( CurTime() + self.FireDelay )
        self:IncrementProjectileIndex()
        self:ShootEffects()

        local vehicle = self.Vehicle
        local turret = vehicle:GetTurret()
        local ang = turret:GetGunBody():GetAngles()
        local target
        
        if not turret:IsValid() then return end

        local pos = vehicle:LocalToWorld( self.ProjectileOffsets[self.projectileOffsetIndex] )
        local missile = ents.Create( "glide_guided_missile" )
        missile:SetPos( pos )
        missile:SetAngles( ang )
        missile:Spawn()
        missile:SetupMissile( attacker, parent )
        missile:SetModelScale( self.MissileModelScale )

        missile.damage = missile.damage * self.ProjectileDamageMult

        if self.MissileModel ~= "" then
            missile:SetModel( self.MissileModel )
            if self.MissileBodyGroup ~= nil then
                timer.Simple( self.MissileBodygroupDelay, function ()
                    if missile:IsValid() then
                        missile:SetBodygroup( self.MissileBodyGroup[1], self.MissileBodyGroup[2]  )                                    
                    end
                end)
            end
        end

        if self.FiringAnimation ~= "" then 
            local anim = self.Vehicle:LookupSequence( self.FiringAnimation )
            self.Vehicle:ResetSequence( anim ) -- Plays the firing animation you set
        end
    end
end