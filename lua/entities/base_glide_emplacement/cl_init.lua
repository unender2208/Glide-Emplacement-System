include( "shared.lua" )

DEFINE_BASECLASS( "base_glide" )

--- Implement this base class function.
function ENT:ShouldActivateSounds()
    return true 
end

function ENT:GetCameraType()
    return 1
end

function ENT:AimDownSights( upOffset, backwardOffset )
    local pos, ang = self:GetBonePosition(2)
    local gunBody = self:GetTurret():GetGunBody()
    local offset = ( pos + gunBody:GetUp() * upOffset ) + gunBody:GetForward() * backwardOffset -- Offset for ADS ( Uses the bonepos because it kept the iron sights lined up properly )
    local vec = WorldToLocal( offset, ang, self:GetPos(), self:GetAngles() ) 
    return vec
end