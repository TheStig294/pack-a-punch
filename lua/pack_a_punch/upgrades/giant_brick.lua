local UPGRADE = {}
UPGRADE.id = "giant_brick"
UPGRADE.class = "weapon_ttt_tacticalbrick"
UPGRADE.name = "Giant Brick"

UPGRADE.convars = {
    {
        name = "pap_giant_brick_throws",
        type = "int"
    },
    {
        name = "pap_giant_brick_damage",
        type = "int"
    },
    {
        name = "pap_giant_brick_scale",
        type = "int"
    },
}

local throwsCvar = CreateConVar("pap_giant_brick_throws", "3", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Number of throws, 0 = infinite", 0, 50)

local scaleCvar = CreateConVar("pap_giant_brick_scale", "20", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Size scale of the brick", 2, 40)

local function GetDescription()
    local desc = "Throw a giant brick!"
    local throws = throwsCvar:GetInt()

    if throws == 1 then
        desc = desc .. " You get 1 throw"
    elseif throws > 1 then
        desc = desc .. " You get " .. throws .. " throws"
    end

    return desc
end

UPGRADE.desc = GetDescription()

function UPGRADE:Apply(SWEP)
    self.desc = GetDescription()
    SWEP:SetModelScale(scaleCvar:GetInt(), 0.0001)
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