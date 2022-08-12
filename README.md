# Volatility Swap Stablecoin System
Mint synthetic assets and crypto derivatives
VSSS has two product offerings, a stablecoin and an unstable (i.e. leveraged) coin.  
  
Both tokens are collateralized with the same underlying asset. The stablecoin maintains a peg to a target asset, for example USD, via a price feed. Conversely, the unstablecoin offeres leveraged exposure to the underlying asset.

Essentially, it's an equity swap contract with tokenized fixed and floating legs, with payments and collateral in the reference asset.

# How It Works
Each Swap contract creates two synthetic assets whose values are determined by a price feed and backed by an underlying asset. Either synthetic asset can be minted or burned on-demand by depositing/withdrawing some of the underlying asset into/out of the Swap contract. For example, in an ETH/USD contract, you can deposit ETH to mint either synthetic USD or leveraged ETH, or you can withdraw ETH by burning synthetic USD or leveraged ETH.




## Properties of the system
L = leverage of the unstable (i.e. leveraged) coin  
R = collateralization ratio  
C = value of all locked collateral  
S = value of the total supply of the stablecoin  

where R = C/S

L varies with R such that the following is always true:

    
| L = R / (R - 1) |
| --------------- |
  
  
<img src="https://user-images.githubusercontent.com/13501607/150663503-7f72bbd7-2fb9-46fb-9ca5-0dc333cd9ddb.png" width="50%" height="50%">

  
- Market forces determine R and keep it above 1:  
  - As R falls closer to 1:  
    - L increases asymptotically toward infinity, increasing demand for the unstablecoin. R rises again as unstablecoins are bought.  
    - Risk of the peg breaking becomes greater, decreasing demand for the stablecoin. R rises again as stablecoins are sold.  


# Fees
All fees are used to serve cryptoeconomic goals such as maintaining a target collateralization ratio. They are taken from some participants and given to others. They don't go to a DAO. 

## One-time Fees
Every buy (mint) or sell (burn) has an associated fee that's proportional to the value of the trade. All proceeds from fees are put into the floating-leg pool, meaning they're given to floating-leg token holders.   
The fees have 3 main purposes. They:   
    1. serve as a last line of defence against soft frontrunning
    2. provide a way for fixed-leg holders to pay floating-leg holders without having to set a negative interest rate
    3. signal a minimum-intended time horizon for those buying in to either leg of the swap

## Interest Rate
Interest payments are made from floating-leg holders to fixed-leg holders on an hourly basis. Each swap contract has its own variable interest rate, used to target a collateralization ratio by changing the relative demand for fixed- and floating-leg tokens. Interest payments are automatically reinvested.

future: use PID controller design to adjust interest rate to maintain target collateralization ratio.


## The MakerDAO Killer
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

# Possible Attack Vectors
## Frontrunning
A successful frontrunning attack could steal gains from or magnify losses of honest participants, so it's imperative that it's never possible.   
   
## Frontrunning Price Oracle Updates
This involves an attacker watching the mempool for a price oracle update then submitting a buy or sell transaction infront of it to make a risk-free profit from the price change. The Swap contract prevents this by enforcing a maximum allowed priority fee on all buy or sell transactions, preventing the attacker from setting a high enough priority fee to get his transaction in front of the price oracle update transaction. This works as long as the max allowed priority fee is less than the price oracle update transaction's priority fee, which should always be the case.   
   
## Soft Frontrunning
In theory it's possible for an attacker to predict a price orace update before the transaction even enters the mempool by looking at off-chain data such as prices on centralized exchanges. Trading on this advanced price knowledge is sometimes called "soft frontrunning", and VSSS has two lines of defence against it. First, a low enough priority fee limit will add a delay to any buy or sell transactions, giving the price oracle time to update. This works as long as the network is at least somewhat congested (i.e. as long as blocks are being filled). Second, every buy or sell has an associated fee that makes a price change of a given amount unprofitable. If, for example, the price change tolerance were set to 1%, the price would need to change by more than 1% for gains to be greater than the trade's fee.   


# Composability (Derivatives legos)
Use synthetic assets as the underlying asset for other swap contracts. i.e. collateralize synthetic assets with other synthetic assets. The token outputs from one swap contract can be used as inputs to others.    

Is it a bad idea?     
  - It isn't necessary since a single contract can track any asset or index and use any ERC20 as collateral
  - adds friction (time and gas costs) to entering/exiting positions
  - undercollateralization of dependant contracts adds complications
  - creates redundant synthetic tokens e.g. sUSD/ETH's resulting sETH
    - you can just hold ETH, or have the cashflow equivalent of sETH by holding lETH and ETH/hETH's hETH

## Shorting
E.g. use the sUSD created from the ETH/USD swap to create an sUSD/ETH swap
Adds shorting without writing any more code. cool!
leverage is 1 - lETH leverage. So if ETH/USD is 150% collateralized and thus lETH offers 3x leverage, our short has 1 - 3 = -2x leverage

## Squaring
E.g. use the lETH created from the ETH/USD swap to create a lETH/USD swap
or should it be a lETH/sUSD swap? Would be safe to do since it will always undercollateralize before sUSD. Shouldn't make much difference tho, 
It's a swap squared (ETH/USD)^2
Gives more leverage
open question: Is this better in any way than just deploying another ETH/USD swap with a lower collateralization ratio?
  - takes the same price change to cause undercollateralization. So that's not any better
  - costs more gas to enter into position. So that's worse
  - lETH/USD swap TVL all goes to overcollateralizing ETH/USD swap: not sure if this is better
  - interest payments would go from l2ETH -> l1ETH -> s1USD
Probs not useful initaially but could do if degens want MOAR LEVERAGE withought increaseing risk of default for existing holders

# Multi-collateral Stablecoin
Create an sUSD/USD swap where sUSD is a blend of different synthetic USD assests, such as ones with different collateral types or collateralization ratios.
For example, combine esUSD (ETH-collateralized Synthetic USD) and lsUSD (LINK-collateralized Synthetic USD) into a single sUSD, and use that as the underlying asset in a sUSD/USD swap.
The ssUSD created from the sUSD/USD swap will be able to hold its peg even if lsUSD or esUSD (and thus sUSD) lose their pegs.
Those taking the other side of the trade are taking on the risk of sUSD losing its peg but are being compensated with interest payments. 


# Behavior in event of undercollateralization
The remaining collateral is split among fixed-leg token holders. Floating-leg tokens can't be minted or burned. Fixed-leg tokens can be minted or burned for [total collateral] / [fixed-leg total supply]

Open question: what's the value of the floating-leg tokens?
  - they can't be redeemed for any collateral, but there's a chance the price comes back up and they can be.
  - essentially they're "out of the money" but not worthless
  - They're worthless iff all fixed-leg holders burn their tokens and redeem the collateral
    - Are fixed-leg holders incentivized to do so?
      - is the value of the collaeral > the value of the token?
        - yes: has the same downside potential with less upside potential

## Alternative behaviors
### Graceful default
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
- add `to` address parameter to buy and sell functions
- look into using super cheap exp() function
- consolidate premium rates functions
- make sure not vulnerable to erc 777 reentry
  - just dont use ERC-777
- make interest rate payments at times such that all swap contracts are syncronized (e.g. every perfect multiple of 3600 secs since unix epoch)
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

