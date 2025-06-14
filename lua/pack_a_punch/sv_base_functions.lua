-- 
-- Server-side pack-a-punch functions 
-- 
local shootSoundCvar

hook.Add("Initialize", "TTTPAPGetShootSoundConvar", function()
    shootSoundCvar = GetConVar("ttt_pap_apply_generic_shoot_sound")
end)

-- Debug command for testing upgrades, only works on a peer-to-peer server for the server host if sv_cheats is on
concommand.Add("pap_order", function(ply, _, _, argsStr)
    -- Searching for the input bot player name number
    if argsStr ~= "" then
        for _, p in ipairs(player.GetAll()) do
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

hook.Add("InitPostEntity", "TTTPAPFixPlayerUnstuckModConflict", function()
    -- The auto-player unstuck mod tries to make players who are stuck not shoot each other, but this conflicts with the pack-a-punch,
    -- It causes a weapon's upgrade to undo itself if it uses the SWEP:PrimaryAttack() hook, using its old functionality on swapping weapons...
    -- The original purpose of this hook was to make it so players who were stuck shot through each other, but removing this isn't the end of the world
    -- (That feature vs. the Pack-a-Punch? Come on the PaP wins)
    -- If they're both installed, remove this functionality to make the PaP work again
    if ConVarExists("sv_player_stuck") then
        hook.Add("Think", "StigTTTFixes", function()
            hook.Remove("PlayerSwitchWeapon", "PlayerSwitchWeaponStuck")
        end)
    end

    -- Set on load/save on exit all PaP convars
    -- This is used instead of FCVAR_ARCHIVE because it causes a major issue in players not being able to join the server if too many archived convars are used!
    -- This is done in an InitPostEntity hook because we need to wait for the ttt_pap_detective and ttt_pap_traitor convars to be created in their entity lua files!
    -- (Hopefully in TTT2 the PaP item is loaded before this hook too but who knows...)
    -- Also, the server config hasn't loaded yet, so all config values will overwrite these values, and be saved, which perfectly emulates FCVAR_ARCHIVE!
    if not file.IsDir("pack_a_punch", "DATA") then
        file.CreateDir("pack_a_punch")
    elseif file.Exists("pack_a_punch/convars.json", "DATA") then
        local cvarValues = util.JSONToTable(file.Read("pack_a_punch/convars.json", "DATA"))

        for cvarName, cvarValue in pairs(cvarValues) do
            local cvar = GetConVar(cvarName)
            if not cvar then continue end
            cvar:SetString(cvarValue)
        end
    end
end)

hook.Add("ShutDown", "TTTPAPSaveConvars", function()
    local cvarValues = {}

    for cvarName, _ in pairs(TTTPAP.convars) do
        local convar = GetConVar(cvarName)
        if not convar then continue end
        local value = convar:GetString()
        -- Don't bother saving the default value because that will just use up more space
        -- and make it difficult for us to change defaults in the future
        -- (Thanks to Mal for this optimisation!)
        if value == convar:GetDefault() then continue end
        cvarValues[cvarName] = value
    end

    file.Write("pack_a_punch/convars.json", util.TableToJSON(cvarValues))
end)

-- Choose a random upgrade from available ones to give to the weapon
-- Else, pick a random generic upgrade if no upgrade is found
function TTTPAP:SelectUpgrade(SWEP)
    local upgrades = TTTPAP.upgrades[SWEP:GetClass()]
    local isGenericUpgrade = false

    if not upgrades then
        upgrades = TTTPAP.genericUpgrades
        isGenericUpgrade = true
    end

    local UPGRADE

    -- Check for an upgrade that has its condition met, and has its convar enabled
    -- (There is guaranteed to be at least one by the TTTCanOrderEquipment hook)
    for id, upg in RandomPairs(upgrades) do
        if not upg:Condition(SWEP) then continue end
        if isGenericUpgrade and not GetConVar("ttt_pap_" .. id):GetBool() then continue end
        if not isGenericUpgrade and not GetConVar("ttt_pap_" .. upg.id):GetBool() then continue end
        UPGRADE = upg
        break
    end

    return UPGRADE
end

-- Finds an upgrade for the player's held weapon and applies it!
function TTTPAP:OrderPAP(ply, skipCanOrderCheck)
    if not IsValid(ply) or not ply:IsPlayer() then return end
    local SWEP = ply:GetActiveWeapon()

    -- Check weapon is valid no matter what, else skip checking if the upgrade can be applied if skipCanOrderCheck is true
    if not skipCanOrderCheck then
        if not TTTPAP:CanOrderPAP(ply, true) then return end
    elseif not IsValid(SWEP) then
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
        -- Don't let players smuggle the pap between rounds
        if GetRoundState() == ROUND_PREP then
            ply:SetNWBool("TTTPAPIsUpgrading", false)

            return
        end

        for _, w in ipairs(ply:GetWeapons()) do
            if w.Kind == weapons.Get(classname).Kind then
                ply:StripWeapon(w.ClassName)
                break
            end
        end

        SWEP = ply:Give(classname)
        ply:SetNWBool("TTTPAPIsUpgrading", false)
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

        local UPGRADE = TTTPAP:SelectUpgrade(SWEP)

        if not UPGRADE.noSelectWep then
            ply:SelectWeapon(classname)
        end

        -- The gun's original remaining ammo in the clip is needed to scale remaining ammo properly if there's an ammo upgrade
        UPGRADE.oldClip = oldClip
        -- This prevents a weapon's upgrade from being displayed twice, the PlayerSwitchWeapon hook below isn't run for ply:SelectWeapon()
        SWEP.TTTPAPLastPlayerSwitchedTo = ply
        hook.Run("TTTPAPOrder", ply, SWEP, UPGRADE)
        TTTPAP:ApplyUpgrade(SWEP, UPGRADE)
    end)
end

-- Applies the PAP shoot sound
util.AddNetworkString("TTTPAPApplySound")

hook.Add("WeaponEquip", "TTTPAPSoundChange", function(SWEP, ply)
    timer.Simple(0.1, function()
        if not SWEP.PAPUpgrade or SWEP.PAPUpgrade.noSound then return end

        if SWEP.Primary and shootSoundCvar:GetBool() then
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
    -- Always delay running this function by a split second because giving a weapon and upgrading it on the same frame doesn't work,
    -- the entity doesn't exist yet on the client
    timer.Simple(0.1, function()
        if not IsValid(SWEP) then return end

        -- Give the player a completely new base weapon instead if one is specified
        if UPGRADE.newClass and WEPS.GetClass(SWEP) ~= UPGRADE.newClass then
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
            TTTPAP:ApplyUpgrade(SWEP, UPGRADE)

            return
        end

        -- Upgrade function (Where all the magic happens...)
        UPGRADE:Apply(SWEP)
        table.insert(TTTPAP.activeUpgrades, UPGRADE)

        -- Camo
        if not UPGRADE.noCamo then
            SWEP:SetPAPCamo()
        end

        -- Sound
        if SWEP.Primary and not UPGRADE.noSound and shootSoundCvar:GetBool() then
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
        if isnumber(SWEP.Primary.ClipSize) then
            local oldClipSize = SWEP.Primary.ClipSize
            local oldClip = UPGRADE.oldClip or SWEP:Clip1()
            SWEP.Primary.ClipSize = SWEP.Primary.ClipSize * UPGRADE.ammoMult
            SWEP.Primary.ClipMax = SWEP.Primary.ClipSize
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
    end)
end

-- Applies a random upgrade to a loose weapon, not necessarily carried by a player
function TTTPAP:ApplyRandomUpgrade(SWEP)
    if not IsValid(SWEP) or SWEP.PAPUpgrade then return end
    local UPGRADE = TTTPAP:SelectUpgrade(SWEP)
    if UPGRADE == nil then return end
    UPGRADE.noDesc = true

    local function Try()
        TTTPAP:ApplyUpgrade(SWEP, UPGRADE)
    end

    local function Catch(err)
        ErrorNoHalt("WARNING: Pack-a-Punch upgrade '" .. UPGRADE.id .. "' caused an error being applied to '" .. tostring(SWEP) .. "'. Please report to the addon developer with the following error:\n", err, "\n")
    end

    xpcall(Try, Catch)
end

-- Displays the upgrade description for upgraded weapons you find on the ground
hook.Add("PlayerSwitchWeapon", "TTTPAPDroppedWeaponUpgradeDescription", function(ply, _, SWEP)
    if IsValid(SWEP) and SWEP.PAPUpgrade and SWEP.PAPUpgrade.desc then
        if not IsValid(SWEP.TTTPAPLastPlayerSwitchedTo) or SWEP.TTTPAPLastPlayerSwitchedTo ~= ply then
            ply:ChatPrint("PAP UPGRADE: " .. SWEP.PAPUpgrade.desc)
        end

        SWEP.TTTPAPLastPlayerSwitchedTo = ply
    end
end)