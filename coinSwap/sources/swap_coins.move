module owner_addr::swap_coins {
  use std::string::{ Self, String };
  use std::vector;

  use aptos_std::signer;
  use aptos_std::type_info::{ Self, TypeInfo };
  use aptos_std::simple_map::{ Self, SimpleMap };
  use aptos_std::string_utils;
  
  use aptos_framework::account;
  use aptos_framework::coin;
  use aptos_framework::resource_account;
  use aptos_framework::timestamp;
  use aptos_framework::event::{ Self, EventHandle };

  const ENO_ENOUGH_COINS_1:u64 = 1;
  const ENO_ENOUGH_COINS_2:u64 = 2;
  const ENO_COINTYPE1_COIN_STORE: u64 = 3;
  const ENO_COINTYPE2_COIN_STORE: u64 = 4;
  const ENO_MINIMAL_COIN_1_BALANCE: u64 = 6;
  const ENO_MINIMAL_COIN_2_BALANCE: u64 = 7;
  const EMISSING_MODULE_DATA: u64 = 8;
  const ENO_PAIR_INFO: u64 = 9;
  const EMISSMATCH_COIN_TYPE1: u64 = 10;
  const EMISSMATCH_COIN_TYPE2: u64 = 11;
  const ESWAP_ISNOT_ACTIVE: u64 = 12;
  const E_INSUFFICIENT_COIN_AMOUNT: u64 = 13;
  const E_INSUFFICIENT_COIN_BALANCE: u64 = 14;
  const EINVALID_COIN_Y_AMOUNT: u64 = 15;
  const EINVALID_EXCHANGE_RATE: u64 = 16;
  const ENO_PERMISSION_TO_REMOVE_PAIR: u64 = 17;
  const ENOT_ENOUGH_COINS_IN_RESERVES: u64 = 18;
  const EINVALID_COIN_TYPE: u64 = 19;

  struct PairCreatedEvent has drop, store {
    meta: PairMeta,
  }

  struct PairRemovedEvent has drop, store {
    meta: PairMeta,
  }

  struct SwapEvent has drop, store {
    coins_from_name: vector<String>,
    coins_to_name: vector<String>,
    coins_from_amount: vector<u64>,
    coins_to_amount: vector<u64>,
    exchange_rates: vector<u64>,
    timestamp: u64,
  }

  struct Events has key {
    pair_created_event: EventHandle<PairCreatedEvent>,
    pair_removed_event: EventHandle<PairRemovedEvent>,
    swap_event: EventHandle<SwapEvent>,
  }

  struct PairMeta has copy, drop, store {
    coins_from: vector<TypeInfo>,
    coins_to: vector<TypeInfo>,
    coins_from_name: vector<String>,
    coins_to_name: vector<String>,
    coins_from_reserves: vector<u64>,
    coins_to_reserves: vector<u64>,
    exchange_rates: vector<u64>,
    creator: address,
  }

  struct PairInfo has key {
    // unique Trading Pair Seed, PairMeta
    pair_meta_map: SimpleMap<String, PairMeta>,
  }

  struct AdminData has key {
    signer_cap: account::SignerCapability,
  }

  // save signer cap to AdminData and save on resource_signer and init empty PairInfo, Events
  fun init_module(resource_signer: &signer) {
    let resource_signer_cap = resource_account::retrieve_resource_account_cap(resource_signer, @source_addr);

    move_to(resource_signer, AdminData {
      signer_cap: resource_signer_cap,
    });

    move_to(resource_signer, PairInfo {
      pair_meta_map: simple_map::create()
    });

    move_to(resource_signer, Events {
      pair_created_event: account::new_event_handle<PairCreatedEvent>(resource_signer),
      pair_removed_event: account::new_event_handle<PairRemovedEvent>(resource_signer),
      swap_event: account::new_event_handle<SwapEvent>(resource_signer),
    });
  }

  // helper functions
  fun register_coin<CoinType>(account: &signer) {
    let account_addr = signer::address_of(account);
    if (!coin::is_account_registered<CoinType>(account_addr)) {
      coin::register<CoinType>(account);
    };
  }

  fun get_resource_signer():signer  acquires AdminData {
    let admin_data = borrow_global<AdminData>(@owner_addr);
    account::create_signer_with_capability(&admin_data.signer_cap)
  } 

  public entry fun remove_pair<Coin_a, Coin_b>(creator: &signer, pair_id: String) acquires AdminData, PairInfo, Events {
    let creator_addr = signer::address_of(creator);
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);

    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);

    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta = simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);

    assert!(pair_meta.creator == creator_addr, ENO_PERMISSION_TO_REMOVE_PAIR);

    // withdraw all reserves coin to creator of pair
    coin::transfer<Coin_a>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_from_reserves, 0));
    coin::transfer<Coin_b>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_to_reserves, 0));
    
    let events = borrow_global_mut<Events>(resource_signer_address);

    // trigger remove pair event
    event::emit_event(
      &mut events.pair_removed_event,
      PairRemovedEvent {
        meta: *pair_meta,
      },
    );

    // remove PairMeta from PairInfo map
    simple_map::remove(&mut pair_info_data.pair_meta_map, &pair_id);
  }
  
  public entry fun remove_triple_pair<Coin_a, Coin_b, Coin_c>(creator: &signer, pair_id: String) acquires AdminData, PairInfo, Events {
    let creator_addr = signer::address_of(creator);
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);

    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);

    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta = simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);

    assert!(pair_meta.creator == creator_addr, ENO_PERMISSION_TO_REMOVE_PAIR);

    // withdraw all reserves coin to creator of pair
    coin::transfer<Coin_a>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_from_reserves, 0));
    coin::transfer<Coin_b>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_from_reserves, 1));
    coin::transfer<Coin_c>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_to_reserves, 0));

    
    let events = borrow_global_mut<Events>(resource_signer_address);

    // trigger remove pair event
    event::emit_event(
      &mut events.pair_removed_event,
      PairRemovedEvent {
        meta: *pair_meta,
      },
    );

    // remove PairMeta from PairInfo map
    simple_map::remove(&mut pair_info_data.pair_meta_map, &pair_id);
  }

  public entry fun remove_quadruple_pair<Coin_a, Coin_b, Coin_c, Coin_d>(creator: &signer, pair_id: String) acquires AdminData, PairInfo, Events {
    let creator_addr = signer::address_of(creator);
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);

    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);

    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta = simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);

    assert!(pair_meta.creator == creator_addr, ENO_PERMISSION_TO_REMOVE_PAIR);

    // withdraw all reserves coin to creator of pair
    coin::transfer<Coin_a>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_from_reserves, 0));
    coin::transfer<Coin_b>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_from_reserves, 1));
    coin::transfer<Coin_c>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_to_reserves, 0));
    coin::transfer<Coin_d>(&resource_signer, creator_addr, *vector::borrow(&pair_meta.coins_to_reserves, 1));

    let events = borrow_global_mut<Events>(resource_signer_address);

    // trigger remove pair event
    event::emit_event(
      &mut events.pair_removed_event,
      PairRemovedEvent {
        meta: *pair_meta,
      },
    );

    // remove PairMeta from PairInfo map
    simple_map::remove(&mut pair_info_data.pair_meta_map, &pair_id);
  }
  
  public entry fun increase_reserves<Coin_a, Coin_b>(
    user: &signer, pair_id: String, coin_amount_a: u64, coin_amount_b: u64,
  ) acquires PairInfo {
    let user_addr = signer::address_of(user);

    assert!(coin::balance<Coin_a>(user_addr) >= coin_amount_a, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_b>(user_addr) >= coin_amount_b, E_INSUFFICIENT_COIN_BALANCE);

    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);
    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta_by_id = *simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);
    
    let coin_a_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 0);
    let coin_b_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_to_reserves, 0);

    // update coin_a reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 0) = coin_a_reserve_balance + coin_amount_a;
    // update coin_b reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_to_reserves, 0) = coin_b_reserve_balance + coin_amount_b;

    *simple_map::borrow_mut(&mut pair_info_data.pair_meta_map, &pair_id) = pair_meta_by_id;

    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();

    let coin_a_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 0);
    let coin_b_name_meta = *vector::borrow(&pair_meta_by_id.coins_to_name, 0);
    
    assert!(coin_a_name == coin_a_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_b_name == coin_b_name_meta, EINVALID_COIN_TYPE);

    // transfer coins 
    coin::transfer<Coin_a>(user, @owner_addr, coin_amount_a);
    coin::transfer<Coin_b>(user, @owner_addr, coin_amount_b);
  } 

  public entry fun increase_triple_reserves<Coin_a, Coin_b, Coin_c>(
    user: &signer, pair_id: String, coin_amount_a: u64, coin_amount_b: u64, coin_amount_c: u64,
  ) acquires PairInfo {
    let user_addr = signer::address_of(user);

    assert!(coin::balance<Coin_a>(user_addr) >= coin_amount_a, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_b>(user_addr) >= coin_amount_b, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_c>(user_addr) >= coin_amount_c, E_INSUFFICIENT_COIN_BALANCE);

    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);
    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta_by_id = *simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);
    
    let coin_a_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 0);
    let coin_b_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 1);
    let coin_c_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_to_reserves, 0);

    // update coin_a reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 0) = coin_a_reserve_balance + coin_amount_a;
    // update coin_b reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 1) = coin_b_reserve_balance + coin_amount_b;
    // update coin_c reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_to_reserves, 0) = coin_c_reserve_balance + coin_amount_c;


    *simple_map::borrow_mut(&mut pair_info_data.pair_meta_map, &pair_id) = pair_meta_by_id;

    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();
    let coin_c_name = type_info::type_name<Coin_c>();

    let coin_a_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 0);
    let coin_b_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 1);
    let coin_c_name_meta = *vector::borrow(&pair_meta_by_id.coins_to_name, 0);

    assert!(coin_a_name == coin_a_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_b_name == coin_b_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_c_name == coin_c_name_meta, EINVALID_COIN_TYPE);

    // transfer coins 
    coin::transfer<Coin_a>(user, @owner_addr, coin_amount_a);
    coin::transfer<Coin_b>(user, @owner_addr, coin_amount_b);
    coin::transfer<Coin_c>(user, @owner_addr, coin_amount_c);
  }

  public entry fun increase_quadruple_reserves<Coin_a, Coin_b, Coin_c, Coin_d>(
    user: &signer, pair_id: String, coin_amount_a: u64, coin_amount_b: u64, coin_amount_c: u64, coin_amount_d: u64,
  ) acquires PairInfo {
    let user_addr = signer::address_of(user);

    assert!(coin::balance<Coin_a>(user_addr) >= coin_amount_a, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_b>(user_addr) >= coin_amount_b, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_c>(user_addr) >= coin_amount_c, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_d>(user_addr) >= coin_amount_d, E_INSUFFICIENT_COIN_BALANCE);

    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);
    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta_by_id = *simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);
    
    let coin_a_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 0);
    let coin_b_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 1);
    let coin_c_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_to_reserves, 0);
    let coin_d_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_to_reserves, 1);

    // update coin_a reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 0) = coin_a_reserve_balance + coin_amount_a;
    // update coin_b reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 1) = coin_b_reserve_balance + coin_amount_b;
    // update coin_c reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_to_reserves, 0) = coin_c_reserve_balance + coin_amount_c;
    // update coin_d reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_to_reserves, 1) = coin_d_reserve_balance + coin_amount_d;

    *simple_map::borrow_mut(&mut pair_info_data.pair_meta_map, &pair_id) = pair_meta_by_id;

    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();
    let coin_c_name = type_info::type_name<Coin_c>();
    let coin_d_name = type_info::type_name<Coin_d>();

    let coin_a_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 0);
    let coin_b_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 1);
    let coin_c_name_meta = *vector::borrow(&pair_meta_by_id.coins_to_name, 0);
    let coin_d_name_meta = *vector::borrow(&pair_meta_by_id.coins_to_name, 1);

    assert!(coin_a_name == coin_a_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_b_name == coin_b_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_c_name == coin_c_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_d_name == coin_d_name_meta, EINVALID_COIN_TYPE);

    // transfer coins
    coin::transfer<Coin_a>(user, @owner_addr, coin_amount_a);
    coin::transfer<Coin_b>(user, @owner_addr, coin_amount_b);
    coin::transfer<Coin_c>(user, @owner_addr, coin_amount_c);
    coin::transfer<Coin_d>(user, @owner_addr, coin_amount_d);
  } 

  public entry fun create_pair<Coin_a, Coin_b>(
    creator: &signer,
    exchange_rates: vector<u64>,
    coin_a_reserves: u64,
    coin_b_reserves: u64,
  ) acquires PairInfo, AdminData, Events {
    let creator_addr = signer::address_of(creator);
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);
    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);

    let coin_a_type_info = type_info::type_of<Coin_a>();
    let coin_b_type_info = type_info::type_of<Coin_b>();

    let coin_a_struct_name = type_info::struct_name(&coin_a_type_info);
    let coin_b_struct_name = type_info::struct_name(&coin_b_type_info);
    
    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();

    let pair_meta_seed = string_utils::to_string<vector<u8>>(&coin_a_struct_name);
    string::append(&mut pair_meta_seed, string_utils::to_string<vector<u8>>(&coin_b_struct_name));
    
    // register coins on resource account
    register_coin<Coin_a>(&resource_signer);
    register_coin<Coin_b>(&resource_signer);

    assert!(coin_a_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);
    assert!(coin_b_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);
    
    assert!(coin::balance<Coin_a>(creator_addr) >= coin_a_reserves, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_b>(creator_addr) >= coin_b_reserves, E_INSUFFICIENT_COIN_BALANCE);

    // transfer coins from creator of pair to treasury (resource account)
    coin::transfer<Coin_a>(creator, @owner_addr, coin_a_reserves);
    coin::transfer<Coin_b>(creator, @owner_addr, coin_b_reserves);

    let coins_from = vector[coin_a_type_info];    
    let coins_to = vector[coin_b_type_info];
    let coins_from_name = vector[coin_a_name];
    let coins_to_name = vector[coin_b_name];    
    let coins_from_reserves = vector[coin_a_reserves];    
    let coins_to_reserves = vector[coin_b_reserves];

    let pair_meta = PairMeta {
      coins_from,
      coins_to,
      coins_from_name,
      coins_to_name,
      coins_from_reserves,
      coins_to_reserves,
      exchange_rates,
      creator: creator_addr,
    };

    simple_map::add(
      &mut pair_info_data.pair_meta_map,
      pair_meta_seed,
      copy pair_meta,
    );

    // trigger create pair event
    let events = borrow_global_mut<Events>(resource_signer_address);
    
    event::emit_event(&mut events.pair_created_event, PairCreatedEvent {
      meta: pair_meta,
    });
  }

  public entry fun create_triple_pair<Coin_a, Coin_b, Coin_c>(
    creator: &signer,
    exchange_rates: vector<u64>,
    coin_a_reserves: u64, // from 1
    coin_b_reserves: u64, // from 2
    coin_c_reserves: u64, // to 1
  ) acquires PairInfo, AdminData, Events {
    let creator_addr = signer::address_of(creator);
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);
    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);

    let coin_a_type_info = type_info::type_of<Coin_a>();
    let coin_b_type_info = type_info::type_of<Coin_b>();
    let coin_c_type_info = type_info::type_of<Coin_c>();

    let coin_a_struct_name = type_info::struct_name(&coin_a_type_info);
    let coin_b_struct_name = type_info::struct_name(&coin_b_type_info);
    let coin_c_struct_name = type_info::struct_name(&coin_c_type_info);
    
    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();
    let coin_c_name = type_info::type_name<Coin_c>();

    let pair_meta_seed = string_utils::to_string<vector<u8>>(&coin_a_struct_name);
    string::append(&mut pair_meta_seed, string_utils::to_string<vector<u8>>(&coin_b_struct_name));
    string::append(&mut pair_meta_seed, string_utils::to_string<vector<u8>>(&coin_c_struct_name));
    
    // register coins on resource account
    register_coin<Coin_a>(&resource_signer);
    register_coin<Coin_b>(&resource_signer);
    register_coin<Coin_c>(&resource_signer);

    assert!(coin_a_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);
    assert!(coin_b_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);
    assert!(coin_c_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);
    
    assert!(coin::balance<Coin_a>(creator_addr) >= coin_a_reserves, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_b>(creator_addr) >= coin_b_reserves, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_c>(creator_addr) >= coin_c_reserves, E_INSUFFICIENT_COIN_BALANCE);

    // transfer coins from creator of pair to treasury (resource account)
    coin::transfer<Coin_a>(creator, @owner_addr, coin_a_reserves);
    coin::transfer<Coin_b>(creator, @owner_addr, coin_b_reserves);
    coin::transfer<Coin_c>(creator, @owner_addr, coin_c_reserves);

    let coins_from = vector[coin_a_type_info, coin_b_type_info];
    let coins_to = vector[coin_c_type_info];    
    let coins_from_name = vector[coin_a_name, coin_b_name];
    let coins_to_name = vector[coin_c_name];
    let coins_from_reserves = vector[coin_a_reserves, coin_b_reserves];
    let coins_to_reserves = vector[coin_c_reserves];

    let pair_meta = PairMeta {
      coins_from,
      coins_to,
      coins_from_name,
      coins_to_name,
      coins_from_reserves,
      coins_to_reserves,
      exchange_rates,
      creator: creator_addr,
    };

    simple_map::add(
      &mut pair_info_data.pair_meta_map,
      pair_meta_seed,
      copy pair_meta,
    );

    // trigger create pair event
    let events = borrow_global_mut<Events>(resource_signer_address);
    
    event::emit_event(&mut events.pair_created_event, PairCreatedEvent {
      meta: pair_meta,
    });
  }

  public entry fun create_quadruple_pair<Coin_a, Coin_b, Coin_c, Coin_d>(
    creator: &signer,
    exchange_rates: vector<u64>,
    coin_a_reserves: u64, // from 1
    coin_b_reserves: u64, // from 2
    coin_c_reserves: u64, // to 1
    coin_d_reserves: u64, // to 2
  ) acquires PairInfo, AdminData, Events {
    let creator_addr = signer::address_of(creator);
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);
    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);

    let coin_a_type_info = type_info::type_of<Coin_a>();
    let coin_b_type_info = type_info::type_of<Coin_b>();
    let coin_c_type_info = type_info::type_of<Coin_c>();
    let coin_d_type_info = type_info::type_of<Coin_d>();

    let coin_a_struct_name = type_info::struct_name(&coin_a_type_info);
    let coin_b_struct_name = type_info::struct_name(&coin_b_type_info);
    let coin_c_struct_name = type_info::struct_name(&coin_c_type_info);
    let coin_d_struct_name = type_info::struct_name(&coin_d_type_info);
    
    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();
    let coin_c_name = type_info::type_name<Coin_c>();
    let coin_d_name = type_info::type_name<Coin_d>();

    let pair_meta_seed = string_utils::to_string<vector<u8>>(&coin_a_struct_name);
    string::append(&mut pair_meta_seed, string_utils::to_string<vector<u8>>(&coin_b_struct_name));
    string::append(&mut pair_meta_seed, string_utils::to_string<vector<u8>>(&coin_c_struct_name));
    string::append(&mut pair_meta_seed, string_utils::to_string<vector<u8>>(&coin_d_struct_name));
    
    // register coins on resource account
    register_coin<Coin_a>(&resource_signer);
    register_coin<Coin_b>(&resource_signer);
    register_coin<Coin_c>(&resource_signer);
    register_coin<Coin_d>(&resource_signer);

    assert!(coin_a_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);
    assert!(coin_b_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);
    assert!(coin_c_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);
    assert!(coin_d_reserves > 0, E_INSUFFICIENT_COIN_AMOUNT);

    assert!(coin::balance<Coin_a>(creator_addr) >= coin_a_reserves, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_b>(creator_addr) >= coin_b_reserves, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_c>(creator_addr) >= coin_c_reserves, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_d>(creator_addr) >= coin_d_reserves, E_INSUFFICIENT_COIN_BALANCE);

    // transfer coins from creator of pair to treasury (resource account)
    coin::transfer<Coin_a>(creator, @owner_addr, coin_a_reserves);
    coin::transfer<Coin_b>(creator, @owner_addr, coin_b_reserves);
    coin::transfer<Coin_c>(creator, @owner_addr, coin_c_reserves);
    coin::transfer<Coin_d>(creator, @owner_addr, coin_d_reserves);

    let coins_from = vector[coin_a_type_info, coin_b_type_info];
    let coins_to = vector[coin_c_type_info, coin_d_type_info];
    let coins_from_name = vector[coin_a_name, coin_b_name];
    let coins_to_name = vector[coin_c_name, coin_d_name];
    let coins_from_reserves = vector[coin_a_reserves, coin_b_reserves];
    let coins_to_reserves = vector[coin_c_reserves, coin_d_reserves];

    let pair_meta = PairMeta {
      coins_from,
      coins_to,
      coins_from_name,
      coins_to_name,
      coins_from_reserves,
      coins_to_reserves,
      exchange_rates,
      creator: creator_addr,
    };

    simple_map::add(
      &mut pair_info_data.pair_meta_map,
      pair_meta_seed,
      copy pair_meta,
    );

    // trigger create pair event
    let events = borrow_global_mut<Events>(resource_signer_address);
    
    event::emit_event(&mut events.pair_created_event, PairCreatedEvent {
      meta: pair_meta,
    });
  }

  public entry fun swap<Coin_a, Coin_b>(
    user: &signer, pair_id: String, coin_amount_a: u64,
  ) acquires AdminData, PairInfo, Events {
    let user_addr = signer::address_of(user);    
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);

    assert!(coin_amount_a > 0, E_INSUFFICIENT_COIN_AMOUNT);
    
    assert!(coin::balance<Coin_a>(user_addr) >= coin_amount_a, E_INSUFFICIENT_COIN_BALANCE);
    
    // get pair info
    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);
    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta_by_id = *simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);

    let fixed_exchange_rate = *vector::borrow(&pair_meta_by_id.exchange_rates, 0);

    let deposit_coin_amount = (coin_amount_a / 100) * fixed_exchange_rate;

    let coin_b_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_to_reserves, 0);
    // check if reservers has enough coin balance
    assert!(coin_b_reserve_balance >= deposit_coin_amount, ENOT_ENOUGH_COINS_IN_RESERVES);

    // update coin_b reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_to_reserves, 0) = coin_b_reserve_balance - deposit_coin_amount;  
     
    let coin_a_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 0);

    // update coin_a reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 0) = coin_a_reserve_balance + coin_amount_a;
    
    // save changes of PairMeta
    *simple_map::borrow_mut(&mut pair_info_data.pair_meta_map, &pair_id) = pair_meta_by_id;

    // transfer from user account to owner address coin_a
    coin::transfer<Coin_a>(user, @owner_addr, coin_amount_a);
    // register Coin_b type if user dont have it already
    register_coin<Coin_b>(user);
    // transfer from Exchange address to user address all coin y
    coin::transfer<Coin_b>(&resource_signer, user_addr, (deposit_coin_amount as u64));
    
    let events = borrow_global_mut<Events>(resource_signer_address);

    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();

    // check if coins that user pass - is same as stored in pair meta map
    let coin_a_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 0);
    let coin_b_name_meta = *vector::borrow(&pair_meta_by_id.coins_to_name, 0);
    assert!(coin_a_name == coin_a_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_b_name == coin_b_name_meta, EINVALID_COIN_TYPE);

    let coins_from_name_vector = vector[coin_a_name];
    let coins_to_name_vector = vector[coin_b_name];
    let coins_from_amount_vector = vector[coin_amount_a];    
    let coins_to_amount_vector = vector[deposit_coin_amount];

    // trigger swap event
    event::emit_event<SwapEvent>(
      &mut events.swap_event,
      SwapEvent {
        coins_from_name: coins_from_name_vector,
        coins_to_name: coins_to_name_vector,
        coins_from_amount: coins_from_amount_vector,
        coins_to_amount: coins_to_amount_vector,
        exchange_rates: pair_meta_by_id.exchange_rates,
        timestamp: timestamp::now_seconds(),
      },
    );
  }

  public entry fun triple_swap<Coin_a, Coin_b, Coin_c>(
    user: &signer, pair_id: String, coin_amount_a: u64, coin_amount_b: u64
  ) acquires AdminData, PairInfo, Events {
    let user_addr = signer::address_of(user);    
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);

    assert!(coin_amount_a > 0, E_INSUFFICIENT_COIN_AMOUNT);
    assert!(coin_amount_b > 0, E_INSUFFICIENT_COIN_AMOUNT);
    
    assert!(coin::balance<Coin_a>(user_addr) >= coin_amount_a, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_b>(user_addr) >= coin_amount_b, E_INSUFFICIENT_COIN_BALANCE);
    
    // get pair info
    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);
    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta_by_id = *simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);

    let fixed_exchange_rate = *vector::borrow(&pair_meta_by_id.exchange_rates, 0);

    let deposit_coin_amount = (coin_amount_a / 100) * fixed_exchange_rate;

    let coin_c_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_to_reserves, 0);
    // check if reservers has enough balance of coin_amount_c
    assert!(coin_c_reserve_balance >= deposit_coin_amount, ENOT_ENOUGH_COINS_IN_RESERVES);

    // update coin_c reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_to_reserves, 0) = coin_c_reserve_balance - deposit_coin_amount;  
     
    let coin_a_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 0);
    let coin_b_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 1);
    
    // update coin_a reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 0) = coin_a_reserve_balance + coin_amount_a;
    // update coin_b reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 1) = coin_b_reserve_balance + coin_amount_b;
    
    // save changes of PairMeta
    *simple_map::borrow_mut(&mut pair_info_data.pair_meta_map, &pair_id) = pair_meta_by_id;

    // transfer from user account to owner address all coin a and coin b
    coin::transfer<Coin_a>(user, @owner_addr, coin_amount_a);
    coin::transfer<Coin_b>(user, @owner_addr, coin_amount_b);
    
    // register Coin_c type if user dont have it already
    register_coin<Coin_c>(user);
    // transfer from Exchange address to user address all coin y
    coin::transfer<Coin_c>(&resource_signer, user_addr, (deposit_coin_amount as u64));
    
    let events = borrow_global_mut<Events>(resource_signer_address);

    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();
    let coin_c_name = type_info::type_name<Coin_c>();

    // check if coins that user pass - is same as stored in pair meta map
    let coin_a_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 0);
    let coin_b_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 1);
    let coin_c_name_meta = *vector::borrow(&pair_meta_by_id.coins_to_name, 0);

    assert!(coin_a_name == coin_a_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_b_name == coin_b_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_c_name == coin_c_name_meta, EINVALID_COIN_TYPE);

    let coins_from_name_vector = vector[coin_a_name, coin_b_name];
    let coins_to_name_vector = vector[coin_c_name];
    let coins_from_amount_vector = vector[coin_amount_a, coin_amount_b];
    let coins_to_amount_vector = vector[deposit_coin_amount];
    
    // trigger swap event
    event::emit_event<SwapEvent>(
      &mut events.swap_event,
      SwapEvent {
        coins_from_name: coins_from_name_vector,
        coins_to_name: coins_to_name_vector,
        coins_from_amount: coins_from_amount_vector,
        coins_to_amount: coins_to_amount_vector,
        exchange_rates: pair_meta_by_id.exchange_rates,
        timestamp: timestamp::now_seconds(),
      },
    );
  }

  // swap Coin_a + Coin_b => Coin_C + Coin_d
  public entry fun quadruple_swap<Coin_a, Coin_b, Coin_c, Coin_d>(
    user: &signer, pair_id: String, coin_amount_a: u64, coin_amount_b: u64
  ) acquires AdminData, PairInfo, Events {
    let user_addr = signer::address_of(user);    
    let resource_signer = get_resource_signer();
    let resource_signer_address = signer::address_of(&resource_signer);

    assert!(coin_amount_a > 0, E_INSUFFICIENT_COIN_AMOUNT);
    assert!(coin_amount_b > 0, E_INSUFFICIENT_COIN_AMOUNT);
    
    assert!(coin::balance<Coin_a>(user_addr) >= coin_amount_a, E_INSUFFICIENT_COIN_BALANCE);
    assert!(coin::balance<Coin_b>(user_addr) >= coin_amount_b, E_INSUFFICIENT_COIN_BALANCE);
    
    // get pair info
    let pair_info_data = borrow_global_mut<PairInfo>(@owner_addr);
    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta_by_id = *simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);

    let fixed_exchange_rate_a = *vector::borrow(&pair_meta_by_id.exchange_rates, 0);
    let fixed_exchange_rate_b = *vector::borrow(&pair_meta_by_id.exchange_rates, 1);

    let deposit_coin_amount_a = (coin_amount_a / 100) * fixed_exchange_rate_a;
    let deposit_coin_amount_b = (coin_amount_b / 100) * fixed_exchange_rate_b;

    let coin_c_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_to_reserves, 0);
    let coin_d_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_to_reserves, 1);
    // check if reservers has enough balance of coin_amount_c
    assert!(coin_c_reserve_balance >= deposit_coin_amount_a, ENOT_ENOUGH_COINS_IN_RESERVES);
    assert!(coin_d_reserve_balance >= deposit_coin_amount_b, ENOT_ENOUGH_COINS_IN_RESERVES);

    // update coin_c and coin_d reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_to_reserves, 0) = coin_c_reserve_balance - deposit_coin_amount_a;
    *vector::borrow_mut(&mut pair_meta_by_id.coins_to_reserves, 0) = coin_d_reserve_balance - deposit_coin_amount_b;

    let coin_a_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 0);
    let coin_b_reserve_balance = *vector::borrow<u64>(&pair_meta_by_id.coins_from_reserves, 1);
    
    // update coin_a reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 0) = coin_a_reserve_balance + coin_amount_a;
    // update coin_b reserves
    *vector::borrow_mut(&mut pair_meta_by_id.coins_from_reserves, 1) = coin_b_reserve_balance + coin_amount_b;
    
    // save changes of PairMeta
    *simple_map::borrow_mut(&mut pair_info_data.pair_meta_map, &pair_id) = pair_meta_by_id;

    // transfer from user account to owner address all coin a and coin b
    coin::transfer<Coin_a>(user, @owner_addr, coin_amount_a);
    coin::transfer<Coin_b>(user, @owner_addr, coin_amount_b);
    
    // register Coin_c and Coin_d type if user dont have it already
    register_coin<Coin_c>(user);
    register_coin<Coin_d>(user);
    // transfer from Exchange address to user address all coin y
    coin::transfer<Coin_c>(&resource_signer, user_addr, (deposit_coin_amount_a as u64));
    coin::transfer<Coin_d>(&resource_signer, user_addr, (deposit_coin_amount_b as u64));
    
    let events = borrow_global_mut<Events>(resource_signer_address);

    let coin_a_name = type_info::type_name<Coin_a>();
    let coin_b_name = type_info::type_name<Coin_b>();
    let coin_c_name = type_info::type_name<Coin_c>();
    let coin_d_name = type_info::type_name<Coin_d>();

    // check if coins that user pass - is same as stored in pair meta map
    let coin_a_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 0);
    let coin_b_name_meta = *vector::borrow(&pair_meta_by_id.coins_from_name, 1);
    let coin_c_name_meta = *vector::borrow(&pair_meta_by_id.coins_to_name, 0);
    let coin_d_name_meta = *vector::borrow(&pair_meta_by_id.coins_to_name, 1);

    assert!(coin_a_name == coin_a_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_b_name == coin_b_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_c_name == coin_c_name_meta, EINVALID_COIN_TYPE);
    assert!(coin_d_name == coin_d_name_meta, EINVALID_COIN_TYPE);

    let coins_from_name_vector = vector[coin_a_name, coin_b_name];
    let coins_to_name_vector = vector[coin_c_name, coin_d_name];
    let coins_from_amount_vector = vector[coin_amount_a, coin_amount_b];
    let coins_to_amount_vector = vector[deposit_coin_amount_a, deposit_coin_amount_b];
    
    // trigger swap event
    event::emit_event<SwapEvent>(
      &mut events.swap_event,
      SwapEvent {
        coins_from_name: coins_from_name_vector,
        coins_to_name: coins_to_name_vector,
        coins_from_amount: coins_from_amount_vector,
        coins_to_amount: coins_to_amount_vector,
        exchange_rates: pair_meta_by_id.exchange_rates,
        timestamp: timestamp::now_seconds(),
      },
    );
  }

  // View functions
  // get all pairs info
  #[view]
  public fun get_all_pairs(): SimpleMap<String, PairMeta> acquires PairInfo {
    let pair_info_data = borrow_global<PairInfo>(@owner_addr);
    pair_info_data.pair_meta_map
  }

  // Get Trading Pair By creator address and trading pair id
  #[view]
  public fun get_pair_info_by_id(pair_id: String): PairMeta acquires PairInfo {
    let pair_info_data = borrow_global<PairInfo>(@owner_addr);
    // check if contains by id 
    assert!(simple_map::contains_key(&pair_info_data.pair_meta_map, &pair_id), ENO_PAIR_INFO);

    let pair_meta = simple_map::borrow(&pair_info_data.pair_meta_map, &pair_id);
    *pair_meta
  }
}
