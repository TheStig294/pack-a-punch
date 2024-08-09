local UPGRADE = {}
UPGRADE.id = "soul_powerer"
UPGRADE.class = "weapon_ttt_smg_soulbinding"
UPGRADE.name = "Soul Powerer"
UPGRADE.desc = "All Soulbound abilities are upgraded!"

UPGRADE.convars = {
    {
        name = "pap_soul_powerer_bee_barrel_bees",
        type = "int"
    },
    {
        name = "pap_soul_powerer_clown_transform_uses",
        type = "int"
    },
    {
        name = "pap_soul_powerer_clown_transform_delay",
        type = "int"
    },
    {
        name = "pap_soul_powerer_headcrab_launcher_uses",
        type = "int"
    },
    {
        name = "pap_soul_powerer_heal_uses",
        type = "int"
    },
    {
        name = "pap_soul_powerer_heal_cooldown",
        type = "float",
        decimals = 1
    },
    {
        name = "pap_soul_powerer_poison_headcrab_launcher_uses",
        type = "int"
    },
    {
        name = "pap_soul_powerer_swap_position_uses",
        type = "int"
    },
    {
        name = "pap_soul_powerer_swap_position_cooldown",
        type = "float",
        decimals = 1
    }
}

local bee_barrel_bees = CreateConVar("pap_soul_powerer_bee_barrel_bees", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Bees spawned by bee barrel ability", 1, 10)

local clown_transform_uses = CreateConVar("pap_soul_powerer_clown_transform_uses", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Uses of clown transform, 0 = infinite", 0, 10)

local clown_transform_delay = CreateConVar("pap_soul_powerer_clown_transform_delay", "10", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs delay of clown transform", 2, 60)

local headcrab_launcher_uses = CreateConVar("pap_soul_powerer_headcrab_launcher_uses", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Uses of spawn headcrab launcher", 1, 5)

local heal_uses = CreateConVar("pap_soul_powerer_heal_uses", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Uses of heal ability", 1, 10)

local heal_cooldown = CreateConVar("pap_soul_powerer_heal_cooldown", "30", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs cooldown of heal ability", 1, 60)

local poison_headcrab_launcher_uses = CreateConVar("pap_soul_powerer_poison_headcrab_launcher_uses", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Uses of spawn poison headcrab launcher", 1, 5)

local swap_position_uses = CreateConVar("pap_soul_powerer_swap_position_uses", "3", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Uses of swap position", 1, 10)

local swap_position_cooldown = CreateConVar("pap_soul_powerer_swap_position_cooldown", "5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Secs cooldown of swap position", 1, 60)

function UPGRADE:Apply(SWEP)
    -- Make a backup of old ability functionality
    if not SOULBOUND.PAPOldAbilities then
        SOULBOUND.PAPOldAbilities = {}
        SOULBOUND.PAPOldAbilities = table.Copy(SOULBOUND.Abilities)
    end

    -- Add PaP border to icons
    if CLIENT then
        -- Travels down the panel hierarchy of the buy menu, and returns a table of all buy menu icons
        local function GetItemIconPanels()
            local DFrame

            -- Look for the title name of the Soulbound buy menu, will break if the language placeholder name is changed...
            for _, child in ipairs(vgui.GetWorldPanel():GetChildren()) do
                if child.GetTitle and child:GetTitle() == LANG.GetTranslation("sbd_abilities_title") then
                    DFrame = child
                    break
                end
            end

            if not DFrame then return end

            -- First is the base panel parented to the DFrame, second is the scroll panel, third is the "EquipSelect" custom gui element from base TTT,
            -- containing all buy menu icons as "LayeredIcon" vgui elements
            -- A table of those "LayeredIcon"(s) is returned (The buy menu icons)
            local panelHierachy = {5, 2, 1}

            local buyMenu = DFrame:GetChildren()

            -- From here, things get unavoidably arbitrary
            -- Hopefully Panel:GetChildren() always returns these child panels the same way every time since they don't have any sort of ID
            -- Being super careful here to check for nil or empty table values at each step,
            -- since Gmod store skins or future updates for the buy menu could render it unusable otherwise
            for _, childIndex in ipairs(panelHierachy) do
                if not buyMenu or table.IsEmpty(buyMenu) then return end
                buyMenu = buyMenu[childIndex]
                if not buyMenu then return end
                buyMenu = buyMenu:GetChildren()
            end

            return buyMenu
        end

        local iconsWithUpgrades = {
            ["vgui/ttt/roles/sbd/abilities/icon_beebarrel.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_box.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_confetti.png"] = true,
            ["vgui/ttt/icon_beacon"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_discombob.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_dropweapon.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_explosivebarrel.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_body.png"] = true,
            ["vgui/ttt/icon_c4"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_gunshots.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_headcrab.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_heal.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_incendiary.png"] = true,
            ["vgui/ttt/ttt_pack_a_punch.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_poisonheadcrab.png"] = true,
            ["vgui/ttt/icon_polter"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_possession.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_reveal.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_smoke.png"] = true,
            ["vgui/ttt/roles/sbd/abilities/icon_swapinventory.png"] = true
        }

        local client

        self:AddHook("OnContextMenuOpen", function()
            -- This code is copied from the soulbound buy menu opening hook to ensure we're only looking for the soulbound buy menu when we should be
            if GetRoundState() ~= ROUND_ACTIVE then return end

            if not client then
                client = LocalPlayer()
            end

            if not client:IsSoulbound() then return end

            timer.Simple(0.1, function()
                local itemIcons = GetItemIconPanels()
                if not itemIcons or table.IsEmpty(itemIcons) then return end

                for _, iconPanel in ipairs(itemIcons) do
                    if not iconsWithUpgrades[iconPanel:GetIcon()] then continue end
                    local icon = vgui.Create("DImage")
                    icon:SetImage("ttt_pack_a_punch/soul_powerer/pap_camo_frame")
                    icon:SetTooltip("Upgraded")
                    -- Set the icon to be faded if the buy menu icon is faded (e.g. weapon is already bought)
                    icon:SetImageColor(iconPanel.Icon:GetImageColor())

                    -- This is how other overlayed icons are done in vanilla TTT, so we do the same here
                    -- This normally used for the slot icon and custom item icon
                    icon.PerformLayout = function(s)
                        s:SetSize(64, 64)
                    end

                    iconPanel:AddLayer(icon)
                    iconPanel:EnableMousePassthrough(icon)
                end
            end)
        end)
    end

    -- 
    -- Bee barrel
    -- 
    local ABILITY = SOULBOUND.Abilities["beebarrel"]
    ABILITY.Name = "Place Upgraded Bee Barrel"
    ABILITY.Description = "Place an upgraded bee barrel that will release big invincible bees when it explodes!"
    local beebarrel_uses = GetConVar("ttt_soulbound_beebarrel_uses")
    local beebarrel_cooldown = GetConVar("ttt_soulbound_beebarrel_cooldown")

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundBeeBarrelUses", beebarrel_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundBeeBarrelNextUse", CurTime())

        UPGRADE:AddHook("EntityTakeDamage", function(target, dmginfo)
            -- Spawned bees are invincible
            if target.TTTPAPSoulboundBee then return true end
            if target:GetClass() ~= "prop_physics" then return end
            if dmginfo:GetDamage() < 1 then return end
            local model = target:GetModel()
            if model ~= "models/bee_drum/beedrum002_explosive.mdl" then return end
            local pos = target:GetPos()
            local isUpgradedBarrel = target:GetMaterial() == TTTPAP.camo

            timer.Create("TTTSoulboundBeeBarrelSpawn", 0.1, bee_barrel_bees:GetInt(), function()
                local spos = pos + Vector(math.random(-50, 50), math.random(-50, 50), math.random(0, 100))
                local headBee = ents.Create("npc_manhack")
                headBee:SetPos(spos)
                headBee:Spawn()
                headBee:Activate()
                headBee:SetNPCState(NPC_STATE_ALERT)

                if scripted_ents.Get("ttt_beenade_proj") ~= nil then
                    local bee = ents.Create("prop_dynamic")
                    bee:SetModel("models/lucian/props/stupid_bee.mdl")
                    bee:SetPos(spos)
                    bee:SetParent(headBee)
                    headBee:SetNoDraw(true)

                    if isUpgradedBarrel then
                        bee:SetModelScale(5, 0.0001)
                        bee:Activate()
                        bee:SetMaterial(TTTPAP.camo)
                        bee.TTTPAPSoulboundBee = true
                        headBee:SetModelScale(5, 0.0001)
                        headBee:Activate()
                        headBee.TTTPAPSoulboundBee = true
                    end
                end

                headBee:SetHealth(100000)
            end, "TTTSoulboundBeeBarrelDamage")
        end)
    end

    function ABILITY:Use(soulbound, target)
        local plyPos = soulbound:GetPos()
        local hitPos = soulbound:GetEyeTrace().HitPos
        local vec = hitPos - plyPos
        local fwd = Vector(0, 0, 0)

        if target then
            fwd = soulbound:GetForward() * 48
            vec = Vector(0, 0, -1)
        end

        local spawnPos = hitPos - (vec:GetNormalized() * 15) + fwd
        local ent = ents.Create("prop_physics")
        ent:SetModel("models/bee_drum/beedrum002_explosive.mdl")
        ent:SetPos(spawnPos)
        ent:Spawn()
        ent:SetMaterial(TTTPAP.camo)
        local uses = soulbound:GetNWInt("TTTSoulboundBeeBarrelUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundBeeBarrelUses", uses)
        soulbound:SetNWFloat("TTTSoulboundBeeBarrelNextUse", CurTime() + beebarrel_cooldown:GetFloat())
    end

    SOULBOUND.Abilities["beebarrel"] = ABILITY
    -- 
    -- Box
    -- 
    ABILITY = SOULBOUND.Abilities["box"]
    ABILITY.Name = "Place Zombie Box"
    ABILITY.Description = "Place a big box with a zombie inside"
    local box_uses = GetConVar("ttt_soulbound_box_uses")
    local box_cooldown = GetConVar("ttt_soulbound_box_cooldown")

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundBoxUses", box_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundBoxNextUse", CurTime())

        UPGRADE:AddHook("PropBreak", function(attacker, prop)
            if prop.PAPSoulboundZombieBox then
                local zombie = ents.Create("npc_zombie")
                zombie:SetPos(prop:GetPos())
                zombie:Spawn()
            end
        end, "TTTPAPSoulboundZombieBox")
    end

    function ABILITY:Use(soulbound, target)
        local plyPos = soulbound:GetPos()
        local hitPos = soulbound:GetEyeTrace().HitPos
        local vec = hitPos - plyPos
        local fwd = Vector(0, 0, 0)

        if target then
            fwd = soulbound:GetForward() * 64
            vec = Vector(0, 0, -1)
        end

        local spawnPos = hitPos - (vec:GetNormalized() * 40) + fwd
        local ent = ents.Create("prop_physics")
        ent:SetModel("models/props_junk/wood_crate001a.mdl")
        ent:SetPos(spawnPos)
        ent:Spawn()
        ent:SetModelScale(2)
        ent:Activate()
        ent:SetMaterial(TTTPAP.camo)
        ent.PAPSoulboundZombieBox = true
        local uses = soulbound:GetNWInt("TTTSoulboundBoxUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundBoxUses", uses)
        soulbound:SetNWFloat("TTTSoulboundBoxNextUse", CurTime() + box_cooldown:GetFloat())
    end

    SOULBOUND.Abilities["box"] = ABILITY
    -- 
    -- Confetti
    -- 
    ABILITY = SOULBOUND.Abilities["confetti"]
    ABILITY.Name = "Clown Transform"
    ABILITY.Description = "Transform a non-traitor player into a clown, then force-activate them after " .. clown_transform_delay:GetInt() .. " seconds"

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundConfettiUses", clown_transform_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundConfettiNextUse", CurTime())
    end

    function ABILITY:Condition(soulbound, target)
        if not IsValid(target) or not target:IsPlayer() or not target:Alive() or target:IsSpec() then
            soulbound:QueueMessage(MSG_PRINTCENTER, "Spectate a player first!", 3)

            return false
        end

        if target:IsTraitorTeam() then
            soulbound:ChatPrint("Cannot transform traitors")

            return false
        end

        if not soulbound:IsInWorld() then return false end
        if clown_transform_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundConfettiUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundConfettiNextUse") then return false end

        return true
    end

    local ActivateClown

    if SERVER then
        local clown_activation_credits = GetConVar("ttt_clown_activation_credits")
        local clown_use_traps_when_active = GetConVar("ttt_clown_use_traps_when_active")
        local clown_heal_on_activate = GetConVar("ttt_clown_heal_on_activate")
        local clown_heal_bonus = GetConVar("ttt_clown_heal_bonus")

        function ActivateClown(clown)
            SetClownTeam(true)
            clown:QueueMessage(MSG_PRINTBOTH, "KILL THEM ALL!")
            clown:AddCredits(clown_activation_credits:GetInt())

            if clown_heal_on_activate:GetBool() then
                local heal_bonus = clown_heal_bonus:GetInt()
                local health = clown:GetMaxHealth() + heal_bonus
                clown:SetHealth(health)

                if heal_bonus > 0 then
                    clown:PrintMessage(HUD_PRINTTALK, "You have been fully healed (with a bonus)!")
                else
                    clown:PrintMessage(HUD_PRINTTALK, "You have been fully healed!")
                end
            end

            net.Start("TTT_ClownActivate")
            net.WritePlayer(clown)
            net.Broadcast()

            -- Give the clown their shop items if purchase was delayed
            if clown.bought and GetConVar("ttt_clown_shop_delay"):GetBool() then
                clown:GiveDelayedShopItems()
            end

            -- Enable traitor buttons for them, if that's enabled
            TRAITOR_BUTTON_ROLES[ROLE_CLOWN] = clown_use_traps_when_active:GetBool()
        end
    end

    function ABILITY:Use(soulbound, target)
        soulbound:QueueMessage(MSG_PRINTCENTER, target:Nick() .. " will activate in " .. clown_transform_delay:GetInt() .. " seconds!")
        local timerName = "TTTPAPSoulboundClownTransform" .. target:SteamID64()
        target:SetRole(ROLE_CLOWN)

        timer.Create(timerName, 1, clown_transform_delay:GetInt(), function()
            if not IsValid(target) or GetRoundState() ~= ROUND_ACTIVE then
                timer.Remove(timerName)

                return
            end

            local countdown = timer.RepsLeft(timerName)

            if countdown > 0 then
                target:PrintMessage(HUD_PRINTCENTER, "A Soulbound used their power to transform you into a Clown! Activating in: " .. countdown)
                -- Don't activate the player if they are dead or already activated
            elseif target:Alive() and not target:IsSpec() and not (target:IsClown() and target:IsRoleActive()) then
                target:SetRole(ROLE_CLOWN)

                if SERVER then
                    SendFullStateUpdate()
                    ActivateClown(target)
                end
            end
        end)

        local uses = soulbound:GetNWInt("TTTSoulboundConfettiUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundConfettiUses", uses)
        soulbound:SetNWFloat("TTTSoulboundConfettiNextUse", CurTime() + clown_transform_delay:GetInt())
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = clown_transform_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundConfettiUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text = "Press '" .. key .. "' to transform player into clown"
            local next_use = soulbound:GetNWFloat("TTTSoulboundConfettiNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["confetti"] = ABILITY
    -- 
    -- Decoy
    -- 
    ABILITY = SOULBOUND.Abilities["decoy"]
    ABILITY.Name = "Place Decoys"
    ABILITY.Description = "Place down a bunch of decoys around the map"
    local decoy_uses = GetConVar("ttt_soulbound_decoy_uses")

    function ABILITY:Bought(soulbound)
        ABILITY.PAPOldUses = ABILITY.PAPOldUses or decoy_uses:GetInt()
        decoy_uses:SetInt(1)
        soulbound:SetNWInt("TTTSoulboundDecoyUses", decoy_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundDecoyNextUse", CurTime())
    end

    function ABILITY:Use(soulbound, target)
        soulbound:EmitSound("Weapon_SLAM.SatchelThrow")
        local playerPositions = {}

        for _, ply in ipairs(player.GetAll()) do
            if UPGRADE:IsAlive(ply) then
                table.insert(playerPositions, ply:GetPos())
            end
        end

        for _, ent in ipairs(ents.GetAll()) do
            local classname = ent:GetClass()
            local pos = ent:GetPos()
            local infoEnt = string.StartWith(classname, "info_")

            -- Using the positions of weapon, ammo and player spawns
            if (string.StartWith(classname, "weapon_") or string.StartWith(classname, "item_") or infoEnt) and not IsValid(ent:GetParent()) and math.random() < 0.2 then
                local tooClose = false

                for _, plyPos in ipairs(playerPositions) do
                    -- 100 * 100 = 10,000, so any positions closer than 100 source units to a player are too close to be placed
                    if math.DistanceSqr(pos.x, pos.y, plyPos.x, plyPos.y) < 10000 then
                        tooClose = true
                        break
                    end
                end

                if not tooClose then
                    local decoy = ents.Create("ttt_decoy")

                    if IsValid(decoy) then
                        decoy:SetPos(pos + Vector(0, 0, 5))
                        decoy:SetOwner(soulbound)
                        decoy:Spawn()
                        decoy:SetMaterial(TTTPAP.camo)
                        local ang = decoy:GetAngles()
                        ang:RotateAroundAxis(ang:Right(), 90)
                        decoy:SetAngles(ang)
                        decoy:PhysWake()
                    end

                    -- Don't remove player spawn points
                    if not infoEnt then
                        ent:Remove()
                    end
                end
            end
        end

        local uses = soulbound:GetNWInt("TTTSoulboundDecoyUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundDecoyUses", uses)
    end

    function ABILITY:Cleanup(soulbound)
        decoy_uses:SetInt(ABILITY.PAPOldUses or 5)
        soulbound:SetNWInt("TTTSoulboundDecoyUses", 0)
    end

    SOULBOUND.Abilities["decoy"] = ABILITY
    -- 
    -- Discombob
    -- 
    ABILITY = SOULBOUND.Abilities["discombob"]
    ABILITY.Description = "Throw an upgraded discombobulator"
    local discombob_fuse_time = GetConVar("ttt_soulbound_discombob_fuse_time")
    local discombob_cooldown = GetConVar("ttt_soulbound_discombob_cooldown")

    function ABILITY:Use(soulbound, target)
        local ang = soulbound:EyeAngles()
        local src = soulbound:GetPos() + (soulbound:Crouching() and soulbound:GetViewOffsetDucked() or soulbound:GetViewOffset()) + (ang:Forward() * 8) + (ang:Right() * 10)
        local pos = soulbound:GetEyeTraceNoCursor().HitPos
        local tang = (pos - src):Angle() -- A target angle to actually throw the grenade to the crosshair instead of fowards

        -- Makes the grenade go upwards
        if tang.p < 90 then
            tang.p = -10 + tang.p * ((90 + 10) / 90)
        else
            tang.p = 360 - tang.p
            tang.p = -10 + tang.p * -((90 + 10) / 90)
        end

        tang.p = math.Clamp(tang.p, -90, 90) -- Makes the grenade not go backwards :/
        local vel = math.min(800, (90 - tang.p) * 6)
        local thr = tang:Forward() * vel + soulbound:GetVelocity()
        local gren = ents.Create("ttt_pap_bristol_pusher_nade")
        if not IsValid(gren) then return end
        gren:SetPos(src)
        gren:SetAngles(Angle(0, 0, 0))
        gren:SetOwner(soulbound)
        gren:SetThrower(soulbound)
        gren:SetGravity(0.4)
        gren:SetFriction(0.2)
        gren:SetElasticity(0.45)
        gren:Spawn()
        gren:PhysWake()
        local phys = gren:GetPhysicsObject()

        if IsValid(phys) then
            phys:SetVelocity(thr)
            phys:AddAngleVelocity(Vector(600, math.random(-1200, 1200)), 0)
        end

        gren:SetDetonateExact(CurTime() + discombob_fuse_time:GetFloat())
        local uses = soulbound:GetNWInt("TTTSoulboundDiscombobUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundDiscombobUses", uses)
        soulbound:SetNWFloat("TTTSoulboundDiscombobNextUse", CurTime() + discombob_cooldown:GetFloat())
    end

    SOULBOUND.Abilities["discombob"] = ABILITY
    -- 
    -- Drop Weapon
    -- 
    ABILITY = SOULBOUND.Abilities["dropweapon"]
    ABILITY.Name = "Drop All Weapons"
    ABILITY.Description = "Force the player you are spectating to drop all of their weapons"
    local dropweapon_cooldown = GetConVar("ttt_soulbound_dropweapon_cooldown")
    local dropweapon_uses = GetConVar("ttt_soulbound_dropweapon_uses")

    function ABILITY:Use(soulbound, target)
        local activeWep = target:GetActiveWeapon()
        local skipFOVReset = not IsValid(activeWep)
        local droppedAWeapon = false

        for _, wep in ipairs(target:GetWeapons()) do
            if IsValid(wep) and wep.AllowDrop then
                target:DropWeapon(wep)
                droppedAWeapon = true

                if not skipFOVReset and wep == activeWep then
                    target:SetFOV(0, 0.2)
                    skipFOVReset = true
                end
            end
        end

        if droppedAWeapon then
            local uses = soulbound:GetNWInt("TTTSoulboundDropWeaponUses", 0)
            uses = math.max(uses - 1, 0)
            soulbound:SetNWInt("TTTSoulboundDropWeaponUses", uses)
            soulbound:SetNWFloat("TTTSoulboundDropWeaponNextUse", CurTime() + dropweapon_cooldown:GetFloat())
        end
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = dropweapon_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundDropWeaponUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text
            local next_use = soulbound:GetNWFloat("TTTSoulboundDropWeaponNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            else
                local target = soulbound:GetObserverMode() ~= OBS_MODE_ROAMING and soulbound:GetObserverTarget() or nil

                if not target or not IsPlayer(target) then
                    ready = false
                    text = "Spectate a player"
                else
                    local droppableWeapon = false

                    for _, wep in ipairs(target:GetWeapons()) do
                        if IsValid(wep) and wep.AllowDrop then
                            droppableWeapon = true
                            break
                        end
                    end

                    if droppableWeapon then
                        text = "Press '" .. key .. "' to make " .. target:Nick() .. " drop their weapons"
                    else
                        ready = false
                        text = target:Nick() .. "'s held weapons can't be dropped"
                    end
                end
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["dropweapon"] = ABILITY
    -- 
    -- Explosive Barrel
    -- 
    ABILITY = SOULBOUND.Abilities["explosivebarrel"]
    ABILITY.Name = "Place Explosive Barrels"
    ABILITY.Description = "Place several explosive barrels"
    local explosivebarrel_uses = GetConVar("ttt_soulbound_explosivebarrel_uses")
    local explosivebarrel_cooldown = GetConVar("ttt_soulbound_explosivebarrel_cooldown")

    function ABILITY:Use(soulbound, target)
        local plyPos = soulbound:GetPos()
        local hitPos = soulbound:GetEyeTrace().HitPos
        local vec = hitPos - plyPos
        local spawnPos = hitPos - (vec:GetNormalized() * 15)
        local ent = ents.Create("ttt_pap_barrel_bomb_proj")
        ent:SetPos(spawnPos)
        ent:Spawn()
        ent:Explode(util.QuickTrace(spawnPos, Vector(0, 0, -1)))
        local uses = soulbound:GetNWInt("TTTSoulboundExplosiveBarrelUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundExplosiveBarrelUses", uses)
        soulbound:SetNWFloat("TTTSoulboundExplosiveBarrelNextUse", CurTime() + explosivebarrel_cooldown:GetFloat())
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = explosivebarrel_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundExplosiveBarrelUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text = "Press '" .. key .. "' to place explosive barrels"
            local next_use = soulbound:GetNWFloat("TTTSoulboundExplosiveBarrelNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    -- 
    -- Fake Body
    -- 
    ABILITY = SOULBOUND.Abilities["fakebody"]
    ABILITY.Name = "Place Explosive Fake Body"
    ABILITY.Description = "Place a fake dead body that looks like you. Explodes when searched"
    local fakebody_cooldown = GetConVar("ttt_soulbound_fakebody_cooldown")

    local deathsounds = {Sound("player/death1.wav"), Sound("player/death2.wav"), Sound("player/death3.wav"), Sound("player/death4.wav"), Sound("player/death5.wav"), Sound("player/death6.wav"), Sound("vo/npc/male01/pain07.wav"), Sound("vo/npc/male01/pain08.wav"), Sound("vo/npc/male01/pain09.wav"), Sound("vo/npc/male01/pain04.wav"), Sound("vo/npc/Barney/ba_pain06.wav"), Sound("vo/npc/Barney/ba_pain07.wav"), Sound("vo/npc/Barney/ba_pain09.wav"), Sound("vo/npc/Barney/ba_ohshit03.wav"), Sound("vo/npc/Barney/ba_no01.wav"), Sound("vo/npc/male01/no02.wav"), Sound("hostage/hpain/hpain1.wav"), Sound("hostage/hpain/hpain2.wav"), Sound("hostage/hpain/hpain3.wav"), Sound("hostage/hpain/hpain4.wav"), Sound("hostage/hpain/hpain5.wav"), Sound("hostage/hpain/hpain6.wav")}

    function ABILITY:Use(soulbound, target)
        local plyPos = soulbound:GetPos()
        local hitPos = soulbound:GetEyeTrace().HitPos
        local vec = hitPos - plyPos
        local fwd = Vector(0, 0, 0)

        if target then
            fwd = soulbound:GetForward() * 48
            vec = Vector(0, 0, -1)
        end

        local spawnPos = hitPos - (vec:GetNormalized() * 40) + fwd
        local ragdoll = ents.Create("prop_ragdoll")
        ragdoll:SetPos(spawnPos)
        ragdoll:SetModel(soulbound:GetModel())
        ragdoll:SetSkin(soulbound:GetSkin())

        for _, value in pairs(soulbound:GetBodyGroups()) do
            ragdoll:SetBodygroup(value.id, soulbound:GetBodygroup(value.id))
        end

        ragdoll:SetAngles(soulbound:GetAngles())
        ragdoll:SetColor(soulbound:GetColor())
        ragdoll:Spawn()
        ragdoll:Activate()
        ragdoll.TTTPAPOwner = soulbound

        timer.Create("FakeRagdoll" .. tostring(CurTime()), 0.5, 5, function()
            local jitter = VectorRand() * 30
            jitter.z = 20
            util.PaintDown(ragdoll:GetPos() + jitter, "Blood", ragdoll)
        end)

        -- Trick the game into thinking this is a real dead body but dont provide an ID so defibs dont work
        CORPSE.SetPlayerNick(ragdoll, soulbound)
        ragdoll.player_ragdoll = true
        ragdoll:SetNWBool("TTTSoulboundIsPAPFakeRagdoll", true)
        sound.Play(deathsounds[math.random(#deathsounds)], spawnPos, 90, 100)
        local uses = soulbound:GetNWInt("TTTSoulboundFakeBodyUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundFakeBodyUses", uses)
        soulbound:SetNWFloat("TTTSoulboundFakeBodyNextUse", CurTime() + fakebody_cooldown:GetFloat())
    end

    self:AddHook("TTTCanSearchCorpse", function(ply, corpse, is_covert, is_long_range, was_traitor)
        if corpse:GetNWBool("TTTSoulboundIsPAPFakeRagdoll", false) then
            local explode = ents.Create("env_explosion")
            explode:SetPos(corpse:GetPos())
            explode:SetOwner(corpse.TTTPAPOwner)
            explode:Spawn()
            explode:SetKeyValue("iMagnitude", "200")
            explode:SetKeyValue("iRadiusOverride", "256")
            explode:Fire("Explode", 0, 0)
            explode:EmitSound("weapon_AWP.Single", 400, 400)
            corpse:Remove()

            return false
        end
    end)

    SOULBOUND.Abilities["fakebody"] = ABILITY
    -- 
    -- C4
    -- 
    ABILITY = SOULBOUND.Abilities["fakec4"]
    ABILITY.Name = "Place C4"
    local fakec4_fuse = GetConVar("ttt_soulbound_fakec4_fuse")
    local fakec4_uses = GetConVar("ttt_soulbound_fakec4_uses")
    local fakec4_cooldown = GetConVar("ttt_soulbound_fakec4_cooldown")
    ABILITY.Description = "Place a C4 that explodes after " .. fakec4_fuse:GetInt() .. " seconds"

    function ABILITY:Use(soulbound, target)
        local plyPos = soulbound:GetPos()
        local hitPos = soulbound:GetEyeTrace().HitPos
        local vec = hitPos - plyPos
        local fwd = Vector(0, 0, 0)

        if target then
            fwd = soulbound:GetForward() * 48
            vec = Vector(0, 0, -1)
        end

        local spawnPos = hitPos - (vec:GetNormalized() * 15) + fwd
        local ent = ents.Create("ttt_c4")
        ent:SetPos(spawnPos)
        ent:Spawn()
        ent:PhysWake()

        -- Wait a moment before arming so the bomb isnt floating in the air
        timer.Simple(3, function()
            if IsValid(ent) then
                ent:Arm(soulbound, fakec4_fuse:GetInt())
            end
        end)

        local uses = soulbound:GetNWInt("TTTSoulboundFakeC4Uses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundFakeC4Uses", uses)
        soulbound:SetNWFloat("TTTSoulboundFakeC4NextUse", CurTime() + fakec4_cooldown:GetFloat())
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = fakec4_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundFakeC4Uses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text = "Press '" .. key .. "' to place C4, explodes after " .. fakec4_fuse:GetInt() .. " seconds"
            local next_use = soulbound:GetNWFloat("TTTSoulboundFakeC4NextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["fakec4"] = ABILITY
    -- 
    -- Gunshots
    -- 
    ABILITY = SOULBOUND.Abilities["gunshots"]
    ABILITY.Name = "Force Shoot"
    ABILITY.Description = "Force the player you are spectating to shoot"
    local gunshots_uses = GetConVar("ttt_soulbound_gunshots_uses")
    local gunshots_cooldown = GetConVar("ttt_soulbound_gunshots_cooldown")

    function ABILITY:Condition(soulbound, target)
        if gunshots_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundGunshotsUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundGunshotsNextUse") then return false end
        if not target or not IsPlayer(target) then return false end
        local wep = target:GetActiveWeapon()
        if not IsValid(wep) or not wep.CanPrimaryAttack or not wep:CanPrimaryAttack() then return false end

        return true
    end

    function ABILITY:Use(soulbound, target)
        local wep = target:GetActiveWeapon()

        if IsValid(wep) and wep.CanPrimaryAttack and wep:CanPrimaryAttack() then
            target:SetNWBool("TTTPAPSoulboundGunshots", true)

            timer.Simple(gunshots_cooldown:GetInt(), function()
                if IsValid(target) then
                    target:SetNWBool("TTTPAPSoulboundGunshots", false)
                end
            end)
        end

        local uses = soulbound:GetNWInt("TTTSoulboundGunshotsUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundGunshotsUses", uses)
        soulbound:SetNWFloat("TTTSoulboundGunshotsNextUse", CurTime() + gunshots_cooldown:GetFloat())
    end

    self:AddHook("StartCommand", function(ply, ucmd)
        if ply:GetNWBool("TTTPAPSoulboundGunshots") then
            ucmd:SetButtons(ucmd:GetButtons() + IN_ATTACK)
        end
    end)

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = gunshots_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundGunshotsUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text
            local next_use = soulbound:GetNWFloat("TTTSoulboundGunshotsNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            else
                local target = soulbound:GetObserverMode() ~= OBS_MODE_ROAMING and soulbound:GetObserverTarget() or nil

                if not target or not IsPlayer(target) then
                    ready = false
                    text = "Spectate a player"
                else
                    local wep = target:GetActiveWeapon()

                    if IsValid(wep) and wep.CanPrimaryAttack and wep:CanPrimaryAttack() then
                        text = "Press '" .. key .. "' to make " .. target:Nick() .. " shoot"
                    else
                        ready = false
                        text = target:Nick() .. "'s held weapon can't be forced to shoot"
                    end
                end
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["gunshots"] = ABILITY
    -- 
    -- Headcrab
    -- 
    ABILITY = SOULBOUND.Abilities["headcrab"]
    ABILITY.Name = "Spawn Headcrabs"
    ABILITY.Description = "*ONLY WORKS OUTSIDE*\nSpawn a headcrab launcher from the sky that slams into the ground, contaning 8 regular headcrabs"
    local headcrab_cooldown = GetConVar("ttt_soulbound_headcrab_cooldown")

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundHeadcrabUses", headcrab_launcher_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundHeadcrabNextUse", CurTime())
    end

    -- This function is from the headcrab launcher weapon: https://steamcommunity.com/sharedfiles/filedetails/?id=911182038
    function ABILITY:CheckForSky(tr)
        local YawIncrement = 20
        local PitchIncrement = 10
        local aBaseAngle = tr.HitNormal:Angle()
        local aBasePos = tr.HitPos
        local bScanning = true
        local iPitch = 10
        local iYaw = -180
        local iLoopLimit = 0
        local iProcessedTotal = 0
        local tValidHits = {}

        while bScanning and iLoopLimit < 500 do
            iYaw = iYaw + YawIncrement
            iProcessedTotal = iProcessedTotal + 1

            if iYaw >= 180 then
                iYaw = -180
                iPitch = iPitch - PitchIncrement
            end

            local tLoop = util.QuickTrace(aBasePos, (aBaseAngle + Angle(iPitch, iYaw, 0)):Forward() * 40000)

            if tLoop.HitSky then
                table.insert(tValidHits, tLoop)
            end

            if iPitch <= -80 then
                bScanning = false
            end

            iLoopLimit = iLoopLimit + 1
        end

        return tValidHits, aBasePos
    end

    function ABILITY:Condition(soulbound, target)
        if not soulbound:IsInWorld() then return false end
        if headcrab_launcher_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundHeadcrabUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundHeadcrabNextUse") then return false end
        local tValidHits = self:CheckForSky(soulbound:GetEyeTrace())

        if #tValidHits > 0 then
            return true
        else
            soulbound:SendLua("surface.PlaySound(\"WallHealth.Deny\")")
            soulbound:ChatPrint("Can't spawn, try outside")

            return false
        end
    end

    function ABILITY:Use(soulbound, target)
        local tValidHits, aBasePos = self:CheckForSky(soulbound:GetEyeTrace())
        local iHits = #tValidHits
        local iRand = math.random(3, iHits)
        local tRand = tValidHits[iRand]
        local rocket = ents.Create("env_headcrabcanister")
        rocket:SetPos(aBasePos)
        rocket:SetAngles((tRand.HitPos - tRand.StartPos):Angle())
        -- These numbers are from "big crab launcher" upgrade, the default damage convar values for that upgrade
        -- Direct damage from being hit by the headcrab launcher should never kill someone at full health
        -- Type 1 = fast headcrabs, ones from fast zombies
        rocket:SetKeyValue("HeadcrabType", 1)
        rocket:SetKeyValue("HeadcrabCount", 8)
        rocket:SetKeyValue("FlightSpeed", 2000)
        rocket:SetKeyValue("FlightTime", 2.5)
        rocket:SetKeyValue("Damage", 30)
        rocket:SetKeyValue("DamageRadius", 150)
        rocket:SetKeyValue("SmokeLifetime", 3)
        rocket:SetKeyValue("StartingHeight", 1000)
        rocket:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        rocket:SetKeyValue("spawnflags", 8192)
        rocket:Spawn()
        rocket:Input("FireCanister", soulbound, soulbound)
        local uses = soulbound:GetNWInt("TTTSoulboundHeadcrabUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundHeadcrabUses", uses)
        soulbound:SetNWFloat("TTTSoulboundHeadcrabNextUse", CurTime() + headcrab_cooldown:GetFloat())
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = headcrab_launcher_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundHeadcrabUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text = "Press '" .. key .. "' to spawn a headcrab launcher"
            local next_use = soulbound:GetNWFloat("TTTSoulboundHeadcrabNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["headcrab"] = ABILITY
    -- 
    -- Heal
    -- 
    ABILITY = SOULBOUND.Abilities["heal"]
    ABILITY.Name = "Heal Instantly"
    ABILITY.Description = "Instanly heal the player you are spectating to full health"

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundHealUses", heal_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundHealNextUse", CurTime())
    end

    function ABILITY:Condition(soulbound, target)
        if heal_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundHealUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundHealNextUse") then return false end
        if not target or not IsPlayer(target) then return false end
        if target:Health() >= target:GetMaxHealth() then return false end

        return true
    end

    function ABILITY:Use(soulbound, target)
        target:SetHealth(math.max(target:Health(), target:GetMaxHealth()))
        target:EmitSound("items/medshot4.wav")
        local uses = soulbound:GetNWInt("TTTSoulboundHealUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundHealUses", uses)
        soulbound:SetNWFloat("TTTSoulboundHealNextUse", CurTime() + heal_cooldown:GetFloat())
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = heal_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundHealUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text
            local next_use = soulbound:GetNWFloat("TTTSoulboundHealNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            else
                local target = soulbound:GetObserverMode() ~= OBS_MODE_ROAMING and soulbound:GetObserverTarget() or nil

                if not target or not IsPlayer(target) then
                    ready = false
                    text = "Spectate a player"
                else
                    if target:Health() >= target:GetMaxHealth() then
                        ready = false
                        text = target:Nick() .. " is at full health or more"
                    else
                        text = "Press '" .. key .. "' to heal " .. target:Nick()
                    end
                end
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["heal"] = ABILITY
    -- 
    -- Incendiary
    -- 
    ABILITY = SOULBOUND.Abilities["incendiary"]
    ABILITY.Description = "Throw a big incendiary grenade, the fire lasts a very long time"
    local incendiary_fuse_time = GetConVar("ttt_soulbound_incendiary_fuse_time")
    local incendiary_cooldown = GetConVar("ttt_soulbound_incendiary_cooldown")

    function ABILITY:Use(soulbound, target)
        local ang = soulbound:EyeAngles()
        local src = soulbound:GetPos() + (soulbound:Crouching() and soulbound:GetViewOffsetDucked() or soulbound:GetViewOffset()) + (ang:Forward() * 8) + (ang:Right() * 10)
        local pos = soulbound:GetEyeTraceNoCursor().HitPos
        local tang = (pos - src):Angle() -- A target angle to actually throw the grenade to the crosshair instead of fowards

        -- Makes the grenade go upwards
        if tang.p < 90 then
            tang.p = -10 + tang.p * ((90 + 10) / 90)
        else
            tang.p = 360 - tang.p
            tang.p = -10 + tang.p * -((90 + 10) / 90)
        end

        tang.p = math.Clamp(tang.p, -90, 90) -- Makes the grenade not go backwards :/
        local vel = math.min(800, (90 - tang.p) * 6)
        local thr = tang:Forward() * vel + soulbound:GetVelocity()
        local gren = ents.Create("ttt_pap_forever_fire_nade")
        if not IsValid(gren) then return end
        gren:SetPos(src)
        gren:SetAngles(Angle(0, 0, 0))
        gren:SetOwner(soulbound)
        gren:SetThrower(soulbound)
        gren:SetGravity(0.4)
        gren:SetFriction(0.2)
        gren:SetElasticity(0.45)
        gren:Spawn()
        gren:PhysWake()
        local phys = gren:GetPhysicsObject()

        if IsValid(phys) then
            phys:SetVelocity(thr)
            phys:AddAngleVelocity(Vector(600, math.random(-1200, 1200)), 0)
        end

        gren:SetDetonateExact(CurTime() + incendiary_fuse_time:GetFloat())
        local uses = soulbound:GetNWInt("TTTSoulboundIncendiaryUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundIncendiaryUses", uses)
        soulbound:SetNWFloat("TTTSoulboundIncendiaryNextUse", CurTime() + incendiary_cooldown:GetFloat())
    end

    SOULBOUND.Abilities["incendiary"] = ABILITY
    -- 
    -- Pack-a-Punch
    -- 
    ABILITY = SOULBOUND.Abilities["packapunch"]
    ABILITY.Name = "Pack-a-Punch All Weps"
    ABILITY.Description = "Try to upgrade all of the weapons of the player you are spectating"
    local packapunch_uses = GetConVar("ttt_soulbound_packapunch_uses")
    local packapunch_cooldown = GetConVar("ttt_soulbound_packapunch_cooldown")

    function ABILITY:Condition(soulbound, target)
        if packapunch_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundPackAPunchUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundPackAPunchNextUse") then return false end
        if not target or not IsPlayer(target) then return false end

        -- Check at least 1 weapon can be upgraded
        for _, wep in ipairs(target:GetWeapons()) do
            if TTTPAP:CanOrderPAP(wep) and WEPS.GetClass(wep) ~= "weapon_ttt_unarmed" then return true end
        end

        soulbound:SendLua("surface.PlaySound(\"WallHealth.Deny\")")
        soulbound:ChatPrint("None of their weapons can be upgraded")

        return false
    end

    function ABILITY:Use(soulbound, target)
        TTTPAP:OrderPAP(target)
        target:QueueMessage(MSG_PRINTBOTH, "A Soulbound is trying to upgrade ALL of your weapons!")

        for _, wep in ipairs(target:GetWeapons()) do
            -- Check for a valid weapon, is not already upgraded, and not the "holstered" weapon
            if IsValid(wep) and WEPS.GetClass(wep) ~= "weapon_ttt_unarmed" then
                TTTPAP:ApplyRandomUpgrade(wep)
            end
        end

        local uses = soulbound:GetNWInt("TTTSoulboundPackAPunchUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundPackAPunchUses", uses)
        soulbound:SetNWFloat("TTTSoulboundPackAPunchNextUse", CurTime() + packapunch_cooldown:GetFloat())
    end

    if CLIENT then
        -- Adding chat messages to display what each upgrade does to the target player
        self:AddHook("PlayerSwitchWeapon", function(ply, oldSWEP, newSWEP)
            if IsValid(newSWEP) and newSWEP.PAPUpgrade and newSWEP.PAPUpgrade.desc then
                if not IsValid(newSWEP.LastPlayerSwitchedTo) or newSWEP.LastPlayerSwitchedTo ~= ply then
                    ply:ChatPrint("PAP UPGRADE: " .. newSWEP.PAPUpgrade.desc)
                end

                newSWEP.LastPlayerSwitchedTo = ply
            end
        end)

        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = packapunch_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundPackAPunchUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text
            local next_use = soulbound:GetNWFloat("TTTSoulboundPackAPunchNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            else
                local target = soulbound:GetObserverMode() ~= OBS_MODE_ROAMING and soulbound:GetObserverTarget() or nil

                if not target or not IsPlayer(target) then
                    ready = false
                    text = "Spectate a player"
                else
                    -- Check at least 1 weapon can be upgraded
                    local canUpgrade = false

                    for _, wep in ipairs(target:GetWeapons()) do
                        if TTTPAP:CanOrderPAP(wep) and WEPS.GetClass(wep) ~= "weapon_ttt_unarmed" then
                            canUpgrade = true
                            break
                        end
                    end

                    if not canUpgrade then
                        ready = false
                        text = "None of " .. target:Nick() .. "'s weapons can be upgraded"
                    else
                        text = "Press '" .. key .. "' to try to upgrade ALL of " .. target:Nick() .. "'s weapons"
                    end
                end
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["packapunch"] = ABILITY
    -- 
    -- Poison Headcrab
    -- 
    ABILITY = SOULBOUND.Abilities["poisonheadcrab"]
    ABILITY.Name = "Spawn Poison Headcrabs"
    ABILITY.Description = "*ONLY WORKS OUTSIDE*\nSpawn a poison headcrab launcher from the sky that slams into the ground, contaning 4 poison headcrabs"
    local poisonheadcrab_cooldown = GetConVar("ttt_soulbound_poisonheadcrab_cooldown")

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundPoisonHeadcrabUses", poison_headcrab_launcher_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundPoisonHeadcrabNextUse", CurTime())
    end

    -- This function is from the headcrab launcher weapon: https://steamcommunity.com/sharedfiles/filedetails/?id=911182038
    function ABILITY:CheckForSky(tr)
        local YawIncrement = 20
        local PitchIncrement = 10
        local aBaseAngle = tr.HitNormal:Angle()
        local aBasePos = tr.HitPos
        local bScanning = true
        local iPitch = 10
        local iYaw = -180
        local iLoopLimit = 0
        local iProcessedTotal = 0
        local tValidHits = {}

        while bScanning and iLoopLimit < 500 do
            iYaw = iYaw + YawIncrement
            iProcessedTotal = iProcessedTotal + 1

            if iYaw >= 180 then
                iYaw = -180
                iPitch = iPitch - PitchIncrement
            end

            local tLoop = util.QuickTrace(aBasePos, (aBaseAngle + Angle(iPitch, iYaw, 0)):Forward() * 40000)

            if tLoop.HitSky then
                table.insert(tValidHits, tLoop)
            end

            if iPitch <= -80 then
                bScanning = false
            end

            iLoopLimit = iLoopLimit + 1
        end

        return tValidHits, aBasePos
    end

    function ABILITY:Condition(soulbound, target)
        if not soulbound:IsInWorld() then return false end
        if poison_headcrab_launcher_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundPoisonHeadcrabUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundPoisonHeadcrabNextUse") then return false end
        local tValidHits = self:CheckForSky(soulbound:GetEyeTrace())

        if #tValidHits > 0 then
            return true
        else
            soulbound:SendLua("surface.PlaySound(\"WallHealth.Deny\")")
            soulbound:ChatPrint("Can't spawn, try outside")

            return false
        end
    end

    function ABILITY:Use(soulbound, target)
        local tValidHits, aBasePos = self:CheckForSky(soulbound:GetEyeTrace())
        local iHits = #tValidHits
        local iRand = math.random(3, iHits)
        local tRand = tValidHits[iRand]
        local rocket = ents.Create("env_headcrabcanister")
        rocket:SetPos(aBasePos)
        rocket:SetAngles((tRand.HitPos - tRand.StartPos):Angle())
        -- These numbers are from "big crab launcher" upgrade, the default damage convar values for that upgrade
        -- Direct damage from being hit by the headcrab launcher should never kill someone at full health
        -- Type 2 = poison headcrabs, ones from poison zombies
        rocket:SetKeyValue("HeadcrabType", 2)
        rocket:SetKeyValue("HeadcrabCount", 4)
        rocket:SetKeyValue("FlightSpeed", 2000)
        rocket:SetKeyValue("FlightTime", 2.5)
        rocket:SetKeyValue("Damage", 30)
        rocket:SetKeyValue("DamageRadius", 150)
        rocket:SetKeyValue("SmokeLifetime", 3)
        rocket:SetKeyValue("StartingHeight", 1000)
        rocket:SetCollisionGroup(COLLISION_GROUP_DEBRIS)
        rocket:SetKeyValue("spawnflags", 8192)
        rocket:Spawn()
        rocket:Input("FireCanister", soulbound, soulbound)
        local uses = soulbound:GetNWInt("TTTSoulboundPoisonHeadcrabUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundPoisonHeadcrabUses", uses)
        soulbound:SetNWFloat("TTTSoulboundPoisonHeadcrabNextUse", CurTime() + poisonheadcrab_cooldown:GetFloat())
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = poison_headcrab_launcher_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundPoisonHeadcrabUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text = "Press '" .. key .. "' to spawn a poison headcrab launcher"
            local next_use = soulbound:GetNWFloat("TTTSoulboundPoisonHeadcrabNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["poisonheadcrab"] = ABILITY
    -- 
    -- Poltergeist
    -- 
    ABILITY = SOULBOUND.Abilities["poltergeist"]
    ABILITY.Name = "Perma-Poltergeist"
    ABILITY.Description = "Shoot a poltergeist that stays on the prop forever"
    local poltergeist_cooldown = GetConVar("ttt_soulbound_poltergeist_cooldown")

    function ABILITY:Use(soulbound, target)
        local tr = soulbound:GetEyeTrace()
        local ang = soulbound:GetAimVector():Angle()
        ang:RotateAroundAxis(ang:Right(), 90)
        local ent = ents.Create("ttt_physhammer")
        ent:SetPos(tr.HitPos)
        ent:SetAngles(ang)
        ent:Spawn()
        ent:SetOwner(soulbound)
        local stuckEnt = tr.Entity
        local stuck = ent:StickTo(stuckEnt)

        if not stuck then
            ent:Remove()

            return
        end

        ent.TTTPAPSoulboundPoltergeistStuckEnt = stuckEnt
        ent:SetMaterial(TTTPAP.camo)
        local uses = soulbound:GetNWInt("TTTSoulboundPoltergeistUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundPoltergeistUses", uses)
        soulbound:SetNWFloat("TTTSoulboundPoltergeistNextUse", CurTime() + poltergeist_cooldown:GetFloat())
    end

    if SERVER then
        self:AddHook("EntityRemoved", function(ent)
            if IsValid(ent) and IsValid(ent.TTTPAPSoulboundPoltergeistStuckEnt) then
                local newEnt = ents.Create("ttt_physhammer")
                newEnt:SetPos(ent:GetPos())
                newEnt:SetAngles(ent:GetAngles())
                newEnt:Spawn()
                local owner = ent:GetOwner()

                if IsValid(owner) then
                    newEnt:SetOwner(owner)
                end

                local stuckEnt = ent.TTTPAPSoulboundPoltergeistStuckEnt
                local stuck = newEnt:StickTo(stuckEnt)

                if not stuck then
                    newEnt:Remove()

                    return
                end

                newEnt.TTTPAPSoulboundPoltergeistStuckEnt = stuckEnt
                newEnt:SetMaterial(TTTPAP.camo)
            end
        end)
    end

    SOULBOUND.Abilities["poltergeist"] = ABILITY
    -- 
    -- Possession
    -- 
    ABILITY = SOULBOUND.Abilities["possession"]
    ABILITY.Name = "Ultra Ghosting Possession"
    ABILITY.Description = "Stronger prop possession, messages you type in chat appear above props you possess"

    function ABILITY:Passive(soulbound, target)
        soulbound.propspec.punches = 1
        soulbound:SetNWFloat("specpunches", 1)
        soulbound:GetNWInt("bonuspunches", 0)
        soulbound.TTTPAPSoulboundPossession = true
    end

    if SERVER then
        self:AddHook("PlayerSay", function(sender, text, teamchat)
            -- ent:SetNWString() has a limit of up to 199 characters
            if sender.TTTPAPSoulboundPossession and string.len(text) < 200 then
                sender:SetNWString("TTTPAPSoulboundPossession", text)
                sender:SetNWEntity("TTTPAPSoulboundPossessionProp", sender.propspec.ent)
                local timerName = "TTTPAPSoulboundPossession" .. sender:SteamID64()

                -- Check the soulbound is still possessing something
                timer.Create(timerName, 0.1, 0, function()
                    if not IsValid(sender) or not sender.propspec or not IsValid(sender.propspec.ent) then
                        sender:SetNWString("TTTPAPSoulboundPossession", "")
                        timer.Remove(timerName)
                    end
                end)
            end
        end)
    end

    if CLIENT then
        local client

        self:AddHook("PostDrawTranslucentRenderables", function()
            if not client then
                client = LocalPlayer()
            end

            for _, ply in player.Iterator() do
                local message = ply:GetNWString("TTTPAPSoulboundPossession", "")
                local prop = ply:GetNWEntity("TTTPAPSoulboundPossessionProp")

                if message ~= "" and IsValid(prop) then
                    local _, boundTop = prop:GetModelRenderBounds()
                    local norm = ply:GetPos() - client:GetPos()
                    local ang = norm:Angle()
                    cam.Start3D2D(prop:GetPos() + Vector(0, 0, boundTop.z + 10), Angle(0, ang.y - 90, 90), 0.5)
                    surface.SetDrawColor(Color(0, 0, 0, 150))
                    surface.SetFont("TargetID")
                    local w, h = surface.GetTextSize(message)
                    local x, y = -w / 2, -h / 2
                    surface.DrawRect(x - 7, y, w + 7, h + 6)
                    draw.SimpleText(message, "TargetID", -4, 4, COLOR_YELLOW, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                    cam.End3D2D()
                end
            end
        end)
    end

    function ABILITY:Cleanup(soulbound)
        hook.Remove("KeyPress", "Soulbound_Possession_KeyPress_" .. soulbound:SteamID64())
        soulbound.TTTPAPSoulboundPossession = nil
        soulbound:SetNWString("TTTPAPSoulboundPossession", nil)
    end

    SOULBOUND.Abilities["possession"] = ABILITY
    -- 
    -- Reveal
    -- 
    ABILITY = SOULBOUND.Abilities["reveal"]
    ABILITY.Name = "Revealing Camera"
    ABILITY.Description = "Reveal the location of the player you are spectating,\nand show a mini-camera of their perspecitve on the top left of their screen to your fellow traitors"

    if SERVER then
        self:AddHook("PlayerPostThink", function(soulbound)
            if not soulbound:IsSoulbound() then return end
            if not soulbound:GetNWBool("TTTSoulboundRevealBought", false) then return end
            local target = soulbound:GetObserverMode() ~= OBS_MODE_ROAMING and soulbound:GetObserverTarget() or nil
            if not IsPlayer(target) or not target:Alive() or target:IsSpec() or target:IsTraitorTeam() then return end
            local oldTarget = soulbound:GetNWEntity("TTTPAPSoulboundRevealTarget")

            if not IsValid(oldTarget) or oldTarget ~= target then
                soulbound:SetNWEntity("TTTPAPSoulboundRevealTarget", target)
            end
        end)
    end

    if CLIENT then
        local client

        self:AddHook("HUDPaint", function()
            if not client then
                client = LocalPlayer()
            end

            if not client:IsTraitorTeam() or not client:Alive() or client:IsSpec() then return end
            local target
            local soulbound

            for _, ply in player.Iterator() do
                target = ply:GetNWEntity("TTTPAPSoulboundRevealTarget")
                soulbound = ply
                if IsValid(target) then break end
            end

            if not IsValid(target) then return end
            -- From the Remote Sticky Bomb's camera: https://steamcommunity.com/sharedfiles/filedetails/?id=550005969
            local CamData = {}
            CamData.angles = Angle(0, target:EyeAngles().yaw, 0)
            CamData.origin = target:GetPos() + Vector(0, 0, 100)
            CamData.x = 0
            CamData.y = 0
            CamData.w = ScrW() / 3
            CamData.h = ScrH() / 3
            render.RenderView(CamData)
            -- RSB code ends here
            draw.WordBox(8, 0, 0, target:Nick() .. " cam, from Soulbound: " .. soulbound:Nick(), "TargetID", Color(0, 0, 0, 180), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
        end)
    end

    SOULBOUND.Abilities["reveal"] = ABILITY
    -- 
    -- Smoke
    -- 
    ABILITY = SOULBOUND.Abilities["smoke"]
    ABILITY.Name = "Instant Smoke Grenade"
    ABILITY.Description = "Throw an upgraded smoke grenade, which makes a massive cloud of smoke"
    local smoke_cooldown = GetConVar("ttt_soulbound_smoke_cooldown")

    function ABILITY:Use(soulbound, target)
        local ang = soulbound:EyeAngles()
        local src = soulbound:GetPos() + (soulbound:Crouching() and soulbound:GetViewOffsetDucked() or soulbound:GetViewOffset()) + (ang:Forward() * 8) + (ang:Right() * 10)
        local pos = soulbound:GetEyeTraceNoCursor().HitPos
        local tang = (pos - src):Angle() -- A target angle to actually throw the grenade to the crosshair instead of fowards

        -- Makes the grenade go upwards
        if tang.p < 90 then
            tang.p = -10 + tang.p * ((90 + 10) / 90)
        else
            tang.p = 360 - tang.p
            tang.p = -10 + tang.p * -((90 + 10) / 90)
        end

        tang.p = math.Clamp(tang.p, -90, 90) -- Makes the grenade not go backwards :/
        local vel = math.min(800, (90 - tang.p) * 6)
        local thr = tang:Forward() * vel + soulbound:GetVelocity()
        local gren = ents.Create("ttt_pap_ninja_bomb_nade")
        if not IsValid(gren) then return end
        gren:SetPos(src)
        gren:SetAngles(Angle(0, 0, 0))
        gren:SetOwner(soulbound)
        gren:SetThrower(soulbound)
        gren:SetGravity(0.4)
        gren:SetFriction(0.2)
        gren:SetElasticity(0.45)
        gren:Spawn()
        gren:PhysWake()
        local phys = gren:GetPhysicsObject()

        if IsValid(phys) then
            phys:SetVelocity(thr)
            phys:AddAngleVelocity(Vector(600, math.random(-1200, 1200)), 0)
        end

        gren:SetDetonateExact(CurTime() + 3)
        local uses = soulbound:GetNWInt("TTTSoulboundSmokeUses", 0)
        uses = math.max(uses - 1, 0)
        soulbound:SetNWInt("TTTSoulboundSmokeUses", uses)
        soulbound:SetNWFloat("TTTSoulboundSmokeNextUse", CurTime() + smoke_cooldown:GetFloat())
    end

    SOULBOUND.Abilities["smoke"] = ABILITY
    -- 
    -- Swap Inventory
    -- 
    ABILITY = SOULBOUND.Abilities["swapinventory"]
    ABILITY.Name = "Swap Position"
    ABILITY.Description = "Swap the position of two different players"

    function ABILITY:Bought(soulbound)
        soulbound:SetNWInt("TTTSoulboundSwapInventoryUses", swap_position_uses:GetInt())
        soulbound:SetNWFloat("TTTSoulboundSwapInventoryNextUse", CurTime())
        soulbound:SetNWString("TTTSoulboundSwapInventoryTarget", "")
    end

    function ABILITY:Condition(soulbound, target)
        if swap_position_uses:GetInt() > 0 and soulbound:GetNWInt("TTTSoulboundSwapInventoryUses", 0) <= 0 then return false end
        if CurTime() < soulbound:GetNWFloat("TTTSoulboundSwapInventoryNextUse") then return false end
        if not target or not IsPlayer(target) then return false end

        return true
    end

    function ABILITY:Use(soulbound, target1)
        local t1sid64 = target1:SteamID64()
        local t2sid64 = soulbound:GetNWString("TTTSoulboundSwapInventoryTarget", "")

        if #t2sid64 == 0 then
            soulbound:SetNWString("TTTSoulboundSwapInventoryTarget", t1sid64)
        elseif t1sid64 ~= t2sid64 then
            local target2 = player.GetBySteamID64(t2sid64)

            if not target2 or not IsPlayer(target2) or not target2:Alive() or target2:IsSpec() then
                soulbound:SetNWString("TTTSoulboundSwapInventoryTarget", t1sid64)
            else
                local t1pos = target1:GetPos()
                target1:SetPos(target2:GetPos())
                target2:SetPos(t1pos)
                soulbound:SpectateEntity(target2)
                local uses = soulbound:GetNWInt("TTTSoulboundSwapInventoryUses", 0)
                uses = math.max(uses - 1, 0)
                soulbound:SetNWInt("TTTSoulboundSwapInventoryUses", uses)
                soulbound:SetNWFloat("TTTSoulboundSwapInventoryNextUse", CurTime() + swap_position_cooldown:GetFloat())
                soulbound:SetNWString("TTTSoulboundSwapInventoryTarget", "")
            end
        end
    end

    if CLIENT then
        local ammo_colors = {
            border = COLOR_WHITE,
            background = Color(100, 60, 0, 222),
            fill = Color(205, 155, 0, 255)
        }

        function ABILITY:DrawHUD(soulbound, x, y, width, height, key)
            local max_uses = swap_position_uses:GetInt()
            local uses = soulbound:GetNWInt("TTTSoulboundSwapInventoryUses", 0)
            local margin = 6
            local ammo_height = 28

            if max_uses == 0 then
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, 1)
                CRHUD:ShadowedText("Unlimited Uses", "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            else
                CRHUD:PaintBar(8, x + margin, y + margin, width - (margin * 2), ammo_height, ammo_colors, uses / max_uses)
                CRHUD:ShadowedText(tostring(uses) .. "/" .. tostring(max_uses), "HealthAmmo", x + (margin * 2), y + margin + (ammo_height / 2), COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            local ready = true
            local text
            local next_use = soulbound:GetNWFloat("TTTSoulboundSwapInventoryNextUse")
            local cur_time = CurTime()

            if max_uses > 0 and uses <= 0 then
                ready = false
                text = "Out of uses"
            elseif cur_time < next_use then
                ready = false
                local s = next_use - cur_time
                local ms = (s - math.floor(s)) * 100
                s = math.floor(s)
                text = "On cooldown for " .. string.format("%02i.%02i", s, ms) .. " seconds"
            else
                local target1 = soulbound:GetObserverMode() ~= OBS_MODE_ROAMING and soulbound:GetObserverTarget() or nil
                local t2sid64 = soulbound:GetNWString("TTTSoulboundSwapInventoryTarget", "")

                if not target1 or not IsPlayer(target1) then
                    ready = false
                    text = "Spectate a player"
                elseif #t2sid64 == 0 then
                    text = "Press '" .. key .. "' to choose " .. target1:Nick() .. " as your first target"
                else
                    local target2 = player.GetBySteamID64(t2sid64)

                    if not target2 or not IsPlayer(target2) or not target2:Alive() or target2:IsSpec() then
                        text = "Press '" .. key .. "' to choose " .. target1:Nick() .. " as your first target"
                    elseif target1 == target2 then
                        ready = false
                        text = "Spectate another player"
                    else
                        text = "Press '" .. key .. "' to swap " .. target1:Nick() .. " and " .. target2:Nick()
                    end
                end
            end

            draw.SimpleText(text, "TabLarge", x + margin, y + height - margin, COLOR_WHITE, TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM)

            return ready
        end
    end

    SOULBOUND.Abilities["swapinventory"] = ABILITY
end

function UPGRADE:Reset()
    -- Hopefully restore the Soulbound abilities to what they were
    -- (I've had problems with this in the past with the French randomat restoring old role names to English,
    -- but this is way less complicated than that so it will hopefully *just work*)
    if SOULBOUND.PAPOldAbilities then
        SOULBOUND.Abilities = table.Copy(SOULBOUND.PAPOldAbilities)
    end
end

TTTPAP:Register(UPGRADE)