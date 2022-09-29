# Equity Swap Synthetic Assets
A system of derivatives contracts for creating fully-collateralized synthetic assets (aka stablecoins) on Ethereum.

## Using The Contract
To gain exposure to the denominating asset (e.g. USD), simply buy into the protection buyer pool with `buyHedge(amount, to)`.
To gain leveraged exposure to the reference asset (e.g. ETH), buy into the protection seller pool with `buyLeverage(amount, to)`
Each operation requires payment in the reference asset and returns a synthetic asset representing your stake in the pool.
You can sell out of either pool at any time with `sellHedge(amount, to)` and `sellLeverage(amount, to)`.

## Nomenclature
### Swap Contracts
Contracts are defined by their reference equity and denominating asset, for example "ETH/USD".
## Tokens
The symbol for the synthetic asset representing the protection buyer pool is its target asset followed by its collateralizing asset in superscript. For the protection seller pool, the synthetic asset's symbol is the reference equity followed by the denominating asset in suprscript, all preceded by an "x".

For example,
ETH/USD hedge token:    USDᵉᵗʰ,  or Ether-collateralized synthetic USD
ETH/USD leverage token: xETHᵘˢᵈ, or leveraged Ether (USD)


## How It Works   
The core of the system is the Swap contract. It works similarly to an equity swap in traditional finance, where cashflows are exchanged between two parties based on the performance of a reference asset and a floating interest rate. But rather than the two counterparties being individual companies or people, they're represented as two stake pools, each with its own token.
In addition,
  1. The two stake pools, representing the protection buyers and protection sellers, can be permissionlessly entered into or exited out of at any time.
  2. Payments and collateral (on both sides) are in the reference equity.
  3. Payments are made whenever the price of the reference equity changes, rather than on predetermined dates. (In actuality, payments are never "made", but pool sizes are recalculated for each buy or sell)
  4. The notional principal changes as traders enter or exit the protection buyer pool and as interest payments are made
  5. The interest rate is a function of the relative size of the two stake pools (i.e. the collateral ratio) rather than an external index such as LIBOR.
  6. The reference equity is an ERC20 token such as WETH or WBTC.
  7. The asset denominating the notinal principal can be any currency, equity, index, etc for which a price feed exists.

### Interest Rate
Interest payments are made from the protection seller pool to the protection buyer pool on an hourly basis. Each swap contract has its own variable interest rate, used to target a collateralization ratio by changing the relative demand for the two tokens. Interest payments are automatically reinvested.

Currently, the rate (R) is proportional of the contract's collateral ratio (C):

R = 0.2 * R - 0.28

This interest rate model may change in the future.

### Fees
There's a 0.1% fee on all buys and sells that goes to existing stakeholders. The fee is put into the protection seller pool and, in turn, factored into the interest rate paid to the protection buyer pool via market forces.

Value is conserved within each swap contract. No disbursements of any kind are transferred out.

The fees serve to prevent soft frontrunning, where traders may have advance knoledge of price oracle updates.

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
The synthetic asset created from one swap can be used as reference equity/underlying asset in another swap. In other words, the token outputs of one swap can be used as the token input to another.

### Shorting
E.g. use the USDᵉᵗʰ from the ETH/USD swap to create a USDᵉᵗʰ/ETH swap
Creates ETHᵘˢᵈ (USDᵉᵗʰ-collateralized synthetic ETH) and xUSDᵉᵗʰ (Shorted ETH (USD))

leverage = 1 - xETHᵘˢᵈ leverage
So if ETH/USD is 150% collateralized and thus xETHᵘˢᵈ offers 3x leverage, our short has 1 - 3 = -2x leverage

ETH -> xETHᵘˢᵈ
       USDᵉᵗʰ -> ETHᵘˢᵈ
                 xUSDᵉᵗʰ

### Squaring
E.g. use the xETHᵘˢᵈ created from the ETH/USD swap to create a xETHᵘˢᵈ/USD swap
Creates USDˣᵉᵗʰ and xETH²ᵘˢᵈ
Gives more leverage

## Multi-collateral Stablecoin
Create an sUSD/USD swap where sUSD is a blend of different synthetic USD assests, such as ones with different collateral types or collateralization ratios.
For example, combine esUSD (ETH-collateralized Synthetic USD) and lsUSD (LINK-collateralized Synthetic USD) into a single sUSD, and use that as the underlying asset in a sUSD/USD swap.
The ssUSD created from the sUSD/USD swap will be able to hold its peg even if lsUSD or esUSD (and thus sUSD) lose their pegs.
Those taking the other side of the trade are taking on the risk of sUSD losing its peg but are being compensated with interest payments. 


## Comparison to existing projects
## MakerDAO
The products offered by VSSS are very similar to those of MakerDAO but require zero maintainence, have no fees and are easier to conceptualize. Similar to DAI, VSSS's stablecoin is overcollateralized with an underlying asset such as ETH. And similar to a CDP, VSSS's unstablecoin offers leveraged exposure to said underlying asset. But, unlike MakerDAO's CDPs, VSSS's unstablecoins are fungible just like any other token. They're liquid and can be bought or sold on exchanges with little hastle or premiums.
  
### Equivalence to MakerDAO
Lets walk through some common use cases to demostrate the equivalence to MakerDAO. For simplicity, we'll assume the VSSS is collateralized at a ratio of 1.5, the same as MakerDAO.

#### Maximum leverage
We want to leverage our 1 ETH. The maximum we can achieve in either system is 3x (though in VSSS this varies).

In MakerDAO, we need to open a CDP by locking up our 1 ETH. This allows us to borrow DAI which we can sell for .66 ETH, putting us at a leverage ratio of 1.6.

To achieve the same result in VSSS, we simply buy .33 ETH worth of the unstablecoin and hold onto our remaining .66 ETH.

In MakerDAO, if we want more leverage we can repeat the above process with our .66 ETH, leaving us with .44 ETH and another CDP. We can keep doing this until we get close to the maximum 3x leverage. At this point we'll have multiple CDPs we need to maintain to avoid liquidations and their resulting fees.

In VSSS we just buy 1 ETH worth of unstablecoins. This will put us at 3x leverage with nothing to worry about but a downward price swing 😎 😬.

### Borrowing
MakerDAO allows for borrowing against ...TODO

### Divergence From MakerDAO
#### Better Stability with a Variable Collateralization Ratio
VSSS's stablecoin should achieve greater stability than MakerDAO's DAI by allowing the collateralization ratio to vary with market forces.  
  
DAI has maintained its peg well for the vast majority of its existence, but durring a sharp drop in ETH price in March 2020, DAI deviated from its peg by over 20%. I believe a hard collateralization ratio was at least partially to blame for the extreme deviation. Burning mass quantities of DAI through CDP liquidations and deleveraging caused demand for DAI to outstrip supply.
  
VSSS always buys back (and burns) its stablecoins at a rate such that the stablecoin exactly holds its peg. To do so at any greater or lesser rate would, by the law of supply and demand, break the peg. This is achieved very simply: users can sell their stablecoins back to the VSSS to be burned at any time for exactly the peg amount. They can also mint new stablecoins for the peg amount.

A high collateralization ratio has its merits, but it's not worth sacrificing stability for. And breaking the peg in a positive direction is not any better than breaking it in a negative direction.

#### No Interest Rate or Fees
Unlike MakerDAO, VSSS doesn't have a DAO that siphons value out of the system through interest rates or liquidation fees.  
The VSSS is much simpler than MakerDAO, requiring no external services or auction mechanisms. This removes the need for even necessary fees.

#### Single Collateral Type Per System
DAI is collateralized with a mix of assets, including ETH, BAT, and USDC. Having a diverse porfolio of collateral assets mitigates risk of the system becoming undercollateralized.  
Each VSSS is collateralized with only one asset, but multliple VSSSs will be deployed, each with its own collateral. This allows the trader a choice in the types and ratios of the collateral underlying their hedge. Alternatively, a blended collateral contract is planned to mix multiple collateral types into one, allowing for a multi-collateral stablecoin.

## Possible Attack Vectors
### Frontrunning
A successful frontrunning attack could steal gains from or magnify losses of honest participants, so it's imperative that it's never possible.   
   
### Frontrunning Price Oracle Updates
This involves an attacker watching the mempool for a price oracle update then submitting a buy or sell transaction infront of it to make a risk-free profit from the price change. The Swap contract prevents this by enforcing a maximum allowed priority fee on all buy or sell transactions, preventing the attacker from setting a high enough priority fee to get his transaction in front of the price oracle update transaction. This works as long as the max allowed priority fee is less than the price oracle update transaction's priority fee, which should always be the case.   
   
### Soft Frontrunning
In theory it's possible for an attacker to predict a price orace update before the transaction even enters the mempool by looking at off-chain data such as prices on centralized exchanges. Trading on this advanced price knowledge is sometimes called "soft frontrunning", and VSSS has two lines of defence against it. First, a low enough priority fee limit will add a delay to any buy or sell transactions, giving the price oracle time to update. This works as long as the network is at least somewhat congested (i.e. as long as blocks are being filled). Second, every buy or sell has an associated fee that makes a price change of a given amount unprofitable. If, for example, the price change tolerance were set to 1%, the price would need to change by more than 1% for gains to be greater than the trade's fee.


## Behavior in event of undercollateralization
The remaining collateral is split among fixed-leg token holders. Floating-leg tokens can't be minted or burned. Fixed-leg tokens can be minted or burned for [total collateral] / [fixed-leg total supply]

Open question: what's the value of the floating-leg tokens?
  - they can't be redeemed for any collateral, but there's a chance the price comes back up and they can be.
  - essentially they're "out of the money" but not worthless
  - They're worthless iff all fixed-leg holders burn their tokens and redeem the collateral
    - Are fixed-leg holders incentivized to do so?
      - is the value of the collaeral > the value of the token?
        - yes: has the same downside potential with less upside potential

### Alternative behaviors
#### Graceful default
- mostly implemented on another branch but decided against going this way

Ratchet down the target value of fixed-leg tokens when the price drops such that the collateralization ratio can never be < 1
pros:
  - Prevents having to redeploy the swap if it becomes undercollateralized, which also prevents having to redeploy any derivative swaps
   - derivative swaps are not necessary, most likey a bad idea
  - Penalizes fixed-leg holders for letting the swap become undercollateralized, helping prevent it from ever happening
  - Further incentivizes buying into floating-leg as collateralization approaches 1
cons:
  - Possibly less fair for fixed-leg holders. Of course they can always exit the position (which is what we want) so it's never really unfair
  - Fixed-leg would demand a higher interest rate, which isn't necessarily bad, possibly good as it acts as an automatic stabilizer
could be the way to go.
  - more catastrophic for fixed-leg holders if there's a default. BUT less so for floating-leg holders
  - more code when we could just redeploy. It's never supposed to happen anyway




# TODO
- update solidity version
- ? implement IArbToken https://github.com/OffchainLabs/token-bridge-contracts/blob/main/contracts/tokenbridge/arbitrum/IArbToken.sol
- look into using super cheap exp() function
- consolidate premium rates functions
- make sure not vulnerable to erc 777 reentry
  - just dont use ERC-777
- improve method names of Rates contract
- look into being erc-4626 compatible.
  - There doesn't seem to be a good way of doing it where both tokens are supported by the standard
- make tokens vote-able. Let token holders vote on interest rate/fees in the future.

# Similar projects
- USM: https://jacob-eliosoff.medium.com/whats-the-simplest-possible-decentralized-stablecoin-4a25262cf5e8
  - turns out this is pretty much the same project but there are some differences:
    - Has a minimum collateral ratio that disables funders' (i.e. floating-leg) withdrawls if below it
    - Doesn't have an interest rate mechanism
    - Fee calculations are very different. Almost like an AMM
- https://github.com/shortdoom/stablecoin-fun
  - based on OSM but has erc-4626 interface. Uses custom functions for volitile token, not ideal.

