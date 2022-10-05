# Inverse Total Return Swap
A simple crypto derivatives contract for creating fully-collateralized synthetic assets (aka stablecoins) on Ethereum.

## Using The Contract
To gain exposure to the denominating asset (e.g. USD), simply buy into the protection buyer pool with `buyHedge(amount, to)`.  
To gain leveraged exposure to the reference asset (e.g. ETH), buy into the protection seller pool with `buyLeverage(amount, to)`.  
Each operation requires payment in the reference asset and returns a synthetic asset representing your stake in the pool.  
You can sell out of either pool at any time with `sellHedge(amount, to)` and `sellLeverage(amount, to)`.

### Deployments
The swap contract is deployed on Arbitrum and can be interacted with using arbiscan:  
[0x841fA73a7c8CA0B513c60B3DeEEd498dd3b546Ca](https://arbiscan.io/address/0x841fa73a7c8ca0b513c60b3deeed498dd3b546ca#writeProxyContract)

### Risks
#### Not Audited
The code is not audited. Despite the contract's minimal attack surface, I can't guarantee it's safe to use.

#### Administered
The Swap and Token contracts are administered and upgradeable by me, but they're behind a one-week timelock.
This enforces that I must schedule any parameter changes or upgrades a week in advance, giving participants time to exit the system.

## Nomenclature
The swap contract is defined by its reference asset and its denominating asset, for example "ETH/USD".  
  
The symbol for the synthetic asset representing the protection buyer pool is its target asset followed by its collateralizing asset in superscript. For the protection seller pool, it's the reference asset followed by the denominating asset.

For example,  
ETH/USD hedge token: &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;USDᵉᵗʰ, or Ether-collateralized synthetic USD  
ETH/USD leverage token: &nbsp;ETHUSD, or leveraged Ether (USD)

## How It Works
The core of the system is the Swap contract. It works similarly to a total return swap in traditional finance, where cashflows are exchanged between two parties based on the performance of a reference asset and a floating interest rate. But rather than the two counterparties being individual companies or people, they're represented as two stake pools, each with its own token.  
In addition,
  1. The two stake pools, representing the protection buyers and protection sellers, can be permissionlessly entered into or exited out of at any time.
  2. Payments and collateral (on both sides) are in the reference asset.
  3. Losses and gains are automatically taken from or added to collateral as the price of the reference asset changes.
  4. The contract is marked to market (i.e. payments are made between stake pools) continuously as the price changes, rather than on predetermined dates. (In reality, payments are never "made", but pool sizes are recalculated for each buy or sell)
  5. The notional principal changes as traders enter or exit the protection buyer pool and as interest payments are made.
  6. The interest rate is a function of the relative size of the two stake pools (i.e. the collateral ratio) rather than an external index such as LIBOR.
  7. The reference asset is an ERC20 token such as WETH or WBTC.
  8. The asset denominating the notinal principal can be any currency, equity, index, etc for which a price feed exists.
  
### Interest Rate
Interest payments are made from the protection seller pool to the protection buyer pool on an hourly basis. Each swap contract has its own variable interest rate, used to target a collateralization ratio by changing the relative demand for the two tokens. Interest payments are automatically reinvested.

Currently, the annual rate (R) is proportional of the contract's collateral ratio (C):

R = 0.2 * C - 0.28

This interest rate model may change in the future.
  
### Fees
There's a 0.1% fee on all buys and sells that goes to existing stakeholders. The fee is put into the protection seller pool and, in turn, factored into the interest rate paid to the protection buyer pool via market forces.

Value is conserved within each swap contract. No disbursements of any kind are transferred out.

The fees serve to prevent soft frontrunning, where traders may have advance knowledge of price oracle updates.
  
### Calculating leverage

| L = C / (C - 1) |
| --------------- |

where

L = leverage of the leveraged coin  
C = collateralization ratio

and

C = (E + P) / P

where

E = value of protection seller pool  
P = The Notional principal / value of protection buyer pool
  
<!-- <img src="https://user-images.githubusercontent.com/13501607/150663503-7f72bbd7-2fb9-46fb-9ca5-0dc333cd9ddb.png" width="50%" height="50%">

  
- Market forces determine R and keep it above 1:  
  - As R falls closer to 1:  
    - L increases asymptotically toward infinity, increasing demand for the unstablecoin. R rises again as unstablecoins are bought.  
    - Risk of the peg breaking becomes greater, decreasing demand for the stablecoin. R rises again as stablecoins are sold.   -->

## Composing swaps
The synthetic assets created in one swap can be used as the reference equity/underlying asset in other swaps. In other words, the token outputs of one swap can be used as the token input to others.

### Shorting
E.g. use the USDᵉᵗʰ from the ETH/USD swap to create a USDᵉᵗʰ/ETH swap  
Creates ETHᵘˢᵈ (USDᵉᵗʰ-collateralized synthetic ETH) and USDETH (Shorted ETH (USD))  
  
ETH -> ETHUSD  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;USDᵉᵗʰ -> ETHᵘˢᵈ  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;USDETH  

### Squaring
E.g. use the ETHUSD created from the ETH/USD swap to create a ETHUSD/USD swap  
Creates USDᵉᵗʰᵘˢᵈ and ETHUSD²  
Gives more leverage

### Multi-Collateral Stablecoin
Create a USDᵇˡᵉⁿᵈ/USD swap where USDᵇˡᵉⁿᵈ is a blend of different synthetic USD assests, such as ones with different collateral types or collateralization ratios.  
For example, combine USDᵉᵗʰ and USDˡⁱⁿᵏ into a single USDᵇˡᵉⁿᵈ, and use that as the underlying asset in a USDᵇˡᵉⁿᵈ/USD swap.  The resulting USDᵘˢᵈ will be able to hold its peg even if USDˡⁱⁿᵏ or USDᵉᵗʰ (and thus USDᵇˡᵉⁿᵈ) lose their pegs.
<!-- 
## Comparison to Existing Projects
### MakerDAO
The products offered are very similar to those of MakerDAO but require zero maintainence, have no fees and are easier to conceptualize. Similar to DAI, the stablecoin is overcollateralized with an underlying asset such as ETH. And similar to a CDP, the protection seller pool token offers leveraged exposure to said underlying asset. But, unlike MakerDAO's CDPs, protection seller pool tokens are fungible just like any other. They're liquid and can be bought or sold on exchanges with little hastle or premiums.
#### Differences
DAI is a soft-pegged stablecoin with a hard-pegged collateralization ratio. USDᵉᵗʰ, on the other hand, is hard pegged to its price feed but has a soft-pegged collateralization ratio. Similar to how the value of DAI is maintained, the collateralization ratio of USDᵉᵗʰ is maintained through adjustments to the intererest rate. Unlike DAI, the interest rate is updated according to an interst rate model.

##### Better Stability with a Variable Collateralization Ratio
The stablecoin should achieve greater stability than MakerDAO's DAI by allowing the collateralization ratio to vary with market forces.  

DAI has maintained its peg well for the vast majority of its existence, but during a sharp drop in ETH price in March 2020, DAI deviated from its peg by over 20%. I believe a hard collateralization ratio was at least partially to blame for the extreme deviation. Burning mass quantities of DAI through CDP liquidations and deleveraging caused demand for DAI to outstrip supply.
  
The inverse TRS contract always buys back (and burns) its stablecoins at a rate such that the stablecoin exactly holds its peg. To do so at any greater or lesser rate would, by the law of supply and demand, break the peg. This is achieved very simply: users can sell their stablecoins back to the contract to be burned at any time for exactly the peg amount. They can also mint new stablecoins for the peg amount.

##### Value is Conserved
Unlike MakerDAO, there is no DAO that siphons value out of the system through interest rates or liquidation fees.  
The contract is also much simpler than MakerDAO, requiring no external services or auction mechanisms. This removes the need for even necessary fees.

##### Single Collateral Type Per System
DAI is collateralized with a mix of assets, including ETH, BAT, and USDC. Having a diverse porfolio of collateral assets mitigates risk of the system becoming undercollateralized.  
Each inverse TRS contract is collateralized with only one asset, but multliple contracts will be deployed, each with its own collateral. This allows traders a choice in the types and ratios of the collateral underlying their hedges. Alternatively, a blended collateral contract is planned to mix multiple collateral types into one, allowing for a multi-collateral stablecoin.

### Synthetix
From an end user's perspective, ESSA and Synthetix are very similar. They both offer collateralized synthetic assets but under the hood there are a number of differences. Most notably, the type of collateral used and the segmentation of debt. Synthetix uses its own native token to collateralize all its synths in a 'pooled debt' model. ESSA, on the other hand, uses only existing crypto assets such as ETH and segments debt between each of its synths.
-->
## Possible Attack Vectors
### Frontrunning / Sandwiching
A successful frontrunning attack could steal gains from or magnify losses of honest participants so it's imperative that it's never possible.   
  
#### Frontrunning Price Oracle Updates
This involves an attacker watching the mempool for a price oracle update then using a MEV auction to insert a buy or sell transaction infront of it to make a risk-free profit from the price change. Because of this possibility, the contrats cannot be deployed on Ethereum L1. Instead they are deployed on Arbitrum One, an L2 where transactions are executed in the order they are received by the sequencer(s).
  
#### Soft Frontrunning
In theory it's possible for an attacker to predict a price orace update before the transaction is sent to the sequencer by looking at off-chain data such as prices on centralized exchanges. Trading on this advanced price knowledge is sometimes called "soft frontrunning". To mitigate this, every buy or sell has an associated fee that makes a price change of a given amount unprofitable. If, for example, the fee were set to 0.1%, the price would need to change by more than 0.1% for gains to be greater than the trade's fee.

## Behavior in Event of Undercollateralization
If the value of the protection seller pool drops to zero, the remaining collateral in the protection buyer pool is split among stablecoin holders. Protection seller tokens can't be minted or burned during this time.
