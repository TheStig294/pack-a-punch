local UPGRADE = {}
UPGRADE.id = "giant_brick"
UPGRADE.class = "weapon_ttt_tacticalbrick"
UPGRADE.name = "Giant Brick"

UPGRADE.convars = {
    {
        name = "pap_giant_brick_throws",
        type = "int"
    }
}

local throwsCvar = CreateConVar("pap_giant_brick_throws", "3", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Number of throws, 0 = infinite", 0, 50)

UPGRADE.desc = "Throw a giant one-shot brick! You get " .. throwsCvar:GetInt() .. " throw(s)"

function UPGRADE:Apply(SWEP)
    self.desc = "Throw a giant one-shot brick! You get " .. throwsCvar:GetInt() .. " throw(s)"
    SWEP:SetModelScale(20, 0.0001)
    SWEP:Activate()
    local owner = SWEP:GetOwner()

    -- If someone tries to upgrade more than one Tactical Brick, reset their "throws" counter
    if IsValid(owner) then
        owner.PAPGiantBrickThrows = 0
    end

    function SWEP:GetGrenadeName()
        return "ttt_pap_tacticalbrick_proj"
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.PAPGiantBrickThrows = nil
    end
end

TTTPAP:Register(UPGRADE)