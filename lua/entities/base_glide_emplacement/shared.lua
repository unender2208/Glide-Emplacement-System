ENT.Type = "anim"
ENT.Base = "base_glide"

ENT.PrintName = "Glide Emplacement"
ENT.Author = "unender"
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

ENT.EnableADS = false  

DEFINE_BASECLASS( "base_glide" )

--- Override this base class function.
function ENT:GetPlayerSitSequence( seatIndex )
    return "idle_all_01" or ( seatIndex > 1 and "idle_all_01" or "idle_all_01" )
end

if CLIENT then
    --- Override this base class function.
    function ENT:GetCameraType( _seatIndex )
        return 2 -- Glide.CAMERA_TYPE.TURRET
    end
end

if SERVER then
    --- Override this base class function.
    function ENT:GetInputGroups( seatIndex )
        return seatIndex > 1  and { "emplacement_controls" } or { "emplacement_controls", "general_controls" }
    end
end

