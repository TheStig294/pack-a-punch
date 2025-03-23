local UPGRADE = {}
UPGRADE.id = "antlion_spammer"
UPGRADE.class = "weapon_antlionsummoner"
UPGRADE.name = "Antlion Spammer"
UPGRADE.desc = "Ammo recharges over time"

UPGRADE.convars = {
    {
        name = "pap_antlion_spammer_recharge_secs",
        type = "int"
    }
}

local rechargeSecsCvar = CreateConVar("pap_antlion_spammer_recharge_secs", 20, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Delay in secs for ammo recharge", 1, 60)

function UPGRADE:Apply(SWEP)
    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack(worldsnd)
        self:PAPOldPrimaryAttack(worldsnd)
        local owner = self:GetOwner()
        local timername = "TTTPAPAntlionSpammer" .. owner:SteamID64()

        timer.Create(timername, rechargeSecsCvar:GetInt(), 0, function()
            if IsValid(self) and self:Clip1() <= 0 then
                self:SetClip1(1)
                self:EmitSound("weapons/crossbow/reload1.wav")
            else
                timer.Remove(timername)
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)