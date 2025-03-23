local UPGRADE = {}
UPGRADE.id = "damage_swap_gun"
UPGRADE.class = "weapon_teleport_gun_t"
UPGRADE.name = "Damage Swap Gun"
UPGRADE.desc = "You only swap after taking damage"

UPGRADE.convars = {
    {
        name = "pap_damage_swap_gun_cooldown",
        type = "int"
    }
}

local cooldownCvar = CreateConVar("pap_damage_swap_gun_cooldown", 2, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds cooldown for another swap", 0, 30)

function UPGRADE:Apply(SWEP)
    local function HitEffects(att, path, dmginfo)
        if SERVER then
            local ply, target = att, path.Entity
            ply.TTTPAPDamageSwapGunPly = target
        end
    end

    self:AddHook("PostEntityTakeDamage", function(ply, dmg, took)
        if not took or not IsValid(ply) then return end
        local target = ply.TTTPAPDamageSwapGunPly

        if self:IsAlivePlayer(target) and not ply.TTTPAPDamageSwapGunCooldown then
            local pos = target:GetPos()
            target:SetPos(ply:GetPos())
            ply:SetPos(pos)
            sound.Play("ambient/levels/labs/electric_explosion2.wav", ply:GetPos(), 65, 75)
            ply.TTTPAPDamageSwapGunCooldown = true

            timer.Simple(cooldownCvar:GetInt(), function()
                if IsValid(ply) then
                    ply.TTTPAPDamageSwapGunCooldown = false
                end
            end)
        end
    end)

    function SWEP:ShootBullet(dmg, recoil, numbul, cone)
        self:SendWeaponAnim(self.PrimaryAnim)
        self:GetOwner():MuzzleFlash()
        self:GetOwner():SetAnimation(PLAYER_ATTACK1)
        numbul = numbul or 1
        cone = cone or 0.01
        local bullet = {}
        bullet.Num = numbul
        bullet.Src = self:GetOwner():GetShootPos()
        bullet.Dir = self:GetOwner():GetAimVector()
        bullet.Spread = Vector(cone, cone, 0)
        bullet.Tracer = 4
        bullet.TracerName = self.Tracer or "Tracer"
        bullet.Force = 10
        bullet.Damage = dmg
        bullet.Callback = HitEffects
        self:GetOwner():FireBullets(bullet)
        -- Owner can die after firebullets
        if (not IsValid(self:GetOwner())) or (not self:GetOwner():Alive()) or self:GetOwner():IsNPC() then return end
        self:TakePrimaryAmmo(1)
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.TTTPAPDamageSwapGunPly = nil
        ply.TTTPAPDamageSwapGunCooldown = nil
    end
end

TTTPAP:Register(UPGRADE)