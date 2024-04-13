local UPGRADE = {}
UPGRADE.id = "player_trapper"
UPGRADE.class = "tfa_jetgun"
UPGRADE.name = "Player Trapper"
UPGRADE.desc = "Sucks in players and kills after 30 seconds\nAvoids triggering many on death effects!"

function UPGRADE:Apply(SWEP)
    -- Is a CoD weapon, so has its own PAP function we can take advantage of, this is not from this mod
    SWEP:OnPaP()
    SWEP.PAPPlayerTrapperCapturedPlayers = {}

    -- Setting the damage type to slash so that players take damage from the jet gun if they are a jester
    self:AddHook("EntityTakeDamage", function(ply, dmg)
        if not self:IsAlivePlayer(ply) then return end
        if ply.PAPPlayerTrapperTrapped then return true end
        local jetgun = dmg:GetInflictor()
        if not IsValid(jetgun) or WEPS.GetClass(jetgun) ~= self.class then return end

        if self:IsUpgraded(jetgun) then
            local owner = jetgun:GetOwner()
            ply:Spectate(OBS_MODE_CHASE)
            ply:SpectateEntity(jetgun)
            ply:DrawViewModel(false)
            ply:DrawWorldModel(false)
            ply:StripWeapons()
            ply:ChatPrint("If not freed, you will die in 30 seconds!")

            if IsValid(owner) then
                ply:SpectateEntity(owner)

                for i = 1, 5 do
                    owner:EmitSound("ttt_pack_a_punch/player_trapper/pop.mp3")
                end
            end

            table.insert(jetgun.PAPPlayerTrapperCapturedPlayers, ply)
            ply.PAPPlayerTrapperTrapped = true

            timer.Simple(30, function()
                if not IsValid(jetgun) or not IsValid(ply) then return end
                ply:UnSpectate()
                ply:DrawViewModel(true)
                ply:DrawWorldModel(true)

                if self:IsAlive(ply) then
                    ply:Kill()
                end

                table.RemoveByValue(jetgun.PAPPlayerTrapperCapturedPlayers, ply)
                owner = jetgun:GetOwner()

                if IsValid(owner) then
                    for i = 1, 5 do
                        owner:EmitSound("ttt_pack_a_punch/player_trapper/pop.mp3")
                    end
                end

                timer.Simple(1, function()
                    if not IsValid(ply) then return end
                    ply.PAPPlayerTrapperTrapped = false
                end)
            end)

            return true
        end
    end)

    self:AddHook("PlayerCanPickupWeapon", function(ply)
        if ply.PAPPlayerTrapperTrapped then return false end
    end)

    self:AddHook("TTTOnCorpseCreated", function(rag, ply)
        if ply.PAPPlayerTrapperTrapped then
            timer.Simple(0.1, function()
                rag:Remove()
            end)
        end
    end)

    -- Make players spectate the weapon if dropped
    function SWEP:OwnerChanged()
        local owner = self:GetOwner()

        if IsValid(owner) then
            for _, ply in ipairs(self.PAPPlayerTrapperCapturedPlayers) do
                ply:SpectateEntity(owner)
            end
        else
            for _, ply in ipairs(self.PAPPlayerTrapperCapturedPlayers) do
                ply:SpectateEntity(self)
            end
        end
    end

    SWEP.PAPOldOnRemove = SWEP.OnRemove

    function SWEP:OnRemove()
        self:PAPOldOnRemove()

        for _, ply in ipairs(self.PAPPlayerTrapperCapturedPlayers) do
            if not UPGRADE:IsAlive(ply) then continue end
            ply:UnSpectate()
            ply:DrawViewModel(true)
            ply:DrawWorldModel(true)
            ply:Spawn()
            ply.PAPPlayerTrapperTrapped = false
        end
    end
end

function UPGRADE:Reset()
    for _, ply in ipairs(player.GetAll()) do
        ply.PAPPlayerTrapperTrapped = nil
    end
end

TTTPAP:Register(UPGRADE)