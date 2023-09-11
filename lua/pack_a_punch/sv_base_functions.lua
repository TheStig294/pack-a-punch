-- 
-- Server-side pack-a-punch functions 
-- 
-- Debug command for testing upgrades, only works on a peer-to-peer server for the server host if sv_cheats is on
concommand.Add("pap_order", function(ply, _, _, argsStr)
    -- Searching for the input bot player name number
    if argsStr ~= "" then
        for _, p in ipairs(player.GetBots()) do
            if p:Nick() == "Bot" .. argsStr then
                -- Skip upgrade is valid checks as this is a debug command
                TTTPAP:OrderPAP(p, true)

                return
            end
        end
    else
        -- Skip upgrade is valid checks as this is a debug command
        TTTPAP:OrderPAP(ply, true)
    end
end, nil, "Simulates ordering the Pack-a-Punch item, searches for the input bot player name number if argument given, e.g. pap_order 01 orders for Bot01", FCVAR_CHEAT)

-- Preventing a player from using a weapon while they are Pack-a-Punching a weapon
hook.Add("PlayerSwitchWeapon", "TTTPAPPreventUpgradingSwitch", function(ply, _, newWep)
    if ply:GetNWBool("TTTPAPIsUpgrading") and ply:HasWeapon("weapon_ttt_unarmed") and IsValid(newWep) and newWep:GetClass() ~= "weapon_ttt_unarmed" then
        -- This hook is not called for ply:SelectWeapon(), so we're not creating an infinite loop here
        ply:SelectWeapon("weapon_ttt_unarmed")

        return true
    end
end)

-- Finds an upgrade for the player's held weapon and applies it!
function TTTPAP:OrderPAP(ply, skipCanOrderCheck)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local SWEP = ply:GetActiveWeapon()

    -- Check weapon is valid no matter what, else skip checking if the upgrade can be applied if skipCanOrderCheck is true
    if not skipCanOrderCheck then
        if not TTTPAP:CanOrderPAP(ply, true) then return end
    elseif not IsValid(SWEP) then
        ply:PrintMessage(HUD_PRINTCENTER, "Invalid Weapon, try again")
        ply:PrintMessage(HUD_PRINTTALK, "Invalid weapon, try again")

        return
    end

    -- Initial upgrade sound is only heard for the player who bought the Pack-a-Punch
    ply:SendLua("surface.PlaySound(\"ttt_pack_a_punch/upgrade_begin.mp3\")")
    local classname = SWEP:GetClass()
    local oldClip = SWEP:Clip1()
    ply:StripWeapon(classname)
    -- Prevent the player from using a weapon while Pack-a-Punching
    ply:SetNWBool("TTTPAPIsUpgrading", true)
    ply:SelectWeapon("weapon_ttt_unarmed")

    timer.Create("TTTPAPPreventWeaponSwitch", 0.1, 34, function()
        ply:SelectWeapon("weapon_ttt_unarmed")
    end)

    timer.Simple(3.4, function()
        ply:SetNWBool("TTTPAPIsUpgrading", false)
        -- Don't let players smuggle the pap between rounds
        if GetRoundState() == ROUND_PREP then return end

        for _, w in ipairs(ply:GetWeapons()) do
            if w.Kind == weapons.Get(classname).Kind then
                ply:StripWeapon(w.ClassName)
                break
            end
        end

        SWEP = ply:Give(classname)
    end)

    timer.Simple(3.5, function()
        -- Don't let players smuggle the pap between rounds
        if GetRoundState() == ROUND_PREP then return end
        -- The final "ding!" sound is heard for anyone nearby
        ply:EmitSound("ttt_pack_a_punch/upgrade_ding.mp3")
        if not ply:HasWeapon(classname) then return end

        if not IsValid(SWEP) then
            SWEP = ply:GetWeapon(classname)
        end

        -- Choose a random upgrade from available ones to give to the weapon
        -- Else, pick a random generic upgrade if no upgrade is found
        local upgrades = TTTPAP.upgrades[classname]
        local isGenericUpgrade = false

        if not upgrades then
            upgrades = TTTPAP.genericUpgrades
            isGenericUpgrade = true
        end

        local UPGRADE

        -- Check for an upgrade that has its condition met, and has its convar enabled
        -- (There is guaranteed to be at least one by the TTTCanOrderEquipment hook)
        for id, upg in RandomPairs(upgrades) do
            if not upg:Condition() then continue end
            if isGenericUpgrade and not GetConVar("ttt_pap_" .. id):GetBool() then continue end
            if not isGenericUpgrade and not GetConVar("ttt_pap_" .. upg.class .. "_" .. upg.id):GetBool() then continue end
            UPGRADE = upg
            break
        end

        if not UPGRADE.noSelectWep then
            ply:SelectWeapon(classname)
        end

        -- The gun's original remaining ammo in the clip is needed to scale remaining ammo properly if there's an ammo upgrade
        UPGRADE.oldClip = oldClip
        TTTPAP:ApplyUpgrade(SWEP, UPGRADE)
    end)
end

-- Applies the PAP shoot sound
util.AddNetworkString("TTTPAPApplySound")

hook.Add("WeaponEquip", "TTTPAPSoundChange", function(SWEP, ply)
    timer.Simple(0.1, function()
        if not SWEP.PAPUpgrade or SWEP.PAPUpgrade.noSound then return end

        if SWEP.Primary then
            SWEP.Primary.Sound = TTTPAP.shootSound
        end

        net.Start("TTTPAPApplySound")
        net.WriteEntity(SWEP)
        net.Send(ply)
    end)
end)

-- Applies all pack-a-punch effects
util.AddNetworkString("TTTPAPApply")

function TTTPAP:ApplyUpgrade(SWEP, UPGRADE)
    if not IsValid(SWEP) then return end

    -- Give the player a completely new base weapon instead if one is specified
    if UPGRADE.newClass and not UPGRADE.skipNewClass then
        local owner = SWEP:GetOwner()

        if IsValid(owner) then
            owner:StripWeapon(UPGRADE.class)
            SWEP = owner:Give(UPGRADE.newClass)

            timer.Simple(0.1, function()
                if not owner:HasWeapon(UPGRADE.newClass) then return end

                if not IsValid(SWEP) then
                    SWEP = owner:GetWeapon(UPGRADE.newClass)
                end

                -- If we don't want the player to hold the weapon straight away, block it
                if not UPGRADE.noSelectWep then
                    owner:SelectWeapon(UPGRADE.newClass)
                end
            end)
        end

        -- Apply the upgrade!
        UPGRADE.skipNewClass = true
        TTTPAP:ApplyUpgrade(SWEP, UPGRADE)

        return
    end

    -- Upgrade function (Where all the magic happens...)
    UPGRADE:Apply(SWEP)
    table.insert(TTTPAP.activeUpgrades, UPGRADE)

    -- Camo
    if not UPGRADE.noCamo then
        SWEP:SetMaterial(TTTPAP.camo)
    end

    -- Sound
    if SWEP.Primary and not UPGRADE.noSound then
        SWEP.Primary.Sound = TTTPAP.shootSound
    end

    -- Firerate
    if isnumber(SWEP.Primary.Delay) then
        SWEP.Primary.Delay = SWEP.Primary.Delay / UPGRADE.firerateMult
    elseif isnumber(SWEP.Primary.RPM) then
        SWEP.Primary.RPM = SWEP.Primary.RPM * UPGRADE.firerateMult
    end

    -- Damage
    if isnumber(SWEP.Primary.Damage) then
        SWEP.Primary.Damage = SWEP.Primary.Damage * UPGRADE.damageMult
    end

    -- Spread
    if isnumber(SWEP.Primary.Cone) then
        SWEP.Primary.Cone = SWEP.Primary.Cone * UPGRADE.spreadMult
    elseif isnumber(SWEP.Primary.Spread) then
        SWEP.Primary.Spread = SWEP.Primary.Spread * UPGRADE.spreadMult
    end

    -- Ammo
    if isnumber(SWEP.Primary.ClipSize) and isnumber(SWEP.Primary.ClipMax) and isnumber(SWEP.Primary.DefaultClip) then
        local oldClipSize = SWEP.Primary.ClipSize
        local oldClip = UPGRADE.oldClip or SWEP:Clip1()
        SWEP.Primary.ClipSize = SWEP.Primary.ClipSize * UPGRADE.ammoMult
        SWEP.Primary.ClipMax = SWEP.Primary.ClipMax * UPGRADE.ammoMult
        SWEP.Primary.DefaultClip = SWEP.Primary.DefaultClip * UPGRADE.ammoMult
        -- Set ammo relative to leftover ammo
        SWEP:SetClip1(oldClip / oldClipSize * SWEP.Primary.ClipSize)
    end

    -- Recoil
    if isnumber(SWEP.Primary.Recoil) then
        SWEP.Primary.Recoil = SWEP.Primary.Recoil * UPGRADE.recoilMult
    elseif isnumber(SWEP.Primary.StaticRecoilFactor) then
        SWEP.Primary.StaticRecoilFactor = SWEP.Primary.StaticRecoilFactor * UPGRADE.recoilMult
    end

    -- Automatic
    if isbool(SWEP.Primary.Automatic) and isbool(UPGRADE.automatic) then
        SWEP.Primary.Automatic = UPGRADE.automatic
    end

    -- Add upgrade table to the weapon entity itself for easy reference
    -- Used for Pack-a-Punch camo, sound and some upgrades themselves for detecting if a weapon is Pack-a-Punched
    SWEP.PAPUpgrade = UPGRADE
    -- Client-side changes
    net.Start("TTTPAPApply")
    net.WriteEntity(SWEP)
    net.WriteFloat(SWEP.Primary.Delay or -1)
    net.WriteFloat(SWEP.Primary.RPM or -1)
    net.WriteFloat(SWEP.Primary.Damage or -1)
    net.WriteFloat(SWEP.Primary.Cone or -1)
    net.WriteFloat(SWEP.Primary.Spread or -1)
    net.WriteFloat(SWEP.Primary.ClipSize or -1)
    net.WriteFloat(SWEP.Primary.Recoil or -1)
    net.WriteFloat(SWEP.Primary.StaticRecoilFactor or -1)
    net.WriteBool(SWEP.Primary.Automatic or false)
    net.WriteString(UPGRADE.id)
    -- Generic upgrades do not have a weapon class defined
    net.WriteString(UPGRADE.class or "")
    net.WriteBool(UPGRADE.noDesc or false)
    net.Broadcast()
end