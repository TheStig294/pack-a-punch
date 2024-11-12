local UPGRADE = {}
UPGRADE.id = "exp_melon_gun"
UPGRADE.class = "weapon_possessed_melon_launcher"
UPGRADE.name = "Exp. Melon Gun"
UPGRADE.desc = "Deals extra damage, melons explode on touch!"

UPGRADE.convars = {
    {
        name = "pap_exp_melon_gun_primary_damage",
        type = "int"
    },
    {
        name = "pap_exp_melon_gun_secondary_damage",
        type = "int"
    }
}

local primaryDmgCvar = CreateConVar("pap_exp_melon_gun_primary_damage", "7", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Extra primary fire damage", 1, 100)

local secondaryDmgCvar = CreateConVar("pap_exp_melon_gun_secondary_damage", "20", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Extra secondary fire damage", 1, 100)

function UPGRADE:Apply(SWEP)
    if CLIENT then return end
    local DMG_EXPLOSIVE_MELON = 7350

    local function ExplodePlayer(ply, inflictor, attacker, damage, effectChance)
        -- Explosion effect
        if math.random(100) <= effectChance then
            local effect = EffectData()
            effect:SetStart(ply:GetPos())
            effect:SetOrigin(ply:GetPos())
            effect:SetScale(damage)
            effect:SetRadius(damage)
            effect:SetMagnitude(damage)
            util.Effect("Explosion", effect)
        end

        -- Explosion damage
        local expDmg = DamageInfo()
        expDmg:SetDamageType(DMG_BLAST)
        expDmg:SetDamage(damage)
        expDmg:SetInflictor(IsValid(inflictor) and inflictor or IsValid(attacker) and attacker or ply)
        expDmg:SetAttacker(IsValid(attacker) and attacker or ply)
        expDmg:SetDamageCustom(DMG_EXPLOSIVE_MELON)
        ply:TakeDamageInfo(expDmg)
    end

    -- Right-click melons
    self:AddHook("OnEntityCreated", function(ent)
        timer.Simple(0, function()
            if IsValid(ent) and ent:GetName() == "PML_Melon" then
                local owner = ent.Owner
                if not IsValid(owner) then return end
                local wep = owner:GetActiveWeapon()
                if not IsValid(wep) or not self:IsUpgraded(wep) then return end
                ent:SetPAPCamo()

                ent:AddCallback("PhysicsCollide", function(phys, data)
                    local hitEnt = data.HitEntity
                    if not IsPlayer(hitEnt) then return end
                    ExplodePlayer(hitEnt, wep, owner, secondaryDmgCvar:GetInt(), 100)
                    ent:Remove()
                end)
            end
        end)
    end)

    -- Left-click melons
    self:AddHook("PostEntityTakeDamage", function(victim, dmg)
        if not self:IsAlivePlayer(victim) then return end
        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) or inflictor:GetName() ~= "PML_Flechette" or dmg:GetDamageCustom() == DMG_EXPLOSIVE_MELON then return end
        local attacker = dmg:GetAttacker()
        if not IsValid(attacker) then return end
        local wep = attacker:GetActiveWeapon()

        if self:IsUpgraded(wep) then
            ExplodePlayer(victim, wep, attacker, primaryDmgCvar:GetInt(), 20)
        end
    end)
end

TTTPAP:Register(UPGRADE)