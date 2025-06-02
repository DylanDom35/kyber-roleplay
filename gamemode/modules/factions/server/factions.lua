KYBER.Factions = {}

KYBER.Factions["jedi"] = {
    name = "Jedi Order",
    color = Color(100, 150, 255),
    description = "Peacekeepers of the Galactic Republic.",
    canUseForce = true,
    ranks = {"Youngling", "Padawan", "Knight", "Master", "Council"},
}

KYBER.Factions["sith"] = {
    name = "Sith Cult",
    color = Color(200, 50, 50),
    description = "Followers of the dark side.",
    canUseForce = true,
    ranks = {"Acolyte", "Apprentice", "Warrior", "Darth", "Overlord"},
}

KYBER.Factions["imperial"] = {
    name = "Imperial Remnant",
    color = Color(180, 180, 180),
    description = "The last echo of the Empire.",
    canUseForce = false,
    ranks = {"Stormtrooper", "Sergeant", "Commander", "Moff"},
}

KYBER.Factions["bounty"] = {
    name = "Bounty Guild",
    color = Color(255, 200, 0),
    description = "Mercenaries for hire, loyal to coin.",
    canUseForce = false,
    ranks = {"Hunter", "Elite", "Guildmaster"},
}
