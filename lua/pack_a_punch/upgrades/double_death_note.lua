local UPGRADE = {}
UPGRADE.id = "double_death_note"
UPGRADE.class = "death_note_ttt"
UPGRADE.name = "Double Death Note"
UPGRADE.desc = "Write 2 names separately, their deaths are quicker!"

UPGRADE.convars = {
    {
        name = "pap_double_death_note_time_mult",
        type = "float",
        decimals = 2
    }
}

local timeMultCvar = CreateConVar("pap_double_death_note_time_mult", "0.5", {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Multiplier to the time the death note takes to kill", 0, 1)

function UPGRADE:Apply(SWEP)
    SWEP.UsesLeft = 2

    self:AddHook("TTTDeathNoteNameEntered", function(_, _, deathNote, deathDelaySecs)
        if self:IsUpgraded(deathNote) then return deathDelaySecs * timeMultCvar:GetFloat() end
    end)
end

TTTPAP:Register(UPGRADE)