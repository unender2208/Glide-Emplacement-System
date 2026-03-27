AddCSLuaFile()

ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "Guided Missile"

ENT.Spawnable = false
ENT.AdminOnly = false
ENT.VJ_ID_Danger = true

ENT.PhysgunDisabled = true
ENT.DoNotDuplicate = true
ENT.DisableDuplicator = true

function ENT:SetupDataTables()
    self:NetworkVar( "Float", "Effectiveness" )
end
