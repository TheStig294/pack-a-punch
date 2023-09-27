local UPGRADE = {}
UPGRADE.id = "mini_mush"
UPGRADE.class = "giantsupermariomushroom"
UPGRADE.name = "Mini Mush"
UPGRADE.desc = "Makes you tiny instead!"

UPGRADE.convars = {
    {
        name = "pap_mini_mush_scale",
        type = "float",
        decimal = 1
    },
    {
        name = "pap_mini_mush_health",
        type = "int"
    },
    {
        name = "pap_mini_mush_armor",
        type = "int"
    },
    {
        name = "pap_mini_mush_duration",
        type = "int"
    }
}

local scaleCvar = CreateConVar("pap_mini_mush_scale", 0.3, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Player scale", 0.1, 0.9)

local healthCvar = CreateConVar("pap_mini_mush_health", 30, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Player health", 1, 100)

local armorCvar = CreateConVar("pap_mini_mush_armor", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Player armor", 0, 100)

local durationCvar = CreateConVar("pap_mini_mush_duration", 30, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds duration", 1, 180)

function UPGRADE:Apply(SWEP)
    if SERVER then
        SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

        function SWEP:PrimaryAttack()
            local oldScale = GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_scale
            local oldHealth = GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_health
            local oldArmor = GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_armor
            local oldDuration = GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_duration
            GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_scale = scaleCvar:GetFloat()
            GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_health = healthCvar:GetInt()
            GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_armor = armorCvar:GetInt()
            GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_duration = durationCvar:GetInt()
            self:PAPOldPrimaryAttack()
            GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_scale = oldScale
            GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_health = oldHealth
            GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_armor = oldArmor
            GIANTSUPERMARIOMUSHROOM.CVARS.giantsupermariomushroom_duration = oldDuration
        end
    end
end

TTTPAP:Register(UPGRADE)