Aptos Coin Swap and Minting Module: Setup and Usage Guide
=========================================================

### Local Testing

1.  Follow the official [Aptos CLI installation guide](https://aptos.dev/tools/install-cli/).
2.  Create a new Aptos account with `aptos init` (this will create a new folder `.aptos` and store public and private keys in it).
3.  Import the private key from `.aptos` to the Petra Extension.
4.  Navigate to the `/mintCoins` folder and mint 10 coins using the account (`owner_addr`) from the `.aptos/config.yaml` `account` field.  
    Run the following command in the `/move` folder:
    
    `aptos move publish --named-addresses owner_addr=account`
    
5.  Navigate to the `/coinSwap` folder, create a resource account, and deploy the swap module using the same account value in `source_addr`.
    
    `aptos move create-resource-account-and-publish-package --seed 12345 --address-name owner_addr --profile default --named-addresses source_addr=account`
    
    Copy the resource account address after deployment.
6.  Go to the main React app and update the `config.json` module address with the created resource account.
7.  Install all frontend dependencies in the `/frontend` directory using `yarn install`, then run the main app with `npm run start`.
8.  Connect your wallet, create a new pair, fill in all fields in the Create Trading Pair form, and click `Create Trading Pair`.  
    The module currently supports 1-1, 2-1, and 2-2 coin pairs.
9.  The created pair should appear in the list of trading pairs. Select it and proceed to the main Swap UI.
10.  Fill in the coin inputs and click `swap`.

* * *

### Modules

*   **mint\_coins.move** - A module to mint 10 new coins: Minerals, EnergyCrystals, Gasolineium, OrganicBiomass, PlasmaCores, NeutroniumAlloy, DarkMatterResidue, RefinedPlasmoid, Hypersteel, BioluminescentFiber, each with different initial balances.
*   **swap\_coins.move** - The main swap module supporting 1-1, 2-1, and 2-2 coin pairs.

* * *

Entry Points
------------

### `Create Pair`

Creates a new swap pair, sets a fixed exchange rate, and sends initial coins to reserves. The module supports `create_pair` (1-1 coin), `create_triple_pair` (2-1 coins), and `create_quadruple_pair` (2-2 coins).

**Arguments:** `creator: &signer, exchange_rates: vector<u64>, coin_a_reserves: u64, coin_b_reserves: u64`  
**Type Arguments:** `CoinTypeA, CoinTypeB`

**Usage:**


``const moduleAddress = "0x0"; // pass your module address here const exchangeRates = [150]; const coinsAAmount = 1000; const coinsBAmount = 1000; const coinTypeA = `${moduleAddress}::mint_coins::Minerals`; const coinTypeB = `${moduleAddress}::mint_coins::EnergyCrystals`; const decimals = 8;  const payload = {     type: "entry_function_payload",     function: `${moduleAddress}::swap_coins::create_pair`,     type_arguments: [coinTypeA, coinTypeB],     arguments: [exchangeRates, coinsAAmount * (10 ** decimals), coinsBAmount * (10 ** decimals)], };  try {     const txResult = await signAndSubmitTransaction(payload);     await client.waitForTransactionWithResult(txResult.hash); } catch (e) {     console.log(e); }``

* * *

### `Increase Reserves`

Transfers coins from a user to the resource account and increases reserve values. Anyone can call this method.  
Supports `increase_reserves` (1-1 coin), `increase_triple_reserves` (2-1 coins), and `increase_quadruple_reserves` (2-2 coins).

**Arguments:** `user: &signer, pair_id: String, coin_amount_a: u64, coin_amount_b: u64`  
**Type Arguments:** `CoinTypeA, CoinTypeB`

**Usage:**



``const moduleAddress = "0x0"; const pairId = "0x1"; const coinAmountA = 1000; const coinAmountB = 1000; const coinTypeA = `${moduleAddress}::mint_coins::Minerals`; const coinTypeB = `${moduleAddress}::mint_coins::EnergyCrystals`; const decimals = 8;  const payload = {     type: "entry_function_payload",     function: `${moduleAddress}::swap_coins::increase_reserves`,     type_arguments: [coinTypeA, coinTypeB],     arguments: [pairId, coinAmountA * (10 ** decimals), coinAmountB * (10 ** decimals)], };  try {     const txResult = await signAndSubmitTransaction(payload);     await client.waitForTransactionWithResult(txResult.hash); } catch (e) {     console.log(e); }``

* * *

### `Remove Pair`

Removes a pair from `PairMeta` based on `pair_id` and returns all coins in reserves to the pair creator.  
Supports `remove_pair` (1-1 coin), `remove_triple_pair` (2-1 coins), and `remove_quadruple_pair` (2-2 coins). Only the creator can remove the pair.

**Arguments:** `creator: &signer, pair_id: String`  
**Type Arguments:** `CoinTypeA, CoinTypeB`

**Usage:**

``const moduleAddress = "0x0"; // pass your module address here const coinTypeA = `${moduleAddress}::mint_coins::Minerals`; const coinTypeB = `${moduleAddress}::mint_coins::EnergyCrystals`; const pairId = "0x01";  const payload = {     type: "entry_function_payload",     function: `${moduleAddress}::swap_coins::remove_pair`,     type_arguments: [coinTypeA, CoinTypeB],     arguments: [pairId], };  try {     const txResult = await signAndSubmitTransaction(payload);     await client.waitForTransactionWithResult(txResult.hash); } catch (e) {     console.log(e); }``

* * *

### `Swap`

Swaps `coinA` to `coinB` based on the saved exchange rate, provided there are sufficient coins in the reserves.  
Supports `swap` (1-1 coin, `CoinA => CoinB`), `triple_swap` (2-1 coins, `CoinA + CoinB => CoinC`), and `quadruple_swap` (2-2 coins, `CoinA + CoinB => CoinC + CoinD`).

**Arguments:** `user: &signer, pair_id: String, coin_amount_a: u64`  
**Type Arguments:** `CoinTypeA, CoinTypeB`

**Usage:**

``const moduleAddress = "0x0"; // pass your module address here const coinTypeA = `${moduleAddress}::mint_coins::Minerals`; const coinTypeB = `${moduleAddress}::mint_coins::EnergyCrystals`; const pairId = "0x01"; const coinsAAmount = 1000; const decimals = 8;  const payload = {     type: "entry_function_payload",     function: `${moduleAddress}::swap_coins::swap`,     type_arguments: [coinTypeA, coinTypeB],     arguments: [pairId, coinsAAmount * (10 ** decimals)], };  try {     const txResult = await signAndSubmitTransaction(payload);     await client.waitForTransactionWithResult(txResult.hash); } catch (e) {     console.log(e); }``

* * *

View Functions
--------------

### `Get All Pairs`

Returns a map of all pairs' metadata with their respective `pair_id`.

**Arguments:** None

**Usage:**

``const payload = {     function: `${moduleAddress}::swap_coins::get_all_pairs`,     type_arguments: [],     arguments: [] };  try {     const allPairsInfo = await provider.view(payload);     console.log(allPairsInfo[0].data); } catch (e) {     console.log(e); }``

* * *

### `Get Pair Info By Id`

Returns pair metadata based on the `pair_id`.

**Arguments:** `pair_id: String`

**Usage:**

``const pairId = "0x0"; const payload = {     function: `${moduleAddress}::swap_coins::get_pair_info_by_id`,     type_arguments: [],     arguments: [pairId] };  try {     const pairInfo = await provider.view(payload);     console.log(pairInfo[0].data); } catch (e) {     console.log(e); }``

* * *

### `Get List of Events`

The module has three basic events: `PairCreatedEvent`, `PairRemovedEvent`, and `SwapEvent`, structured as follows:


`PairCreatedEvent {     meta: PairMeta, }  PairRemovedEvent {     meta: PairMeta, }  SwapEvent {     coins_from_name: vector<String>,     coins_to_name: vector<String>,     coins_from_amount: vector<u64>,     coins_to_amount: vector<u64>,     exchange_rates: vector<u64>,     timestamp: u64, }`

**Usage (example for swap events):**

``const moduleAddress = "0x0"; const eventsStore = `${moduleAddress}::swap_coins::Events`;  try {     const eventsResult = await client.getEventsByEventHandle(moduleAddress, eventsStore, "swap_event");     console.log(eventsResult); } catch (e) {     console.log(e); }``

* * *

SwapCoins module deployed on testnet [here](https://explorer.aptoslabs.com/account/0xecea4a4dca5110d757d5ef3f95b86a374efd1439d4d89a66f746588cd9789123?network=testnet).
