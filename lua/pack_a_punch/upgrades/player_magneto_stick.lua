-- All credit for this code goes to Malivil and Noxx from the 2022 Jingle Jam roles pack: https://github.com/NoxxFlame/TTT-Jingle-Jam-Roles-2022
-- (I just modified it to work like an upgraded magneto-stick, and use the Pack-a-Punch's UPGRADE object system)
local UPGRADE = {}
UPGRADE.id = "player_magneto_stick"
UPGRADE.class = "weapon_zm_carry"
UPGRADE.name = "Player Magneto-stick"
UPGRADE.desc = "A magneto-stick that exclusively picks up players!"
UPGRADE.automatic = false

UPGRADE.convars = {
    {
        name = "pap_player_magneto_stick_release_delay",
        type = "int"
    },
    {
        name = "pap_player_magneto_stick_carry_duration",
        type = "int"
    },
    {
        name = "pap_player_magneto_stick_struggle_interval",
        type = "float"
    },
    {
        name = "pap_player_magneto_stick_struggle_reduce",
        type = "float"
    },
    {
        name = "pap_player_magneto_stick_cooldown",
        type = "int"
    },
    {
        name = "pap_player_magneto_stick_multi_pickup",
        type = "bool"
    }
}

CreateConVar("pap_player_magneto_stick_release_delay", "2", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds a victim is stunned", 0, 60)

CreateConVar("pap_player_magneto_stick_carry_duration", "30", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds someone can be carried for", 0, 60)

CreateConVar("pap_player_magneto_stick_struggle_interval", "0.25", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds between struggles", 0.1, 1)

CreateConVar("pap_player_magneto_stick_struggle_reduce", "0.5", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds a struggle reduces carry", 0.1, 5)

CreateConVar("pap_player_magneto_stick_cooldown", "10", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Second cooldown between picking up", 0, 180)

CreateConVar("pap_player_magneto_stick_multi_pickup", "0", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Players can be picked up more than once a round", 0, 1)

function UPGRADE:Apply(SWEP)
    local CurTime = CurTime
    local ents = ents
    local ipairs = ipairs
    local IsValid = IsValid
    local math = math
    local table = table
    local timer = timer
    local util = util
    local EntsFindAlongRay = ents.FindAlongRay
    local MathClamp = math.Clamp
    local MathRandom = math.random
    local MathAbs = math.abs
    local TableInsert = table.insert
    local TraceLine = util.TraceLine
    local sound_single = Sound("Weapon_Crowbar.Single")
    SWEP.Secondary.Delay = 1

    if SERVER then
        -- Don't let the held player pickup weapons
        self:AddHook("PlayerCanPickupWeapon", function(ply, _)
            if ply == SWEP.Victim then return false end
        end, SWEP:EntIndex())

        -- Prevent fall damage while being carried
        self:AddHook("EntityTakeDamage", function(ent, dmginfo)
            if IsPlayer(ent) and ent == SWEP.Victim and dmginfo:IsFallDamage() then return true end
        end, SWEP:EntIndex())
    end

    SWEP.BaseClass.Initialize(SWEP)

    if SERVER then
        function SWEP:Think()
            self.BaseClass.Think(self)
            if self.Victim == nil then return end

            -- If the player we're holding left or is dead then reset the weapon
            if not IsValid(self.Victim) or not self.Victim:Alive() or self.Victim:IsSpec() then
                self:Reset()

                return
            end

            self:UpdateVictimPosition()
        end
    end

    function SWEP:UpdateVictimPosition()
        if CLIENT then return end
        if not IsValid(self.Victim) then return end
        local owner = self:GetOwner()
        self.Victim:SetPos(owner:LocalToWorld(Vector(35, 0, 0)))
        self.Victim:SetEyeAngles(owner:GetAngles())
        self.Victim:SetMoveType(MOVETYPE_NOCLIP)
    end

    function SWEP:Reset()
        local owner = self:GetOwner()
        local ply = self.Victim
        local plyProps = self.VictimProps
        -- Reset the properties early so the "PlayerCanPickupWeapon" hook is disabled
        self.Victim = nil
        self.VictimProps = nil
        if CLIENT or not IsValid(ply) then return end
        ply:SetNWBool("PAP_magnetoCarryVictim", false)
        ply:SetSolid(plyProps.Solid)
        ply:SetMoveType(MOVETYPE_WALK)

        -- If this Reset is becauses they died, just drop them
        if ply:Alive() and not ply:IsSpec() then
            -- Move the player up a little bit to make sure they don't get stuck in the ground
            local newPos = owner:LocalToWorld(Vector(75, 0, 5))
            -- Prevent player from getting stuck in the world
            local found = false
            local attempts = 0

            while true and attempts < 10 do
                attempts = attempts + 1

                local tr = TraceLine({
                    start = newPos,
                    endpos = newPos
                })

                if tr.Hit then
                    newPos.z = newPos.z + 10
                else
                    found = true
                    break
                end
            end

            -- Prevent player from getting stuck in other players
            attempts = 0

            while true and attempts < 10 do
                attempts = attempts + 1
                local foundEnts = EntsFindAlongRay(newPos, newPos)

                if #foundEnts > 1 then
                    newPos.z = newPos.z + 10
                else
                    found = true
                    break
                end
            end

            -- If we failed to find a suitable place, just put them literally in the owner
            -- The players can figure out what to do from there
            if not found then
                newPos = owner:GetPos()
            end

            ply:SetPos(newPos)

            -- Give the player's weapons back
            for _, data in ipairs(plyProps.Weapons) do
                local wep = ply:Give(data.class)
                wep:SetClip1(data.clip1)
                wep:SetClip2(data.clip2)
            end
        end

        -- Unlock the owner's view as well
        net.Start("PAP_magnetoCarryEnd")
        net.WriteUInt(self:EntIndex(), 16)
        net.Send(owner)
        -- Unlock player movement and camera and hide struggle UI
        net.Start("PAP_magnetoVictimCarryEnd")
        net.WriteUInt(self:EntIndex(), 16)
        net.WriteUInt(GetConVar("pap_player_magneto_stick_release_delay"):GetInt(), 8)
        net.Send(ply)
    end

    function SWEP:Pickup(ent)
        if IsValid(self.Victim) then return end
        if not IsValid(ent) then return end

        if ent.PaPMagnetostickPickedUpBefore and not GetConVar("pap_player_magneto_stick_multi_pickup"):GetBool() then
            self:GetOwner():PrintMessage(HUD_PRINTCENTER, "This player has been picked up before!")

            return
        end

        ent.PaPMagnetostickPickedUpBefore = true

        if ent.PaPMagnetostickCooldown then
            self:GetOwner():PrintMessage(HUD_PRINTCENTER, "This player was picked up too recently!")

            return
        else
            ent.PaPMagnetostickCooldown = true

            timer.Simple(GetConVar("pap_player_magneto_stick_cooldown"):GetInt(), function()
                if IsValid(ent) then
                    ent.PaPMagnetostickCooldown = false
                end
            end)
        end

        self.Victim = ent
        if CLIENT then return end
        self.Victim:SetNWBool("PAP_magnetoCarryVictim", true)

        self.VictimProps = {
            Solid = self.Victim:GetSolid(),
            Weapons = {}
        }

        self.Victim:SetSolid(SOLID_NONE)

        for _, weap in ipairs(self.Victim:GetWeapons()) do
            TableInsert(self.VictimProps.Weapons, {
                class = weap:GetClass(),
                clip1 = weap:Clip1(),
                clip2 = weap:Clip2()
            })
        end

        self.Victim:StripWeapons()
        self:UpdateVictimPosition()
        -- Lock the owner's camera a bit too so things are less janky
        net.Start("PAP_magnetoCarryStart")
        net.WriteUInt(self:EntIndex(), 16)
        net.Send(self:GetOwner())
        -- Lock player movement and camera on the client to reduce jerkiness
        -- Also show UI for the held player to struggle
        net.Start("PAP_magnetoVictimCarryStart")
        net.WriteUInt(self:EntIndex(), 16)
        net.WriteUInt(GetConVar("pap_player_magneto_stick_carry_duration"):GetInt(), 8)
        net.WriteFloat(GetConVar("pap_player_magneto_stick_struggle_interval"):GetFloat())
        net.WriteFloat(GetConVar("pap_player_magneto_stick_struggle_reduction"):GetFloat())
        net.Send(self.Victim)
    end

    function SWEP:PrimaryAttack()
    end

    function SWEP:SecondaryAttack()
        self:SendWeaponAnim(ACT_VM_MISSCENTER)
        self:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)

        if IsValid(self.Victim) then
            self:Reset()

            return
        end

        local owner = self:GetOwner()
        if not IsValid(owner) then return end

        -- for some reason not always true
        if owner.LagCompensation then
            owner:LagCompensation(true)
        end

        local spos = owner:GetShootPos()
        local sdest = spos + owner:GetAimVector() * 70
        local kmins = Vector(1, 1, 1) * -10
        local kmaxs = Vector(1, 1, 1) * 10

        local tr_main = util.TraceHull({
            start = spos,
            endpos = sdest,
            filter = owner,
            mask = MASK_SHOT_HULL,
            mins = kmins,
            maxs = kmaxs
        })

        local hitEnt = tr_main.Entity
        self:EmitSound(sound_single)

        if not IsPlayer(hitEnt) or tr_main.HitWorld then
            if owner.LagCompensation then
                owner:LagCompensation(false)
            end

            return
        end

        self:Pickup(hitEnt)

        if owner.LagCompensation then
            owner:LagCompensation(false)
        end
    end

    function SWEP:OnDrop()
        self:Remove()
    end

    function SWEP:Deploy()
        self:Reset()
        local vm = self:GetOwner():GetViewModel()
        vm:SendViewModelMatchingSequence(vm:LookupSequence("fists_draw"))

        return true
    end

    function SWEP:OnRemove()
        self:Reset()
    end

    function SWEP:Holster()
        self:Reset()

        return true
    end

    function SWEP:ShouldDropOnDie()
        return false
    end

    if SERVER then
        util.AddNetworkString("PAP_magnetoCarryStart")
        util.AddNetworkString("PAP_magnetoCarryEnd")
        util.AddNetworkString("PAP_magnetoVictimCarryStart")
        util.AddNetworkString("PAP_magnetoVictimCarryEnd")
        util.AddNetworkString("PAP_magnetoVictimStruggle")
        resource.AddSingleFile("sound/ttt_pack_a_punch/player_magneto_stick/struggle1.mp3")
        resource.AddSingleFile("sound/ttt_pack_a_punch/player_magneto_stick/struggle2.mp3")
        resource.AddSingleFile("sound/ttt_pack_a_punch/player_magneto_stick/struggle3.mp3")

        local struggle_sounds = {Sound("ttt_pack_a_punch/player_magneto_stick/struggle1.mp3"), Sound("ttt_pack_a_punch/player_magneto_stick/struggle2.mp3"), Sound("ttt_pack_a_punch/player_magneto_stick/struggle3.mp3")}

        net.Receive("PAP_magnetoVictimCarryEnd", function(_, ply)
            local entIdx = net.ReadUInt(16)
            local wep = Entity(entIdx)
            if not IsValid(wep) or not wep:IsWeapon() then return end
            if wep.Victim ~= ply then return end
            wep:Reset()
        end)

        net.Receive("PAP_magnetoVictimStruggle", function(_, ply)
            if not IsPlayer(ply) or not ply:Alive() or ply:IsSpec() then return end
            local idx = MathRandom(1, #struggle_sounds)
            local chosen_sound = struggle_sounds[idx]
            sound.Play(chosen_sound, ply:GetPos())
        end)
    end

    if CLIENT then
        -- Owner
        net.Receive("PAP_magnetoCarryStart", function()
            local client = LocalPlayer()
            local entIdx = net.ReadUInt(16)

            self:AddHook("InputMouseApply", function(cmd, x, y, ang)
                if not client:Alive() or client:IsSpec() then return end
                -- Lock view from going too high up or down
                ang.pitch = MathClamp(ang.pitch, -35, 35)
                -- Apply the mouse movement to the values and then set the camera angles
                ang.pitch = ang.pitch + y / 50
                ang.yaw = ang.yaw - x / 50
                cmd:SetViewAngles(ang)

                return true
            end, entIdx)
        end)

        net.Receive("PAP_magnetoCarryEnd", function()
            local entIdx = net.ReadUInt(16)
            self:RemoveHook("InputMouseApply", entIdx)
        end)

        -- Victim
        surface.CreateFont("PAP_magnetoEscape", {
            font = "Trebuchet24",
            size = 18,
            weight = 600
        })

        net.Receive("PAP_magnetoVictimCarryStart", function()
            local client = LocalPlayer()
            local entIdx = net.ReadUInt(16)
            local carryDuration = net.ReadUInt(8)
            local struggleInterval = net.ReadFloat()
            local struggleReduction = net.ReadFloat()
            local pap_magnetoWeapon = Entity(entIdx)
            local pap_magneto = pap_magnetoWeapon:GetOwner()

            self:AddHook("StartCommand", function(ply, cmd)
                if ply ~= client then return end
                if not client:Alive() or client:IsSpec() then return end
                -- Stop them from moving and attacking
                cmd:SetForwardMove(0)
                cmd:SetSideMove(0)
                cmd:RemoveKey(IN_JUMP)
                cmd:RemoveKey(IN_DUCK)
                cmd:RemoveKey(IN_ATTACK)
                cmd:RemoveKey(IN_ATTACK2)
            end, entIdx)

            self:AddHook("InputMouseApply", function(cmd, _, _, ang)
                if not client:Alive() or client:IsSpec() then return end

                -- If we're being held by the owner, lock our view in the center but facing the same direction as owner
                -- If they aren't being held then the mouse is basically just disabled, preventing them from moving their camera
                -- This lock takes effect in the delay after the victim is dropped by the owner
                if client:GetNWBool("PAP_magnetoCarryVictim", false) then
                    local currentYaw = client:EyeAngles().yaw
                    local targetYaw = pap_magneto:EyeAngles().yaw
                    local speedMult = 0.001
                    local minSpeed = 0.001
                    local dir = currentYaw < targetYaw and 1 or -1
                    local difference = MathAbs(currentYaw - targetYaw)

                    if difference > 180 then
                        dir = dir * -1
                        difference = 360 - difference
                    end

                    local change = difference * speedMult

                    if change < minSpeed then
                        change = minSpeed
                    end

                    currentYaw = currentYaw + change * dir

                    -- Yaw ranges from -180 to 180
                    if currentYaw > 180 then
                        currentYaw = currentYaw - 360
                    elseif currentYaw < -180 then
                        currentYaw = currentYaw + 360
                    end

                    ang.pitch = 0
                    ang.yaw = currentYaw
                    cmd:SetViewAngles(ang)
                end

                return true
            end, entIdx)

            -- If duration is not set then this hold is indefinite
            if carryDuration <= 0 then return end
            -- Show the struggle UI
            local startTime = CurTime()
            local endTime = startTime + carryDuration
            local margin = 10
            local width, height = 200, 25
            local x = ScrW() / 2 - width / 2
            local y = margin / 2 + height

            local colors = {
                background = Color(30, 60, 100, 222),
                fill = Color(75, 150, 255, 255)
            }

            self:AddHook("HUDPaint", function()
                if not client:Alive() or client:IsSpec() then return end
                -- Don't use carryDuration or the changes to the endTime for the struggle won't reflect accurately
                local percentage = (CurTime() - startTime) / (endTime - startTime)

                -- If the percentage has hit 100 then release the player
                if percentage >= 1 then
                    net.Start("PAP_magnetoVictimCarryEnd")
                    net.WriteUInt(entIdx, 16)
                    net.SendToServer()
                    self:RemoveHook("HUDPaint", entIdx)

                    return
                end

                CRHUD:PaintBar(8, x, y, width, height, colors, percentage)

                draw.TextShadow({
                    text = "Someone has a hold of you!",
                    font = "PAP_magnetoEscape",
                    pos = {ScrW() / 2, y - height + 3},
                    color = COLOR_WHITE,
                    xalign = TEXT_ALIGN_CENTER
                }, 1, 255)

                draw.SimpleText("ESCAPE PROGRESS", "PAP_magnetoEscape", ScrW() / 2, y + 3, COLOR_WHITE, TEXT_ALIGN_CENTER)

                draw.TextShadow({
                    text = "Press " .. Key("+forward", "W") .. " repeatedly to struggle",
                    font = "PAP_magnetoEscape",
                    pos = {ScrW() / 2, y + height + 3},
                    color = COLOR_WHITE,
                    xalign = TEXT_ALIGN_CENTER
                }, 1, 255)
            end, entIdx)

            -- Increase progress every time they press the struggle button
            local nextStruggle = 0

            self:AddHook("KeyPress", function(ply, key)
                if ply ~= client then return end
                if not client:Alive() or client:IsSpec() then return end
                if key ~= IN_FORWARD then return end

                if CurTime() > nextStruggle then
                    nextStruggle = CurTime() + struggleInterval
                    endTime = endTime - struggleReduction
                    net.Start("PAP_magnetoVictimStruggle")
                    net.SendToServer()
                end
            end, entIdx)
        end)

        net.Receive("PAP_magnetoVictimCarryEnd", function()
            local entIdx = net.ReadUInt(16)
            local delay = net.ReadUInt(8)

            local function End()
                self:RemoveHook("StartCommand", entIdx)
                self:RemoveHook("InputMouseApply", entIdx)
            end

            -- End the effect after the given delay, if there is one
            if delay > 0 then
                timer.Simple(delay, End)
            else
                End()
            end

            self:RemoveHook("HUDPaint", entIdx)
            self:RemoveHook("KeyPress", entIdx)
        end)
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PaPMagnetostickCooldown = nil
        ply.PaPMagnetostickPickedUpBefore = nil
    end
end

TTTPAP:Register(UPGRADE)