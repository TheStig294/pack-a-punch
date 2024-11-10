local UPGRADE = {}
UPGRADE.id = "damage_delayer"
UPGRADE.class = "weapon_ttt_painkillers"
UPGRADE.name = "Damage Delayer"
UPGRADE.desc = "Permanent full heal, delays damage taken by 5 seconds"

function UPGRADE:Apply(SWEP)
    function SWEP:PrimaryAttack()
        self:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
        local owner = self:GetOwner()

        -- Cannot be used at max health or higher, and prevent use while animation is playing
        if owner:Health() >= owner:GetMaxHealth() or self.UsedPainKillers then
            self:EmitSound("TTT_Painkillers.Deny")

            return
        end

        self.UsedPainKillers = true
        self:EmitSound("TTT_Painkillers.Eat")
        owner:ViewPunch(Angle(-10, 0, 0))
        owner:SetAnimation(PLAYER_ATTACK1)
        self:SetHoldType("camera")
        owner:SetAnimation(PLAYER_ATTACK1)
        if CLIENT then return end

        timer.Simple(0.5, function()
            -- In case the player's current health is higher than their max health, don't do anything
            owner:SetHealth(math.max(owner:Health(), owner:GetMaxHealth()))
            owner.TTTPAPDamageDelayer = true
            DamageLog("PAINKILLERS:\t " .. owner:Nick() .. " [" .. owner:GetRoleString() .. "]" .. " downed a bottle of *upgraded* painkillers.")

            if IsValid(self) then
                self:Remove()
                owner:ConCommand("lastinv")
            end
        end)
    end

    -- Damage delay
    -- Choosing an arbitrary damage type to set as a flag for delayed damage so it does not go in an infinite loop...
    local DMG_DELAYED = 2051

    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not IsValid(ply) or not ply.TTTPAPDamageDelayer or dmg:GetDamageCustom() == DMG_DELAYED then return end

        -- Credit goes to Mal for creating the "Delayed Reaction" randomat where this code was modified from
        local dmgInfo = {
            dmg = dmg:GetDamage(),
            typ = dmg:GetDamageType(),
            atk = dmg:GetAttacker(),
            inf = dmg:GetInflictor(),
            foc = dmg:GetDamageForce(),
            pos = dmg:GetDamagePosition(),
            rpo = dmg:GetReportedPosition()
        }

        timer.Simple(5, function()
            -- Checking for ply.TTTPAPDamageDelayer here prevents damage from being taken on the next round, as it gets reset by then
            if self:IsAlivePlayer(ply) and ply.TTTPAPDamageDelayer then
                local delayedDmg = DamageInfo()
                -- Prevent taking the same damage in an infinite loop...
                delayedDmg:SetDamageCustom(DMG_DELAYED)
                delayedDmg:SetDamage(dmgInfo.dmg)
                delayedDmg:SetDamageType(dmgInfo.typ)
                delayedDmg:SetAttacker(IsValid(dmgInfo.atk) and dmgInfo.atk or game.GetWorld())
                delayedDmg:SetInflictor(IsValid(dmgInfo.inf) and dmgInfo.inf or game.GetWorld())
                delayedDmg:SetDamageForce(dmgInfo.foc)
                delayedDmg:SetDamagePosition(dmgInfo.pos)
                delayedDmg:SetReportedPosition(dmgInfo.rpo)
                ply:TakeDamageInfo(delayedDmg)
            end
        end)

        return true
    end)

    -- Prevent having delayed damage after dying
    self:AddHook("PostPlayerDeath", function(ply)
        ply.TTTPAPDamageDelayer = nil
    end)
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPDamageDelayer = nil
    end
end

TTTPAP:Register(UPGRADE)