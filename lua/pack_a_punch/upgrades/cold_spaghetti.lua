local UPGRADE = {}
UPGRADE.id = "cold_spaghetti"
UPGRADE.class = "weapon_ttt_hotpotato"
UPGRADE.name = "Cold Spaghetti"
UPGRADE.noCamo = true
UPGRADE.noSelectWep = true

UPGRADE.convars = {
    {
        name = "pap_cold_spaghetti_radius",
        type = "int"
    },
    {
        name = "pap_cold_spaghetti_frozen_secs",
        type = "int"
    },
    {
        name = "pap_cold_spaghetti_music",
        type = "bool"
    }
}

local frozenSecsCvar = CreateConVar("pap_cold_spaghetti_frozen_secs", 20, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Seconds players are frozen", 0, 60)

local radiusCvar = CreateConVar("pap_cold_spaghetti_frozen_radius", 600, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Distance players are frozen", 0, 1000)

local musicCvar = CreateConVar("pap_cold_spaghetti_alt_music", 0, {FCVAR_NOTIFY, FCVAR_REPLICATED}, "Whether the cold spaghetti plays alternative music", 0, 1)

UPGRADE.desc = "Temporarily freezes players in addition to exploding,\ndoesn't affect you!"

function UPGRADE:Apply(SWEP)
    -- Initially setting spaghetti model
    local spaghettiModel = "models/ttt_pack_a_punch/spaghetti/spaghetti.mdl"
    SWEP.ViewModel = spaghettiModel
    SWEP.WorldModel = spaghettiModel
    SWEP.UseHands = false

    -- If this is not being passed to a player, turn on showing the upgrade description again for the new potato-upgrader player
    if not IsValid(SWEP.PAPOwner) then
        self.noDesc = false
    end

    local PAPOwner

    timer.Simple(0.1, function()
        PAPOwner = SWEP.PAPOwner or SWEP:GetOwner()

        if SERVER and IsValid(PAPOwner) then
            PAPOwner:SelectWeapon(self.class)
        end
    end)

    local PotatoSound = Sound("ttt_pack_a_punch/cold_spaghetti/cold_spaghetti.mp3")

    if musicCvar:GetBool() then
        PotatoSound = Sound("ttt_pack_a_punch/cold_spaghetti/gameshow.mp3")
    end

    local OldPotatoSound = "hotpotatoloop.wav"
    -- A global function from the hot potato SWEP file
    -- Hijack it to use it like a hook for removing the potato sound when it should be
    local old_fn_CleanUp = fn_CleanUp

    function fn_CleanUp(ply)
        if SERVER then
            ply:StopSound(PotatoSound)
        end

        return old_fn_CleanUp(ply)
    end

    SWEP.PAPOldDetonate = SWEP.Detonate
    local screenColour = Color(0, 238, 255, 20)
    local freezeColour = Color(0, 255, 255)

    function SWEP:Detonate(p)
        for _, ply in ipairs(ents.FindInSphere(self:GetPos(), radiusCvar:GetInt())) do
            if UPGRADE:IsAlivePlayer(ply) then
                -- Make the original owner of the cold spaghetti immune to the explosion
                if IsValid(PAPOwner) and ply == PAPOwner then
                    ply.PAPColdSpaghettiBlockExplosion = true

                    timer.Simple(1, function()
                        if IsValid(ply) then
                            ply.PAPColdSpaghettiBlockExplosion = false
                        end
                    end)
                else
                    -- Freeze all other players, after a delay to detect if a player has died from the potato, so don't show them the "You are frozen!" message
                    timer.Simple(0.1, function()
                        if not UPGRADE:IsAlive(ply) then return end
                        local freezeDuration = frozenSecsCvar:GetInt()
                        ply:Freeze(true)
                        ply:EmitSound("ttt_pack_a_punch/cold_spaghetti/freeze.mp3")
                        ply:ScreenFade(SCREENFADE.OUT, screenColour, 1, freezeDuration - 1)
                        ply:ChatPrint("Frozen for " .. freezeDuration .. " seconds!")
                        local oldPlayerColour = ply:GetColor()
                        ply:SetColor(freezeColour)

                        timer.Simple(freezeDuration + 0.1, function()
                            if IsValid(ply) then
                                ply:Freeze(false)
                                ply:SetColor(oldPlayerColour)
                            end
                        end)
                    end)
                end
            end
        end

        return self:PAPOldDetonate(p)
    end

    self:AddHook("EntityTakeDamage", function(ent, dmg)
        if not self:IsPlayer(ent) or not ent.PAPColdSpaghettiBlockExplosion then return end
        local inflictor = dmg:GetInflictor()
        if not IsValid(inflictor) then return end
        if inflictor:GetClass() == "env_explosion" then return true end
    end)

    SWEP.PAPOldPotatoTime = SWEP.PotatoTime

    function SWEP:PotatoTime(victim, PotatoChef)
        self:PAPOldPotatoTime(victim, PotatoChef)
        local potato = victim:GetWeapon(UPGRADE.class)

        -- No switching weapons with potato unless forced
        hook.Add("PlayerSwitchWeapon", victim:Name() .. "_DontSwitch", function(ply, oldWeapon, newWeapon)
            if ply == victim then
                -- Allow switch to holstered to refresh weapon model and name
                if IsValid(newWeapon) and newWeapon:GetClass() == "weapon_ttt_unarmed" and newWeapon.AllowHolstered then
                    return
                elseif IsValid(oldWeapon) then
                    -- if potato is still in inventory, dont switch
                    if oldWeapon == potato then return true end
                else -- in case of forced removal of potato, clean up
                    victim:StopSound(PotatoSound)
                    fn_CleanUp(ply)
                end
            end
        end)

        -- No picking up new weapons while potato active, except for holstered for weapon model and name refresh
        hook.Add("PlayerCanPickupWeapon", victim:Name() .. "_NoNewWeapon", function(ply, wep)
            if ply == victim then
                if IsValid(wep) and wep:GetClass() == "weapon_ttt_unarmed" then
                    return true
                else
                    return false
                end
            end
        end)

        local owner = self:GetOwner()

        if IsValid(owner) then
            owner:StopSound(PotatoSound)

            timer.Simple(0.1, function()
                owner:StopSound(PotatoSound)
            end)
        end

        if IsValid(potato) then
            victim:EmitSound(PotatoSound)
            victim:StopSound(OldPotatoSound)
            local holstered = victim:Give("weapon_ttt_unarmed")
            holstered.AllowHolstered = true
            victim:SelectWeapon("weapon_ttt_unarmed")

            timer.Simple(0.1, function()
                victim:SelectWeapon(UPGRADE.class)
                holstered.AllowHolstered = false
                victim:StopSound(OldPotatoSound)
                holstered:Remove()
            end)

            potato.PAPOwner = PAPOwner
            UPGRADE.noDesc = true
            TTTPAP:ApplyUpgrade(potato, UPGRADE)
        end
    end

    -- Spaghetti model
    if CLIENT then
        -- Adjust these variables to move the viewmodel's position
        SWEP.IronSightsPos = Vector(15.49, 20, -30.371)
        SWEP.IronSightsAng = Vector(12, 65, -20.19)

        function SWEP:GetViewModelPosition(EyePos, EyeAng)
            SWEP.ViewModel = spaghettiModel
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

        local WorldModel = ClientsideModel(spaghettiModel)
        -- Settings...
        WorldModel:SetSkin(1)
        WorldModel:SetNoDraw(true)

        function SWEP:DrawWorldModel()
            local _Owner = self:GetOwner()

            if IsValid(_Owner) then
                -- Specify a good position
                local offsetVec = Vector(0, 0, 0)
                local offsetAng = Angle(180, 0, 0)
                local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand") -- Right Hand
                if not boneid then return end
                local matrix = _Owner:GetBoneMatrix(boneid)
                if not matrix then return end
                local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())
                WorldModel:SetPos(newPos)
                WorldModel:SetAngles(newAng)
                WorldModel:SetupBones()
            else
                WorldModel:SetPos(self:GetPos())
                WorldModel:SetAngles(self:GetAngles())
            end

            WorldModel:DrawModel()
        end
    end
end

function UPGRADE:Reset()
    if CLIENT then return end

    for _, ply in ipairs(player.GetAll()) do
        ply:Freeze(false)
        ply.PAPColdSpaghettiBlockExplosion = nil
    end
end

TTTPAP:Register(UPGRADE)