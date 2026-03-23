ENT.Type = "anim"
ENT.Base = "base_glide"

ENT.PrintName = "Glide Emplacement"
ENT.Author = "unender"
ENT.AdminOnly = false
ENT.AutomaticFrameAdvance = true

DEFINE_BASECLASS( "base_glide" )

Glide.SetupInputGroup( "emplacement_controls" )

Glide.AddInputAction( "emplacement_controls", "attack", MOUSE_LEFT )
Glide.AddInputAction( "emplacement_controls", "switch_weapon", KEY_R )
Glide.AddInputAction( "emplacement_controls", "free_look", KEY_LALT )

--- Override this base class function.
function ENT:GetPlayerSitSequence( seatIndex )
    return "idle_all_01" or ( seatIndex > 1 and "idle_all_01" or "idle_all_01" )
end



if CLIENT then
    Glide.SetupInputGroup( "emplacement_controls" )

    --- Override this base class function.
    function ENT:GetCameraType( _seatIndex )
        return 2 -- Glide.CAMERA_TYPE.TURRET
    end
end

if SERVER then
    Glide.SetupInputGroup( "emplacement_controls" )

    --- Override this base class function.
    function ENT:GetInputGroups( seatIndex )
        return seatIndex > 1  and { "general_controls" } or { "general_controls", "emplacement_controls" }
    end
end

