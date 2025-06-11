# Kyber Roleplay Framework

A semi-serious Star Wars roleplay gamemode for Garry's Mod focused on deep character immersion, emergent faction systems, and modular design.

## Features

### Core Systems
- **Deep Character System** - Persistent character data, reputation, and progression
- **Faction Dynamics** - 8 built-in factions with custom ranks and relationships
- **Force Lottery System** - Fair chance-based Force sensitivity assignment
- **Equipment & Crafting** - Complex gear system with stats and crafting recipes
- **Banking & Economy** - Multi-tiered banking with faction treasuries
- **Medical System** - Injury tracking, bacta tanks, and clone revival
- **Reputation System** - Faction standing affects prices, access, and gameplay
- **Galaxy Travel** - Cross-server travel and local teleportation
- **Communications** - Holocalls, faction broadcasts, news system

### Built-in Factions
- Galactic Republic
- Imperial Remnant  
- Rebel Alliance
- Jedi Order
- Sith Order
- Mandalorian Clans
- Bounty Hunters Guild  
- Hutt Cartel

### Key Features
- **Modular Design** - Easy to add/remove systems
- **Persistent Data** - Character progression saves across sessions  
- **Immersive UI** - Diegetic interfaces (datapads, terminals)
- **Emergent Gameplay** - Player-driven stories and faction conflicts
- **Legendary Characters** - Whitelist system for canon characters

## Installation

2. Rename the folder to `kyber` if needed

3. Select "Kyber Roleplay" from the gamemode list in your server

## Quick Start

### For Players
- Press **F4** to open your datapad
- Use **I** to open inventory
- Use **C** to open equipment
- Type `/help` for available commands

### For Server Owners
- Configure factions in `shared.lua`
- Set up cross-server travel IPs in galaxy system
- Configure economic balance in each module

## Module Structure

```
gamemode/
├── modules/           # Core gameplay systems
│   ├── banking/      # Banking and storage
│   ├── crafting/     # Item creation system  
│   ├── economy/      # Grand Exchange trading
│   ├── equipment/    # Gear and stats system
│   ├── factions/     # Faction management
│   ├── force/        # Force lottery system
│   ├── galaxy/       # Travel system
│   ├── inventory/    # Item management
│   ├── medical/      # Health and injury system
│   └── reputation/   # Faction standing
└── entities/         # Custom entities
    ├── kyber_bacta_tank/
    ├── kyber_banking_terminal/
    └── kyber_crafting_station/
```

## Configuration

Most systems can be configured by modifying the `Config` tables in each module. Key settings include:

- **Economy**: Item prices, trading fees
- **Medical**: Injury rates, bacta costs  
- **Force**: Lottery timing and chances
- **Banking**: Interest rates, storage limits
- **Reputation**: Faction relationships

## Development

### Adding New Systems
1. Create module folder in `gamemode/modules/`
2. Follow server/client split structure
3. Add to load order in `init.lua`
4. Use hook system for integration

### Contributing
1. Fork the repository
2. Create feature branch
3. Follow existing code style
4. Test thoroughly before submitting PR

## Support

- **Issues**: Use GitHub issue tracker
- **Documentation**: Check module comments
- **Discord**: [[Your Discord Server]](https://discord.gg/wmXgN6t9RU)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Credits

- **Framework**: Kyber Development Team
- **Inspiration**: SWTOR, MovieBattles II
- **Community**: Our amazing roleplay community G-Realms

---

*May the Force be with you, always.*
