include( "shared.lua" )

DEFINE_BASECLASS( "base_glide" )

--- Implement this base class function.
function ENT:ShouldActivateSounds()
    return true 
end

function ENT:GetCameraType()
    return 1
end