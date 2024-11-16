local UPGRADE = {}
UPGRADE.id = "weapon_tracker"
UPGRADE.class = "weapon_ttt_dete_playercam"
UPGRADE.name = "Weapon Tracker"
UPGRADE.desc = "Also tracks their current weapons!"

function UPGRADE:Apply(SWEP)
    if SERVER then
        util.AddNetworkString("TTTPAPWeaponTracker")

        self:AddHook("PostEntityFireBullets", function(attacker, data)
            if not IsPlayer(attacker) then return end
            local inflictor = attacker:GetActiveWeapon()
            if not IsValid(inflictor) or not self:IsUpgraded(inflictor) then return end
            local victim = data.Trace.Entity

            if IsValid(victim) then
                victim.TTTPAPWeaponTracker = attacker
                net.Start("TTTPAPWeaponTracker")
                net.WriteBool(true)
                net.WriteBool(false)
                net.WritePlayer(victim)
                net.Send(attacker)
            end
        end)

        self:AddHook("WeaponEquip", function(wep, owner)
            -- Stop spam at the end of the round when the victim's weapons are all removed
            if not self:IsAlivePlayer(owner.TTTPAPWeaponTracker) or GetRoundState() ~= ROUND_ACTIVE then return end
            net.Start("TTTPAPWeaponTracker")
            net.WriteBool(false)
            net.WriteBool(false)
            net.WritePlayer(owner)
            net.WriteString(WEPS.GetClass(wep))
            net.Send(owner.TTTPAPWeaponTracker)
        end)

        self:AddHook("PlayerDroppedWeapon", function(owner, wep)
            if not self:IsAlivePlayer(owner.TTTPAPWeaponTracker) or GetRoundState() ~= ROUND_ACTIVE or not self:IsAlive(owner) then return end
            net.Start("TTTPAPWeaponTracker")
            net.WriteBool(false)
            net.WriteBool(true)
            net.WritePlayer(owner)
            net.WriteString(WEPS.GetClass(wep))
            net.Send(owner.TTTPAPWeaponTracker)
        end)

        self:AddHook("PostPlayerDeath", function(ply)
            -- The detective player cam goes away after the victim dies
            ply.TTTPAPWeaponTracker = nil

            -- And when the attacker dies
            for _, p in player.Iterator() do
                if p.TTTPAPWeaponTracker == ply then
                    p.TTTPAPWeaponTracker = nil
                end
            end
        end)
    end

    if CLIENT then
        net.Receive("TTTPAPWeaponTracker", function()
            local isPlayer = net.ReadBool()
            local isDroppedWeapon = net.ReadBool()
            local victim = net.ReadPlayer()

            if isPlayer then
                chat.AddText(victim, "'s current weapons:")
                local message = ""

                for _, wep in ipairs(victim:GetWeapons()) do
                    message = message .. LANG.TryTranslation(wep.PrintName) .. ", "
                end

                message = message:TrimRight(", ")
                chat.AddText(message)
            else
                local class = net.ReadString()
                local printName = weapons.Get(class).PrintName
                local message = isDroppedWeapon and " lost their " or " obtained a "
                chat.AddText(victim, message, LANG.TryTranslation(printName))
            end
        end)
    end
end

function UPGRADE:Reset()
    for _, ply in player.Iterator() do
        ply.TTTPAPWeaponTracker = nil
    end
end

TTTPAP:Register(UPGRADE)