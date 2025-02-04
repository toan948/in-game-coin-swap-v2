module owner_addr::mint_coins {
  use std::signer;
  use aptos_framework::managed_coin;

  // Basic resources
  struct Minerals {}
  struct EnergyCrystals {}
  struct Gasolineium {}
  struct OrganicBiomass {}

  // Advanced resources
  struct PlasmaCores {}
  struct NeutroniumAlloy {}
  struct DarkMatterResidue {}

  // Crafted resources
  struct RefinedPlasmoid {}     
  struct Hypersteel {}          
  struct BioluminescentFiber {}

  fun init_module(owner: &signer) {
    managed_coin::initialize<Minerals>(
      owner,
      b"Minerals",
      b"MNS",
      8,
      true,
    );

    managed_coin::initialize<EnergyCrystals>(
      owner,
      b"Energy Crystals",
      b"ECRY",
      8,
      true,
    );
    
    managed_coin::initialize<Gasolineium>(
      owner,
      b"Gasolineium",
      b"GSM",
      8,
      true,
    );

    managed_coin::initialize<OrganicBiomass>(
      owner,
      b"Organic Biomass",
      b"OCMS",
      8,
      true,
    );

    managed_coin::initialize<PlasmaCores>(
      owner,
      b"Plasma Cores",
      b"PLCR",
      8,
      true,
    );

    managed_coin::initialize<NeutroniumAlloy>(
      owner,
      b"Neutronium Alloy",
      b"NTAY",
      8,
      true,
    );

    managed_coin::initialize<DarkMatterResidue>(
      owner,
      b"Dark Matter Residue",
      b"DMR",
      8,
      true,
    );

    managed_coin::initialize<RefinedPlasmoid>(
      owner,
      b"Refined Plasmoid",
      b"RPD",
      8,
      true,
    );
    managed_coin::initialize<Hypersteel>(
      owner,
      b"Hypersteel",
      b"HYSL",
      8,
      true,
    );
    managed_coin::initialize<BioluminescentFiber>(
      owner,
      b"Bioluminescent Fiber",
      b"BMF",
      8,
      true,
    );

    managed_coin::register<Minerals>(owner);
    managed_coin::register<EnergyCrystals>(owner);
    managed_coin::register<Gasolineium>(owner);
    managed_coin::register<OrganicBiomass>(owner);
    managed_coin::register<PlasmaCores>(owner);
    managed_coin::register<NeutroniumAlloy>(owner);
    managed_coin::register<DarkMatterResidue>(owner);
    managed_coin::register<RefinedPlasmoid>(owner);
    managed_coin::register<Hypersteel>(owner);
    managed_coin::register<BioluminescentFiber>(owner);

    let owner_addr = signer::address_of(owner);

    managed_coin::mint<Minerals>(owner, owner_addr, 10000000000000);
    managed_coin::mint<EnergyCrystals>(owner, owner_addr, 10000000000000);
    managed_coin::mint<Gasolineium>(owner, owner_addr, 10000000000000);
    managed_coin::mint<OrganicBiomass>(owner, owner_addr, 10000000000000);
    managed_coin::mint<PlasmaCores>(owner, owner_addr, 1000000000000);
    managed_coin::mint<NeutroniumAlloy>(owner, owner_addr, 1000000000000);
    managed_coin::mint<DarkMatterResidue>(owner, owner_addr, 1000000000000);
    managed_coin::mint<RefinedPlasmoid>(owner, owner_addr, 100000000000);
    managed_coin::mint<Hypersteel>(owner, owner_addr, 100000000000);
    managed_coin::mint<BioluminescentFiber>(owner, owner_addr, 100000000000);
  }
}