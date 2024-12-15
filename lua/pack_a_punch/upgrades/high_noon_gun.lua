local UPGRADE = {}
UPGRADE.id = "high_noon_gun"
UPGRADE.class = "weapon_ttt_revolver"
UPGRADE.name = "High-noon gun"
UPGRADE.desc = "Infinite ammo... but you need to duel!\nDRAW!"

function UPGRADE:Apply(SWEP)
    function SWEP:Think()
        if self:Clip1() < 1 then
            self:SetClip1(1)
        end
    end

    -- Fix being able to shoot a player that walks into a lead shot by the high noon gun
    self:AddHook("EntityTakeDamage", function(target, dmg)
        if not IsPlayer(target) then return end
        local attacker = dmg:GetAttacker()
        if not IsPlayer(attacker) then return end
        local inflictor = attacker:GetActiveWeapon()
        if not IsValid(inflictor) then return end

        if inflictor:GetClass() == "weapon_zm_improvised" then
            local duelAttacker = target:GetNWEntity("TTTPAPHighNoonGunDuellingPlayer")
            local duelTarget = attacker:GetNWEntity("TTTPAPHighNoonGunDuellingPlayer")
            attacker:PrintMessage(HUD_PRINTCENTER, "Can't crowbar duelling players!")
            if IsPlayer(duelAttacker) or IsPlayer(duelTarget) then return true end
        elseif inflictor:GetClass() == "weapon_ttt_revolver" then
            local duelAttacker = target:GetNWEntity("TTTPAPHighNoonGunDuellingPlayer")
            local duelTarget = attacker:GetNWEntity("TTTPAPHighNoonGunDuellingPlayer")
            if not (IsPlayer(duelAttacker) and IsPlayer(duelTarget) and attacker == duelAttacker and target == duelTarget) then return true end
            -- Play a bullet ricochet sound for everyone when someone is shot by the high noon gun
            BroadcastLua("surface.PlaySound(\"ttt_pack_a_punch/high_noon_gun/ricochet" .. math.random(6) .. ".mp3\")")
        end
    end)

    -- Stop a duel if a player dies in the middle of it
    self:AddHook("PostPlayerDeath", function(deadPly)
        deadPly:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", NULL)
        deadPly.DuelOpponent = nil

        for _, ply in player.Iterator() do
            if IsPlayer(ply:GetNWEntity("TTTPAPHighNoonGunDuellingPlayer")) and ply:GetNWEntity("TTTPAPHighNoonGunDuellingPlayer") == deadPly then
                ply:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", NULL)
                ply.DuelOpponent = nil
            end
        end

        -- Remove the duel halo when a player dies
        net.Start("TTTPAPHighNoonGunRemoveHalo")
        net.Send(deadPly)
    end)

    -- Force players to holster if the have the holstered weapon, and they are frozen, being about to duel
    if SERVER then
        self:AddHook("PlayerPostThink", function(ply)
            if ply:IsFrozen() and ply:HasWeapon("weapon_ttt_unarmed") then
                ply:SelectWeapon("weapon_ttt_unarmed")
            end
        end)
    end

    -- Draws halos over the duelling players
    if SERVER then
        util.AddNetworkString("TTTPAPHighNoonGunDrawHalo")
        util.AddNetworkString("TTTPAPHighNoonGunRemoveHalo")
    end

    if CLIENT then
        net.Receive("TTTPAPHighNoonGunDrawHalo", function()
            -- Searching for the duel opponent based on their Steam ID
            local duelOpponent = {}
            local opponentName = net.ReadString()

            for _, ply in player.Iterator() do
                if ply:Nick() == opponentName then
                    table.insert(duelOpponent, ply)
                end
            end

            -- Adding a halo around the duel opponent
            hook.Add("PreDrawHalos", "TTTPAPHighNoonGunHalo", function()
                halo.Add(duelOpponent, Color(0, 255, 0), 0, 0, 1, true, false)

                -- Once the player dies, remove the halo!
                if (not IsPlayer(duelOpponent[1])) or (not duelOpponent[1]:Alive()) or duelOpponent[1]:IsSpec() then
                    hook.Remove("PreDrawHalos", "TTTPAPHighNoonGunHalo")
                end
            end)

            -- Plays the "Draw!" sound effect
            surface.PlaySound("ttt_pack_a_punch/high_noon_gun/draw.mp3")
        end)

        net.Receive("TTTPAPHighNoonGunRemoveHalo", function()
            hook.Remove("PreDrawHalos", "TTTPAPHighNoonGunHalo")
        end)
    end

    function SWEP:Equip()
        local owner = self:GetOwner()
        if not IsPlayer(owner) then return end
        -- Reset everyone's duelling player
        owner:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", NULL)
        owner.DuelOpponent = nil
        net.Start("TTTPAPHighNoonGunRemoveHalo")
        net.Send(owner)
    end

    function SWEP:PrimaryAttack()
        if not IsFirstTimePredicted() then return end
        local owner = self:GetOwner()
        if not IsPlayer(owner) then return end

        -- Refill a player's ammo so the revolver can shoot forever
        if SERVER and self:Ammo1() < 69 then
            owner:SetAmmo(69, self.Primary.Ammo)
        end

        -- Get the player the user is looking at
        local target = owner:GetEyeTrace().Entity

        -- Don't let duelling players shoot anyone else
        if owner.DuelOpponent and SERVER and IsPlayer(target) and target ~= owner.DuelOpponent then
            owner:PrintMessage(HUD_PRINTCENTER, "Not your duel opponent!")

            return
        elseif not owner.DuelOpponent and SERVER and IsPlayer(target) and target.DuelOpponent then
            -- If shooting someone who is duelling with another player, display a message
            -- and prevent the duel-starting logic from running
            owner:PrintMessage(HUD_PRINTCENTER, "Already duelling!")

            return
        elseif (not IsPlayer(target)) or (IsPlayer(target) and owner.DuelOpponent and owner.DuelOpponent == target) then
            -- Try removing the player duel halo immediately after someone wins a duel, else the halo looks awkward on a spectator
            -- The rest of the "end the duel" logic is handled by the "TTTPAPHighNoonGunDuelTimer" timer below
            timer.Simple(0.1, function()
                if IsPlayer(target) and (target:IsSpec() or not target:Alive()) then
                    hook.Remove("PreDrawHalos", "TTTPAPHighNoonGunHalo")
                    -- If hitting the player's target, or not shooting a player, trigger the usual gunshot behaviour
                end
            end)

            return self.BaseClass.PrimaryAttack(self)
        end

        if SERVER then
            if not IsPlayer(target) then return end
            -- Setting the flag for each player to be duelling
            owner:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", target)
            target:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", owner)
            owner.DuelOpponent = target
            target.DuelOpponent = owner
            -- Force the two players to look away from each other and freeze in place
            local ownerEyeAngles = owner:EyeAngles()
            owner:SetEyeAngles(Angle(ownerEyeAngles.x, ownerEyeAngles.y + 180, ownerEyeAngles.z))
            target:SetEyeAngles(ownerEyeAngles)
            owner:Freeze(true)
            target:Freeze(true)
            -- Play the high noon sound effect for the duelling players
            owner:SendLua("surface.PlaySound(\"ttt_pack_a_punch/high_noon_gun/duelquote" .. math.random(8) .. ".mp3\")")
            target:SendLua("surface.PlaySound(\"ttt_pack_a_punch/high_noon_gun/duelquote" .. math.random(8) .. ".mp3\")")
            local timerID = "TTTPAPHighNoonGun" .. owner:SteamID64()

            timer.Create(timerID, 1, 5, function()
                if timer.RepsLeft(timerID) == 0 then
                    -- After the countdown, unfreezes players and displays a message
                    owner:PrintMessage(HUD_PRINTCENTER, "DRAW!")
                    target:PrintMessage(HUD_PRINTCENTER, "DRAW!")
                    owner:Freeze(false)
                    target:Freeze(false)
                    owner:SelectWeapon("weapon_ttt_revolver")
                    target:SelectWeapon("weapon_ttt_revolver")
                    -- Also draws halos around their duel opponent and plays a sound for both players
                    net.Start("TTTPAPHighNoonGunDrawHalo")
                    net.WriteString(target:Nick())
                    net.Send(owner)
                    net.Start("TTTPAPHighNoonGunDrawHalo")
                    net.WriteString(owner:Nick())
                    net.Send(target)

                    -- Timer for checking the result of the duel
                    timer.Create("TTTPAPHighNoonGunDuelTimer" .. owner:SteamID64(), 1, 10, function()
                        -- If either player dies, end the duel
                        if IsPlayer(owner) and IsPlayer(target) and (not owner:Alive() or not target:Alive() or owner:IsSpec() or target:IsSpec()) then
                            owner:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", NULL)
                            target:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", NULL)
                            owner.DuelOpponent = nil
                            target.DuelOpponent = nil
                            net.Start("TTTPAPHighNoonGunRemoveHalo")

                            net.Send({owner, target})

                            timer.Remove("TTTPAPHighNoonGunDuelTimer" .. owner:SteamID64())

                            return
                        end

                        -- If the duel is still going after 5 seconds left, display a timer
                        local repsLeft = timer.RepsLeft("TTTPAPHighNoonGunDuelTimer" .. owner:SteamID64())

                        if repsLeft < 5 and repsLeft > 0 then
                            owner:PrintMessage(HUD_PRINTCENTER, repsLeft)
                            target:PrintMessage(HUD_PRINTCENTER, repsLeft)
                            -- After 10 seconds of duelling, end the duel
                        elseif repsLeft == 0 then
                            owner:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", NULL)
                            target:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", NULL)
                            owner.DuelOpponent = nil
                            target.DuelOpponent = nil
                            net.Start("TTTPAPHighNoonGunRemoveHalo")

                            net.Send({owner, target})

                            owner:PrintMessage(HUD_PRINTCENTER, "The duel is over!")
                            target:PrintMessage(HUD_PRINTCENTER, "The duel is over!")
                        end
                    end)
                else
                    -- Shows a message until the duel starts
                    owner:PrintMessage(HUD_PRINTCENTER, "Get ready to turn around and duel")
                    target:PrintMessage(HUD_PRINTCENTER, "Get ready to turn around and duel")
                end
            end)
        end
    end

    function SWEP:OnRemove()
        local owner = self:GetOwner()
        if not IsPlayer(owner) then return end
        -- Reset everyone's duelling player
        owner:SetNWEntity("TTTPAPHighNoonGunDuellingPlayer", NULL)
        owner.DuelOpponent = nil

        if SERVER then
            net.Start("TTTPAPHighNoonGunRemoveHalo")
            net.Send(owner)
        end
    end
end

TTTPAP:Register(UPGRADE)