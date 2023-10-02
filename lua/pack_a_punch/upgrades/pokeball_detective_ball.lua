local UPGRADE = {}
UPGRADE.id = "pokeball_detective_ball"
UPGRADE.class = "weapon_ttt_detectiveball"
UPGRADE.name = "Pokeball"
UPGRADE.desc = "Works with non-vanilla roles on catching and releasing a player!"

if ConVarExists("pap_pokeball_min_catch_chance") and GetConVar("pap_pokeball_min_catch_chance"):GetInt() < 100 then
    UPGRADE.desc = "Works with non-vanilla roles on catching and releasing a player!\nThe chance to catch them increases if they aren't at full health"
end

UPGRADE.noCamo = true
UPGRADE.noSound = true
UPGRADE.noSelectWep = true

-- Created in the ttt_pap_pokeball entity lua file
UPGRADE.convars = {
    {
        name = "pap_pokeball_throw_strength",
        type = "int"
    },
    {
        name = "pap_pokeball_throw_distance",
        type = "int"
    },
    {
        name = "pap_pokeball_min_catch_chance",
        type = "int"
    },
    {
        name = "pap_pokeball_auto_release_secs",
        type = "int"
    },
    {
        name = "pap_pokeball_auto_remove_secs",
        type = "int"
    },
    {
        name = "pap_pokeball_allow_self_capture",
        type = "bool"
    }
}

function UPGRADE:Apply(SWEP)
    SWEP.Primary.Sound = Sound("ttt_pack_a_punch/pokeball/throw.mp3")
    SWEP.ViewModel = Model("models/ttt_pack_a_punch/pokeball/pokeball.mdl")
    SWEP.WorldModel = Model("models/ttt_pack_a_punch/pokeball/pokeball.mdl")
    SWEP.AllowDrop = true
    SWEP.ModelScale = 0.5

    if SERVER then
        local owner = SWEP:GetOwner()
        SWEP.Thrower = owner

        timer.Simple(0.1, function()
            if IsValid(owner) then
                owner:SelectWeapon(self.class)
            end
        end)

        -- Set via the pokeball entity
        -- Continues the auto-release countdown for the captured player after the ball gets picked up
        if SWEP.AutoReleaseSecsLeft then
            local timername = "TTTPAPPokeballAutoRelease" .. SWEP:EntIndex()
            local caughtPly = SWEP.CaughtPly

            timer.Create(timername, 1, SWEP.AutoReleaseSecsLeft, function()
                if not IsValid(SWEP) or not IsValid(caughtPly) then
                    timer.Remove(timername)
                else
                    caughtPly:PrintMessage(HUD_PRINTCENTER, "Seconds until auto release: " .. timer.RepsLeft(timername))

                    if timer.RepsLeft(timername) == 0 then
                        -- A function set via the pokeball entity
                        SWEP:ReleasePlayer(false)
                        SWEP:SetPlayerNoCollide(owner, caughtPly)
                    end
                end
            end)
        end
    end

    -- Prevents the pokeball owner and captured player from becoming stuck on each other
    function SWEP:SetPlayerNoCollide(ply1, ply2)
        if not IsValid(ply1) or not IsValid(ply2) then return end
        ply2.PAPPokeballNoCollide = true
        ply1.PAPPokeballNoCollide = true
        ply2:SetCustomCollisionCheck(true)
        ply1:SetCustomCollisionCheck(true)

        -- Players have 10 seconds to move out of the way of each other
        timer.Simple(10, function()
            if not IsValid(ply1) or not IsValid(ply2) then return end
            ply2.PAPPokeballNoCollide = nil
            ply1.PAPPokeballNoCollide = nil
        end)
    end

    -- If players are about to be stuck because a player took too long to throw a pokeball, make them not collide with each other
    hook.Add("ShouldCollide", "TTTPAPPokeballCollide", function(ent1, ent2)
        if not IsValid(ent1) or not IsValid(ent2) then return end
        if ent1.PAPPokeballNoCollide or ent2.PAPPokeballNoCollide then return false end
    end)

    -- If the pokeball is removed for whatever reason, the pokeball is not being thrown, and there is a player inside, release them
    function SWEP:OnRemove()
        if self.ThrowRemove or not self.ReleasePlayer or not IsValid(self.Thrower) or not IsValid(self.CaughtPly) then return end
        self:ReleasePlayer(true, true)
        self:SetPlayerNoCollide(self.Thrower, self.CaughtPly)
    end

    -- Update the owner and set the captured player to spectate the pokeball if the owner dies or otherwise drops the pokeball
    function SWEP:OwnerChanged()
        self.Thrower = self:GetOwner()
        if not IsValid(self.CaughtPly) then return end

        if IsValid(self.Thrower) then
            self.CaughtPly:SpectateEntity(self.Thrower)
        else
            self.CaughtPly:SpectateEntity(self)
        end
    end

    function SWEP:SecondaryAttack()
    end

    function SWEP:PrimaryAttack()
        self:EmitSound(self.Primary.Sound)
        if CLIENT then return end
        local owner = self:GetOwner()
        if not IsValid(owner) then return end
        local pokeball = ents.Create("ttt_pap_pokeball")
        if not IsValid(pokeball) then return end
        pokeball.Thrower = self:GetOwner()
        -- Role-setting function defined below
        pokeball.OnSuccess = self.OnSuccess
        -- Set via the pokeball entity
        pokeball.CaughtPly = self.CaughtPly
        pokeball.PAPUpgrade = UPGRADE
        pokeball:Spawn()
        self.ThrowRemove = true
        self:Remove()
    end

    -- Extra function for instantly converting a player into a detective
    -- Somewhat similar to the detective ball, but very heavily modified
    function SWEP:OnSuccess(ply)
        if not IsValid(ply) or not ply:IsPlayer() or not ply:Alive() or ply:IsSpec() then return end
        local detectiveCount = 0

        for _, p in ipairs(player.GetAll()) do
            if p:Alive() and not p:IsSpec() and (DETECTIVE_ROLES and DETECTIVE_ROLES[p:GetRole()] or p:GetRole() == ROLE_DETECTIVE) then
                detectiveCount = detectiveCount + 1
            end
        end

        if DETECTIVE_ROLES and DETECTIVE_ROLES[ply:GetRole()] or ply:GetRole() == ROLE_DETECTIVE then
            -- Detective
            ply:SetHealth(100)
            ply:PrintMessage(HUD_PRINTCENTER, "You are healed!")
            ply:PrintMessage(HUD_PRINTTALK, "You are healed!")

            if IsValid(self.Thrower) then
                self.Thrower:PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " was healed!")
                self.Thrower:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " was healed!")
            end
        elseif ply.IsTraitorTeam and ply:IsTraitorTeam() or ply:GetRole() == ROLE_TRAITOR then
            -- Traitor
            ply:PrintMessage(HUD_PRINTCENTER, "You have been revealed!")
            ply:PrintMessage(HUD_PRINTTALK, "You have been revealed!")

            if IsValid(self.Thrower) then
                self.Thrower:PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " is a traitor!")
                self.Thrower:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is a traitor!")
            end
        elseif ply.IsInnocentTeam and ply:IsInnocentTeam() or ply:GetRole() == ROLE_INNOCENT then
            -- Innocent
            if detectiveCount <= 1 then
                ply:SetRole(ROLE_DETECTIVE)
                ply:SetHealth(100)
                SendFullStateUpdate()
                ply:PrintMessage(HUD_PRINTCENTER, "You are now a detective!")
                ply:PrintMessage(HUD_PRINTTALK, "You are now a detective!")

                if IsValid(self.Thrower) then
                    self.Thrower:PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " is now a detective!")
                    self.Thrower:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is now a detective!")
                end
            else
                ply:SetHealth(100)
                ply:PrintMessage(HUD_PRINTCENTER, "Too many detectives, you are healed!")
                ply:PrintMessage(HUD_PRINTTALK, "Too many detectives, you are healed!")

                if IsValid(self.Thrower) then
                    self.Thrower:PrintMessage(HUD_PRINTCENTER, "Too many detectives, " .. ply:Nick() .. " was healed!")
                    self.Thrower:PrintMessage(HUD_PRINTTALK, "Too many detectives, " .. ply:Nick() .. " was healed!")
                end
            end
        elseif IsValid(self.Thrower) then
            -- Jester/Independent
            ply:PrintMessage(HUD_PRINTCENTER, "You are are suspicious to " .. self.Thrower:Nick() .. "...")
            ply:PrintMessage(HUD_PRINTTALK, "You are are suspicious to " .. self.Thrower:Nick() .. "...")
            self.Thrower:PrintMessage(HUD_PRINTCENTER, ply:Nick() .. " is neither innocent nor traitor...")
            self.Thrower:PrintMessage(HUD_PRINTTALK, ply:Nick() .. " is neither innocent nor traitor...")
        end
    end

    if CLIENT then
        -- Adjust these variables to move the viewmodel's position
        SWEP.IronSightsPos = Vector(25.49, 0, -30.371)
        SWEP.IronSightsAng = Vector(12, 65, -20.19)

        function SWEP:GetViewModelPosition(EyePos, EyeAng)
            local Mul = 1.0
            local Offset = self.IronSightsPos

            if self.IronSightsAng then
                EyeAng = EyeAng * 1
                EyeAng:RotateAroundAxis(EyeAng:Right(), self.IronSightsAng.x * Mul)
                EyeAng:RotateAroundAxis(EyeAng:Up(), self.IronSightsAng.y * Mul)
                EyeAng:RotateAroundAxis(EyeAng:Forward(), self.IronSightsAng.z * Mul)
            end

            local Right = EyeAng:Right()
            local Up = EyeAng:Up()
            local Forward = EyeAng:Forward()
            EyePos = EyePos + Offset.x * Right * Mul
            EyePos = EyePos + Offset.y * Forward * Mul
            EyePos = EyePos + Offset.z * Up * Mul

            return EyePos, EyeAng
        end

        local WorldModel = ClientsideModel(SWEP.WorldModel)
        -- Settings...
        WorldModel:SetSkin(1)
        WorldModel:SetNoDraw(true)

        function SWEP:DrawWorldModel()
            local _Owner = self:GetOwner()

            if IsValid(_Owner) then
                -- Specify a good position
                local offsetVec = Vector(5, -2.7, -3.4)
                local offsetAng = Angle(180, -90, 0)
                local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
                if not boneid then return end
                local matrix = _Owner:GetBoneMatrix(boneid)
                if not matrix then return end
                local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
                WorldModel:SetPos(newPos)
                WorldModel:SetAngles(newAng)

                -- Set the pokeball to be smaller in a player's hands
                if IsValid(self.Thrower) then
                    WorldModel:SetModelScale(self.ModelScale)
                else
                    WorldModel:SetModelScale(1)
                end

                WorldModel:SetupBones()
            else
                WorldModel:SetPos(self:GetPos())
                WorldModel:SetAngles(self:GetAngles())
            end

            WorldModel:DrawModel()
        end
    end
end

TTTPAP:Register(UPGRADE)