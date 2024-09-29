local UPGRADE = {}
UPGRADE.id = "potion_shield"
UPGRADE.class = "weapon_ttt_mc_immortpotion"
UPGRADE.name = "Shield Potion"

UPGRADE.convars = {
    {
        name = "pap_potion_shield_max",
        type = "int"
    },
    {
        name = "pap_potion_shield_resist",
        type = "int"
    }
}

local maxCvar = CreateConVar("pap_potion_shield_max", 100, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Max no. of shield points", 1, 500)

local dmgResistCvar = CreateConVar("pap_potion_shield_resist", 10, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "% damage resistance", 0, 100)

UPGRADE.desc = "Gives you a health shield!\nResists " .. dmgResistCvar:GetInt() .. "% of damage, protects from 1-shot deaths!"

function UPGRADE:Apply(SWEP)
    local DestroySound = "minecraft_original/glass2.wav"
    local maxShield = maxCvar:GetInt()
    local dmgResist = dmgResistCvar:GetInt()

    function SWEP:ImmortalityEnable()
        if self.PotionEnabled then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        UPGRADE:SetShield(owner, maxShield, dmgResist, true)
        self:TakePrimaryAmmo(1)
        self.PotionEnabled = true
        local tickRate = 0.02
        local chargeRate = math.ceil(1 * (maxShield / 100))
        local shieldPoints = math.min(owner:GetNWInt("PAPHealthShield", 0) + chargeRate, maxShield)
        owner:SetNWInt("PAPHealthShield", shieldPoints)

        timer.Create("use_ammo" .. self:EntIndex(), tickRate, 0, function()
            if self:Clip1() <= self.MaxAmmo then
                self:SetClip1(math.min(self:Clip1() - 1, self.MaxAmmo))
            end

            shieldPoints = math.min(owner:GetNWInt("PAPHealthShield", 0) + chargeRate, maxShield)
            owner:SetNWInt("PAPHealthShield", shieldPoints)

            if self:Clip1() <= 0 then
                self:ImmortalityDisable()
                self:EmitSound(DestroySound)

                if SERVER then
                    self:Remove()
                end
            end
        end)
    end
end

TTTPAP:Register(UPGRADE)