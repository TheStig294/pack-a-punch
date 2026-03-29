local UPGRADE = {}
UPGRADE.id = "target_buffer"
UPGRADE.class = "weapon_cln_targetpicker"
UPGRADE.name = "Target Buffer"
UPGRADE.desc = "Lets you periodically buff you and your target!"

UPGRADE.convars = {
    {
        name = "pap_target_buffer_buff_cooldown",
        type = "int"
    }
}

local buffCooldownCvar = CreateConVar("pap_target_buffer_buff_cooldown", 20, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Buff cooldown", 1, 180)

local registeredBuffs = false
local buffs = {}

function UPGRADE:Apply(SWEP)
    local function ChooseBuff(owner, target)
        if SERVER or IsValid(owner.PAPTargetBufferFrame) then return end
        local frame = vgui.Create("DFrame")
        owner.PAPTargetBufferFrame = frame
        frame:SetSize(ScrW() / 5, ScrH() / 5)
        -- Set the buff selection panel to be halfway down, on the far left of the screen
        frame:Center()
        frame:SetX(0)
        frame:SetTitle("Hold TAB to choose a buff for you and " .. target:Nick() .. "!")
        frame:ShowCloseButton(false)
        -- owner.PAPTargetBufferFrame = frame
        local list = vgui.Create("DListView", frame)
        list:Dock(FILL)
        list:SetMultiSelect(false)
        list:AddColumn("Buffs")

        for buffName, buff in SortedPairsByMemberValue(buffs, "index") do
            if not buff.used then
                list:AddLine(buffName)
            end
        end

        function list:OnRowSelected(_, row)
            if not UPGRADE:IsAlivePlayer(target) then
                frame:Close()
                owner:ChatPrint("Your clone target is dead or no longer valid :(")

                return
            end

            local buffName = row:GetColumnText(1)
            net.Start("TTTPAPTargetBufferBuffTarget")
            net.WriteString(buffName)
            net.WritePlayer(target)
            net.SendToServer()
            frame:Close()
        end
    end

    SWEP.PAPOldPrimaryAttack = SWEP.PrimaryAttack

    function SWEP:PrimaryAttack()
        local owner = self:GetOwner()
        self:PAPOldPrimaryAttack()
        if SERVER or not IsValid(owner) or LocalPlayer() ~= owner then return end
        local target = player.GetBySteamID64(owner.TTTCloneTarget)
        if not IsValid(target) then return end
        ChooseBuff(owner, target)
        local timername = "TTTPAPTargetBufferBuffCooldown" .. target:SteamID64()

        timer.Create(timername, buffCooldownCvar:GetInt(), 0, function()
            local stopTimer = true

            if IsValid(owner) then
                -- Hopefully this is cleared at the end of the round...
                target = player.GetBySteamID64(owner.TTTCloneTarget)

                if UPGRADE:IsAlivePlayer(target) then
                    stopTimer = false
                end
            end

            if stopTimer then
                if IsValid(owner) and IsValid(owner.PAPTargetBufferFrame) then
                    owner.PAPTargetBufferFrame:Close()
                end

                timer.Remove(timername)

                return
            end

            ChooseBuff(owner, target)
        end)
    end

    if not registeredBuffs then
        local function IsValidPair(owner, target)
            return IsValid(owner) and UPGRADE:IsAlivePlayer(target)
        end

        if SERVER then
            util.AddNetworkString("TTTPAPTargetBufferBuffTarget")

            net.Receive("TTTPAPTargetBufferBuffTarget", function(_, owner)
                local buffName = net.ReadString()
                local target = net.ReadPlayer()
                if not IsValidPair(owner, target) then return end
                buffs[buffName].func(owner, target)

                timer.Simple(0.1, function()
                    net.Start("TTTPAPTargetBufferBuffTarget")
                    net.WriteString(buffName)
                    net.WritePlayer(owner)
                    net.WritePlayer(target)

                    net.Send({owner, target})
                end)
            end)
        end

        if CLIENT then
            net.Receive("TTTPAPTargetBufferBuffTarget", function()
                local buffName = net.ReadString()
                local owner = net.ReadPlayer()
                local target = net.ReadPlayer()
                if not IsValidPair(owner, target) then return end
                buffs[buffName].func(owner, target)
            end)
        end

        -- All buff functions are called on the server, and the clients of the owner and target players
        local index = 1

        local function RegisterBuff(name, func)
            buffs[name] = {
                index = index,
                func = func
            }

            index = index + 1
        end

        RegisterBuff("Player Outlines", function(owner, target)
            if SERVER then return end
            buffs["Player Outlines"].used = true
            local haloColour = Color(0, 255, 0)

            hook.Add("PreDrawHalos", "TTTPAPTargetBufferWallhacks", function()
                if not IsValidPair(owner, target) then
                    hook.Remove("PreDrawHalos", "TTTPAPTargetBufferWallhacks")

                    return
                end

                local alivePlys = {}

                for _, ply in player.Iterator() do
                    if UPGRADE:IsAlive(ply) then
                        table.insert(alivePlys, ply)
                    end
                end

                halo.Add(alivePlys, haloColour, 1, 1, 2, true, true)
            end)
        end)

        RegisterBuff("Health Regen", function(owner, target)
            local timername = "TTTPAPTargetBufferHealthRegen" .. target:SteamID64()
            target.TTTPAPTargetBufferRegenRate = target.TTTPAPTargetBufferRegenRate or 0
            target.TTTPAPTargetBufferRegenRate = target.TTTPAPTargetBufferRegenRate + 1

            timer.Create(timername, 1, 0, function()
                if not IsValidPair(owner, target) then
                    timer.Remove(timername)

                    if IsValid(target) then
                        target.TTTPAPTargetBufferRegenRate = nil
                    end

                    return
                end

                if owner:Health() < owner:GetMaxHealth() then
                    owner:SetHealth(math.min(owner:Health() + target.TTTPAPTargetBufferRegenRate, owner:GetMaxHealth()))
                end

                if target:Health() < target:GetMaxHealth() then
                    target:SetHealth(math.min(target:Health() + target.TTTPAPTargetBufferRegenRate, target:GetMaxHealth()))
                end
            end)
        end)

        RegisterBuff("Speed Boost", function(owner, target)
            target.TTTPAPTargetBufferSpeedBoost = target.TTTPAPTargetBufferSpeedBoost or 1
            target.TTTPAPTargetBufferSpeedBoost = target.TTTPAPTargetBufferSpeedBoost + 1

            hook.Add("TTTSpeedMultiplier", "TTTPAPTargetBufferSpeedBoost" .. target:SteamID64(), function(ply, mults)
                if not IsValidPair(owner, target) then return end
                if ply ~= owner and ply ~= target then return end
                table.insert(mults, target.TTTPAPTargetBufferSpeedBoost)
            end)
        end)

        RegisterBuff("PAP Upgrade", function(owner, target)
            if CLIENT then return end
            TTTPAP:OrderPAP(owner)
            TTTPAP:OrderPAP(target)
        end)

        local function ForceRoleAndWeapons(owner, target, role, ...)
            local plys = {owner, target}

            local roleWeaponCount = select("#", ...)

            for _, ply in ipairs(plys) do
                ply:SetRole(role)
                ply:StripRoleWeapons()
                local usedSlots = {}

                for _, wep in ipairs(ply:GetWeapons()) do
                    usedSlots[wep.Kind] = wep
                end

                for i = 1, roleWeaponCount do
                    local wep = select(i, ...)
                    local slot = weapons.Get(wep)
                    local oldWep = usedSlots[slot]

                    if oldWep then
                        oldWep:Remove()
                    end

                    ply:Give(wep)
                end
            end

            SendFullStateUpdate()
        end

        RegisterBuff("Get Hired", function(owner, target)
            if CLIENT then return end
            ForceRoleAndWeapons(owner, target, ROLE_CHEF, "weapon_chf_stoveplacer")
        end)

        RegisterBuff("Become Golem", function(owner, target)
            if CLIENT then return end
            ForceRoleAndWeapons(owner, target, ROLE_SAFEKEEPER, "weapon_sfk_safeplacer")
        end)

        RegisterBuff("Turn Evil", function(owner, target)
            if CLIENT then return end
            ForceRoleAndWeapons(owner, target, ROLE_THIEF, "weapon_thf_thievestools")
        end)

        RegisterBuff("Free Dog", function(owner, target)
            if CLIENT then return end
            ForceRoleAndWeapons(owner, target, ROLE_YORKSHIREMAN, "weapon_ysm_dbshotgun", "weapon_ysm_guarddog", "weapon_ysm_pie")
        end)

        RegisterBuff("Explode", function(owner, target)
            if CLIENT then return end
            UPGRADE:Explode(owner, 550, 550)
            UPGRADE:Explode(target, 550, 550)
        end)

        registeredBuffs = true
    end
end

function UPGRADE:Reset()
    if CLIENT then
        hook.Remove("PreDrawHalos", "TTTPAPTargetBufferWallhacks")
    end

    for _, buff in pairs(buffs) do
        buff.used = false
    end

    for _, ply in player.Iterator() do
        timer.Remove("TTTPAPTargetBufferHealthRegen" .. ply:SteamID64())
        ply.TTTPAPTargetBufferRegenRate = nil
        hook.Remove("TTTSpeedMultiplier", "TTTPAPTargetBufferSpeedBoost" .. ply:SteamID64())

        if IsValid(ply.PAPTargetBufferFrame) then
            ply.PAPTargetBufferFrame:Close()
        end
    end
end

TTTPAP:Register(UPGRADE)