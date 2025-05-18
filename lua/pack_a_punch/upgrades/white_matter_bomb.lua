local UPGRADE = {}
UPGRADE.id = "white_matter_bomb"
UPGRADE.class = "weapon_ttt_rmgrenade"
UPGRADE.name = "White Matter Bomb"
UPGRADE.desc = "Pushes players and damages those in range instead"
UPGRADE.noCamo = true

function UPGRADE:Apply(SWEP)
    function SWEP:GetGrenadeName()
        return "ttt_pap_wmgrenade_proj"
    end

    if CLIENT and not SWEP.PAPOldDrawWorldModel then
        SWEP.PAPOldDrawWorldModel = SWEP.DrawWorldModel

        function SWEP:DrawWorldModel()
            self:PAPOldDrawWorldModel()

            if IsValid(self.ModelEntity) then
                self.ModelEntity:SetPAPCamo()
            end
        end
    end

    if CLIENT and not SWEP.PAPOldViewModelDrawn then
        SWEP.PAPOldViewModelDrawn = SWEP.ViewModelDrawn

        function SWEP:ViewModelDrawn()
            self:PAPOldViewModelDrawn()

            if IsValid(self.ModelEntity) then
                self.ModelEntity:SetPAPCamo()
            end
        end
    end
end

TTTPAP:Register(UPGRADE)