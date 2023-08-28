AddCSLuaFile()
ENT.Base = "ttt_cup_arrow"
ENT.PrintName = "PaP Cupid's Arrow"
ENT.Type = "anim"

local StickSound = {"cupid/impact_arrow_stick_1.wav", "cupid/impact_arrow_stick_2.wav", "cupid/impact_arrow_stick_3.wav"}

local FleshSound = {"cupid/impact_arrow_flesh_1.wav", "cupid/impact_arrow_flesh_2.wav", "cupid/impact_arrow_flesh_3.wav", "cupid/impact_arrow_flesh_4.wav"}

local CollisionIgnoreClasses = {"trigger_*"}

local function ShouldIgnoreCollision(ent)
    for _, c in ipairs(CollisionIgnoreClasses) do
        if string.gmatch(ent:GetClass(), c) then return true end
    end

    return false
end

function ENT:Touch(ent)
    local owner = self:GetOwner()
    if not IsValid(owner) then return end
    local tr = self:GetTouchTrace()
    local tr2

    if tr.Hit then
        self:FireBullets({
            Damage = 0,
            Attacker = owner,
            Inflictor = self.Weapon,
            Callback = function(_, trace, _)
                tr2 = trace
            end,
            Force = 0,
            Tracer = 0,
            Src = tr.StartPos,
            Dir = tr.Normal,
            AmmoType = "huntingbow_arrows"
        })
    end

    if ent and ent:IsWorld() then
        sound.Play(table.Random(StickSound), tr.HitPos)
        self:SetMoveType(MOVETYPE_NONE)
        self:PhysicsInit(SOLID_NONE)
        SafeRemoveEntityDelayed(self, 10)

        return
    end

    if not IsValid(ent) then return end

    if ent:IsNPC() or ent:IsPlayer() then
        if tr2.Entity == ent then
            sound.Play(table.Random(FleshSound), tr.HitPos)
        end

        if ent:IsPlayer() and ent:IsActive() then
            if ent == owner then
                owner:QueueMessage(MSG_PRINTCENTER, "You cannot make yourself fall in love with someone.")
            else
                local target1 = owner:GetNWString("TTTCupidTarget1", "")
                local target2 = owner:GetNWString("TTTCupidTarget2", "")

                if target1 == "" then
                    ent:SetNWString("TTTCupidShooter", owner:SteamID64())
                    owner:SetNWString("TTTCupidTarget1", ent:SteamID64())
                    owner:QueueMessage(MSG_PRINTBOTH, ent:Nick() .. " has been hit with your first arrow.")
                    ent:QueueMessage(MSG_PRINTBOTH, "You have been hit by cupid's arrow!")
                elseif target2 == "" then
                    if ent:SteamID64() == target1 then
                        owner:QueueMessage(MSG_PRINTCENTER, "You cannot make someone fall in love with themselves.")
                    else
                        ent:SetNWString("TTTCupidShooter", owner:SteamID64())
                        owner:SetNWString("TTTCupidTarget2", ent:SteamID64())
                        owner:QueueMessage(MSG_PRINTBOTH, ent:Nick() .. " has been hit with your second arrow.")
                        ent:QueueMessage(MSG_PRINTBOTH, "You have been hit by cupid's arrow!")
                    end
                elseif owner:GetNWString("TTTCupidTarget3", "") == "" then
                    if ent:SteamID64() == target1 or ent:SteamID64() == target2 then
                        owner:QueueMessage(MSG_PRINTCENTER, "You cannot make someone fall in love with themselves.")
                    else
                        local ent2 = player.GetBySteamID64(target1)
                        local ent3 = player.GetBySteamID64(target2)
                        ent:SetNWString("TTTCupidShooter", owner:SteamID64())
                        owner:SetNWString("TTTCupidTarget3", ent3:SteamID64())
                        ent:QueueMessage(MSG_PRINTBOTH, "You have fallen in love with " .. ent2:Nick() .. " and " .. ent3:Nick() .. "!")
                        ent2:QueueMessage(MSG_PRINTBOTH, "You have fallen in love with " .. ent2:Nick() .. " and " .. ent3:Nick() .. "!")
                        owner:QueueMessage(MSG_PRINTBOTH, "You have created a love triangle between " .. ent:Nick() .. ", " .. ent2:Nick() .. " and " .. ent3:Nick() .. "!")
                        ent:SetNWString("TTTCupidLover", target1)
                        ent2:SetNWString("TTTCupidLover", ent:SteamID64())
                        ent3:SetNWString("TTTCupidLover", ent2:SteamID64())
                        owner:StripWeapon("weapon_cup_bow")
                        net.Start("TTT_CupidPaired")
                        net.WriteString(owner:Nick())
                        net.WriteString(ent:Nick())
                        net.WriteString(ent2:Nick())
                        net.WriteString(owner:SteamID64())
                        net.Broadcast()

                        -- You need to place successive net messages in a timer, else Gmod will complain about restarting a net message already sent...
                        timer.Simple(0, function()
                            net.Start("TTT_CupidPaired")
                            net.WriteString(owner:Nick())
                            net.WriteString(ent2:Nick())
                            net.WriteString(ent3:Nick())
                            net.WriteString(owner:SteamID64())
                            net.Broadcast()
                        end)

                        local mode = GetConVar("ttt_cupid_lovers_notify_mode"):GetInt()

                        if mode ~= ANNOUNCE_REVEAL_NONE then
                            for _, v in pairs(player.GetAll()) do
                                if v == ent or v == ent2 or v == owner then continue end

                                if mode == ANNOUNCE_REVEAL_ALL or v:IsTraitorTeam() and mode == ANNOUNCE_REVEAL_TRAITORS or v:IsInnocentTeam() and mode == ANNOUNCE_REVEAL_INNOCENTS then
                                    v:QueueMessage(MSG_PRINTBOTH, ROLE_STRINGS_EXT[ROLE_CUPID] .. " has made three players fall in love!")
                                end
                            end
                        end
                    end
                end
            end
        end

        self:Remove()
    elseif not ShouldIgnoreCollision(ent) then
        self:SetParent(ent)
        sound.Play(table.Random(StickSound), tr.HitPos)
        self:SetMoveType(MOVETYPE_NONE)
        self:SetSolid(SOLID_NONE)
        SafeRemoveEntityDelayed(self, 10)
    end
end