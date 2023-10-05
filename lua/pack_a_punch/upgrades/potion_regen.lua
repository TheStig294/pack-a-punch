local UPGRADE = {}
UPGRADE.id = "potion_regen"
UPGRADE.class = "weapon_ttt_mc_healthpotion"
UPGRADE.name = "Regeneration Potion"
UPGRADE.desc = "Continually regenerates your health!"

UPGRADE.convars = {
    {
        name = "pap_potion_regen_delay",
        type = "int"
    },
    {
        name = "pap_potion_regen_amount",
        type = "int"
    }
}

local delayCvar = CreateConVar("pap_potion_regen_delay", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs between heals", 1, 10)

local healAmountCvar = CreateConVar("pap_potion_regen_amount", "5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Heal amount", 1, 100)

function UPGRADE:Apply(SWEP)
    timer.Simple(0.1, function()
        SWEP:SetClip1(-1)
    end)

    local DenySound = "minecraft_original/wood_click.wav"
    local DestroySound = "minecraft_original/glass2.wav"

    function SWEP:DoHeal(ent, primary)
        local owner = self:GetOwner()

        if IsValid(ent) and (ent:IsPlayer() or ent:IsNPC()) and ent:Health() < ent:GetMaxHealth() then
            local timername = "TTTPAPRegenPotion" .. ent:SteamID64()

            timer.Create("TTTPAPRegenPotion" .. ent:SteamID64(), delayCvar:GetInt(), 0, function()
                if not UPGRADE:IsAlivePlayer(ent) or GetRoundState() ~= ROUND_ACTIVE then
                    timer.Remove(timername)

                    return
                end

                ent:SetHealth(math.min(ent:GetMaxHealth(), ent:Health() + healAmountCvar:GetInt()))
            end)

            self:Remove()
            ent:EmitSound(DestroySound)
        else
            owner:EmitSound(DenySound)

            if primary then
                self:SetNextPrimaryFire(CurTime() + 1)
            else
                self:SetNextSecondaryFire(CurTime() + 1)
            end
        end
    end

    if CLIENT then
        SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

        function SWEP:DrawWorldModel()
            SWEP:PAPOldDrawWorldModel()

            if IsValid(self.WorldModelEnt) then
                self.WorldModelEnt:SetMaterial(TTTPAP.camo)
            end
        end
    end
end

TTTPAP:Register(UPGRADE)