local UPGRADE = {}
UPGRADE.id = "noir_quote_pistol"
UPGRADE.class = "weapon_ttt_revolver_randomat"
UPGRADE.name = "Noir Quote Pistol"
UPGRADE.desc = "Plays a random noir quote when reloading"

function UPGRADE:Apply(SWEP)
    function SWEP:PAPReshuffleNoirQuotes()
        self.PAPNoirQuoteOrder = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11}

        table.Shuffle(self.PAPNoirQuoteOrder)
        self.PAPNoirQuoteNumber = 1
    end

    SWEP:PAPReshuffleNoirQuotes()

    function SWEP:Reload()
        self.BaseClass.Reload(self)

        if self.PAPNoirQuoteNumber > #self.PAPNoirQuoteOrder then
            SWEP:PAPReshuffleNoirQuotes()
        end

        self:EmitSound("ttt_pack_a_punch/noir_quote_pistol/quote" .. SWEP.PAPNoirQuoteOrder[self.PAPNoirQuoteNumber] .. ".mp3")
        self.PAPNoirQuoteNumber = self.PAPNoirQuoteNumber + 1
    end
end

TTTPAP:Register(UPGRADE)