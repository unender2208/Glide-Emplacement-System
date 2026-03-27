local Clamp = math.Clamp

function EFFECT:Init( data )
    local origin = data:GetOrigin()
    local normal = data:GetNormal()
    local scale = Clamp( data:GetScale(), 0.1, 3 )

    local emitter = ParticleEmitter( origin, false )
    if not IsValid( emitter ) then return end

    self:Smoke( emitter, origin, normal, scale )

    emitter:Finish()
end

function EFFECT:Think()
    return false
end

function EFFECT:Render()
end

local FLAME_MATERIAL = "glide/effects/flamelet"

local RandomInt = math.random
local RandomFloat = math.Rand
local RandomAng = AngleRand

local SMOKE_SPRITES = {
    "particle/smokesprites_0001",
    "particle/smokesprites_0002",
    "particle/smokesprites_0003",
    "particle/smokesprites_0004",
    "particle/smokesprites_0005",
    "particle/smokesprites_0006",
    "particle/smokesprites_0007",
    "particle/smokesprites_0008"
}

local UP = Vector( 0, 0, 1 )
local GRAVITY = Vector( 0, 0, 200 )

function EFFECT:Smoke( emitter, origin, normal, scale )
    local p
    local right = normal

    for _ = 0, 10 do
        p = emitter:Add( SMOKE_SPRITES[RandomInt( 1, #SMOKE_SPRITES )], origin )

        if p then
            local size = RandomFloat( 30, 50 ) * 0.7
            local vel = ( right * RandomInt( 100, 2000 ) )

            p:SetGravity( GRAVITY )
            p:SetVelocity( vel * scale )
            p:SetAngleVelocity( RandomAng() * 0.02 )
            p:SetAirResistance( 800 )

            p:SetStartAlpha( 100 )
            p:SetEndAlpha( 0 )
            p:SetStartSize( size )
            p:SetEndSize( size * RandomFloat( 1.5, 2 ) )
            p:SetRoll( RandomFloat( -1, 1 ) )

            p:SetColor( 70, 70, 70 )
            p:SetDieTime( RandomFloat( 0.75, 6 ) * scale )
            p:SetCollide( true )
        end
    end
end
