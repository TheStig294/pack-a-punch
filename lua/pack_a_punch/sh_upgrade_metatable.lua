-- 
-- Creating a fake "UPGRADE" class using metatables, borrowed from the randomat's "EVENT" class
-- 
local UPGRADE = {}
UPGRADE.__index = UPGRADE
-- Basic properties
UPGRADE.id = nil -- Unique ID name of the upgrade, required. Try to not use the weapon's classname, as other upgrades might use this
UPGRADE.class = nil -- Classname of the weapon the upgrade is for, nil designates the upgrade as a "Generic upgrade" that can be applied to any basic weapon
UPGRADE.name = nil -- Displayed SWEP.PrintName of the upgrade weapon
UPGRADE.desc = nil -- Displayed in chat, upgrade description on receiving the upgraded weapon
UPGRADE.convars = nil -- Table of convar info tables, format:
-- convars = {
--    {
--        name = ConVar name,
--        type = ConVar variable type (bool, int, float or string),
--        decimals = No. of decimals the convar value slider should have in the F1 tab
--    },
--    {
--        ...
--    },
--    ...
--}
-- Weapon stats
UPGRADE.firerateMult = 1 -- Firerate
UPGRADE.damageMult = 1 -- Damage
UPGRADE.spreadMult = 1 -- Inverse of accuracy
UPGRADE.ammoMult = 1 -- Ammo
UPGRADE.recoilMult = 1 -- Weapon recoil
UPGRADE.automatic = nil -- Automatic fire, a true/false value overrides the weapon's default
-- Upgrade options
UPGRADE.noSelectWep = nil -- Prevents the upgraded weapon from being automatically selected after it is given
UPGRADE.newClass = nil -- Defines a different weapon SWEP to be given instead of the same one when a weapon is upgraded
UPGRADE.noCamo = nil -- Prevents the upgrade camo from being applied to the weapon
UPGRADE.noSound = nil -- Prevents the PAP shoot sound from being applied
UPGRADE.noDesc = nil -- Prevents the chat description from being displayed on upgrading

-- If false, prevents the upgrade from being applied. Mainly used for checking if the upgrade's required mods are installed on the server
function UPGRADE:Condition(SWEP)
    return true
end

-- Runs when a player purchases the PaP and the weapon begins upgrading. NOT run for instant upgrades. Useful for disabling a weapon's passive effects while it's upgrading
function UPGRADE:OnPurchase(SWEP)
end

-- The function responsible for upgrading the weapon, run when the weapon should be upgraded
function UPGRADE:Apply(SWEP)
end

-- Run the next time TTTPrepareRound is called to reset any data or anything that needs cleaning up that the weapon upgrade affected
function UPGRADE:Reset()
end

-- These functions are from Malivil's randomat mod, where hooks passed are automatically given an appropriate hook id and are removed the next time TTTPrepareRound is called
-- Upgrade functions use self:AddHook(), self:RemoveHook() and self:AddCleanupHooks() are used in sh_base_functions.lua to clean up the hooks at the end of the round
function UPGRADE:AddHook(hooktype, callbackfunc, suffix)
    callbackfunc = callbackfunc or self[hooktype]
    local id = "TTTPAP." .. self.id .. ":" .. hooktype

    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. ":" .. suffix
    end

    hook.Add(hooktype, id, function(...) return callbackfunc(...) end)
    self.Hooks = self.Hooks or {}

    table.insert(self.Hooks, {hooktype, id})
end

function UPGRADE:RemoveHook(hooktype, suffix)
    local id = "TTTPAP." .. self.id .. ":" .. hooktype

    if suffix and type(suffix) == "string" and #suffix > 0 then
        id = id .. ":" .. suffix
    end

    for idx, ahook in ipairs(self.Hooks or {}) do
        if ahook[1] == hooktype and ahook[2] == id then
            hook.Remove(ahook[1], ahook[2])
            table.remove(self.Hooks, idx)

            return
        end
    end
end

function UPGRADE:CleanUpHooks()
    if not self.Hooks then return end

    for _, ahook in ipairs(self.Hooks) do
        hook.Remove(ahook[1], ahook[2])
    end

    table.Empty(self.Hooks)
end

-- Adds extra functionality to the end of a weapon's hook, calls the original weapon's hook logic first
function UPGRADE:AddToHook(SWEP, hookName, HookFunction)
    if not IsValid(SWEP) then return end

    -- Save the original hook if not already saved
    if not SWEP["PAPOld" .. hookName] then
        SWEP["PAPOld" .. hookName] = SWEP[hookName]
    end

    -- Now override it
    SWEP[hookName] = function(self, ...)
        -- First call the original hook,
        -- Then call our logic, passing "self" to our logic is redundant
        SWEP["PAPOld" .. hookName](self, ...)

        return HookFunction(...)
    end
end

-- Utility functions available inside any UPGRADE function, usually used in UPGRADE:Apply()
local ForceSetPlayermodel = FindMetaTable("Entity").SetModel

function UPGRADE:SetModel(ply, model)
    ForceSetPlayermodel(ply, model)

    if SERVER then
        ply:SetupHands()
    end
end

function UPGRADE:IsPlayer(ply)
    return IsValid(ply) and ply:IsPlayer()
end

function UPGRADE:IsAlive(ply)
    return ply:Alive() and not ply:IsSpec()
end

function UPGRADE:IsAlivePlayer(ply)
    return self:IsPlayer(ply) and self:IsAlive(ply)
end

function UPGRADE:IsUpgraded(SWEP)
    return SWEP.PAPUpgrade and SWEP.PAPUpgrade.id == self.id
end

function UPGRADE:IsValidUpgrade(SWEP)
    return IsValid(SWEP) and self:IsUpgraded(SWEP)
end

function UPGRADE:PlayerNotStuck(ply)
    -- Check player is no-clipping
    if ply:IsEFlagSet(EFL_NOCLIP_ACTIVE) then return true end
    -- Check player is alive
    if not ply:Alive() or (ply.IsSpec and ply:IsSpec()) then return true end
    -- Check player is not in a vehicle prop like an airboat
    local parent = ply:GetParent()

    if IsValid(parent) then
        local class = parent:GetClass()

        if string.StartWith(class, "prop_vehicle") then
            ply.NotStuckWasInVehicle = true

            return true
        end
    else
        -- Parent returns NULL while exiting a vehicle, delay running the usual stuck-check code to give time to exit
        timer.Simple(1.5, function()
            if IsValid(ply) then
                ply.NotStuckWasInVehicle = nil
            end
        end)

        if ply.NotStuckWasInVehicle then return true end
    end

    local pos = ply:GetPos()

    local t = {
        start = pos,
        endpos = pos,
        mask = MASK_PLAYERSOLID,
        filter = ply
    }

    local isSolidEnt = util.TraceEntity(t, ply).StartSolid
    local ent = util.TraceEntity(t, ply).Entity

    if IsValid(ent) then
        -- A backup check if an entity can be passed through or not
        local nonPlayerCollisionGroups = {1, 2, 10, 11, 12, 15, 16, 17, 20}

        local entGroup = ent:GetCollisionGroup()

        for i, group in ipairs(nonPlayerCollisionGroups) do
            if entGroup == group then return true end
        end

        -- Workaround to stop TTT entities being used to boost through walls
        if ent.CanUseKey then return true end
    end
    -- Else, use what the trace returned

    return not isSolidEnt
end

function UPGRADE:FindPassableSpace(ply, direction, scale, pos)
    local i = 0

    while i < 100 do
        pos = pos + (scale * direction)
        ply:SetPos(pos)
        if self:PlayerNotStuck(ply) then return true, ply:GetPos() end
        i = i + 1
    end

    return false, nil
end

function UPGRADE:UnstuckPlayer(ply)
    if not self:PlayerNotStuck(ply) then
        local oldPos = ply:GetPos()
        local angle = ply:GetAngles()
        local forward = angle:Forward()
        local right = angle:Right()
        local up = angle:Up()
        local SearchScale = 1 -- Increase and it will unstuck you from even harder places but with lost accuracy. Please, don't try higher values than 12
        local origPos = ply:GetPos()
        -- Forward
        local success, pos = self:FindPassableSpace(ply, forward, SearchScale, origPos)

        -- Back
        if not success then
            success, pos = self:FindPassableSpace(ply, forward, -SearchScale, origPos)
        end

        -- Up
        if not success then
            success, pos = self:FindPassableSpace(ply, up, SearchScale, origPos)
        end

        -- Down
        if not success then
            success, pos = self:FindPassableSpace(ply, up, -SearchScale, origPos)
        end

        -- Left
        if not success then
            success, pos = self:FindPassableSpace(ply, right, -SearchScale, origPos)
        end

        -- Right
        if not success then
            success, pos = self:FindPassableSpace(ply, right, SearchScale, origPos)
        end

        if not success then return false end

        -- Not stuck?
        if oldPos == pos then
            return true
        else
            ply:SetPos(pos)

            if ply:IsValid() and ply:GetPhysicsObject():IsValid() then
                if ply:IsPlayer() then
                    ply:SetVelocity(vector_origin)
                end

                ply:GetPhysicsObject():SetVelocity(vector_origin) -- prevents bugs :s
            end

            return true
        end
    end
end

if SERVER then
    util.AddNetworkString("TTTPAPSetShield")
end

-- Drawing the shield bar
if CLIENT then
    net.Receive("TTTPAPSetShield", function()
        local maxShield = net.ReadUInt(10)
        local ply = LocalPlayer()

        hook.Add("DrawOverlay", "TTTPAPSetShield", function()
            local shield = ply:GetNWInt("PAPHealthShield", 0)
            if shield <= 0 then return end
            local text = string.format("%i", shield, maxShield) .. " Shield"
            local x = 19
            local y = ScrH() - 95

            -- Don't show shield bar if player is dead or has the pause menu open
            if ply:Alive() and not ply:IsSpec() and not gui.IsGameUIVisible() then
                local texttable = {}
                texttable.font = "HealthAmmo"
                texttable.color = COLOR_WHITE

                texttable.pos = {135, y + 25}

                texttable.text = text
                texttable.xalign = TEXT_ALIGN_LEFT
                texttable.yalign = TEXT_ALIGN_BOTTOM
                draw.RoundedBox(5, x, y, 233, 28, Color(43, 65, 65))
                draw.RoundedBox(5, x, y, (shield / maxShield) * 233, 28, Color(67, 216, 216))
                draw.TextShadow(texttable, 2)
            end
        end)
    end)
end

function UPGRADE:SetShield(p, maxShield, dmgResist, skipSetShield)
    dmgResist = 1 - dmgResist / 100

    if IsValid(p) then
        p:SetColor(Color(0, 255, 255))
        p:EmitSound("ttt_pack_a_punch/chug_jug_tool/shield.mp3")

        if not skipSetShield then
            p:SetNWInt("PAPHealthShield", maxShield)
        end
    end

    if SERVER then
        net.Start("TTTPAPSetShield")
        net.WriteUInt(maxShield, 10)
        net.Send(p)
    end

    -- Adding hard-coded fix for loosing shield while having PHD flopper, don't know how to do a proper generic fix for cases like that...
    local function ShouldBeImmune(ply, dmg)
        return ply:GetNWBool("PHDActive") and (dmg:IsFallDamage() or dmg:IsExplosionDamage())
    end

    -- Handling damage
    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not self:IsPlayer(ply) then return end
        local shield = ply:GetNWInt("PAPHealthShield", 0)

        if shield > 0 and not ShouldBeImmune(ply, dmg) then
            local attacker = dmg:GetAttacker()
            local damage = dmg:GetDamage() * dmgResist
            ply:SetNWInt("PAPHealthShield", math.floor(shield - damage))
            ply:EmitSound("ttt_pack_a_punch/chug_jug_tool/block.mp3")

            if self:IsPlayer(attacker) then
                attacker:SendLua("surface.PlaySound(\"ttt_pack_a_punch/chug_jug_tool/block.mp3\")")
            end

            if ply:GetNWInt("PAPHealthShield", 0) <= 0 then
                ply:SetColor(COLOR_WHITE)
                ply:EmitSound("ttt_pack_a_punch/chug_jug_tool/break.mp3")

                if self:IsPlayer(attacker) then
                    attacker:SendLua("surface.PlaySound(\"ttt_pack_a_punch/chug_jug_tool/break.mp3\")")
                end
            end

            dmg:ScaleDamage(0)
        end
    end)

    self:AddHook("PlayerSpawn", function(ply)
        ply:SetNWInt("PAPHealthShield", 0)
    end)

    self:AddHook("PostPlayerDeath", function(ply)
        ply:SetNWInt("PAPHealthShield", 0)
    end)

    hook.Add("TTTPrepareRound", "TTTPAPSetShield", function()
        for _, ply in player.Iterator() do
            ply:SetNWInt("PAPHealthShield", 0)
            ply:SetColor(COLOR_WHITE)
        end

        hook.Remove("TTTPrepareRound", "TTTPAPSetShield")
    end)
end

function UPGRADE:SetClip(SWEP, size)
    timer.Simple(0, function()
        SWEP.Primary.ClipSize = size
        SWEP.Primary.ClipMax = size

        if SWEP.Primary_TFA then
            SWEP.Primary_TFA.ClipSize = size
            SWEP.Primary_TFA.MaxAmmo = size
        end

        SWEP:SetClip1(size)
    end)
end

function UPGRADE:SetThirdPerson(ply, active)
    local id = "TTTPAP" .. self.id .. "ThirdPerson"

    if active == nil and not isbool(active) then
        active = true
    end

    if SERVER then
        ply:SetNWBool(id, active)

        hook.Add("TTTPrepareRound", id .. "Reset", function()
            for _, p in player.Iterator() do
                p:SetNWBool(id, nil)
            end

            hook.Remove("TTTPrepareRound", id .. "Reset")
        end)
    end

    if CLIENT and active then
        self:AddHook("CalcView", function(p, pos, angles, fov, znear, zfar)
            if not p:GetNWBool(id) then return end

            local view = {
                origin = util.TraceLine({
                    start = pos,
                    endpos = pos - angles:Forward() * 100,
                    filter = p
                }).HitPos,
                angles = angles,
                fov = fov,
                drawviewer = true,
                znear = znear,
                zfar = zfar
            }

            return view
        end)
    end
end

-- Making the metatable accessible to the base code by placing it in the TTTPAP namespace
TTTPAP.upgrade_meta = UPGRADE