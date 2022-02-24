# Volatility Swap Stablecoin System
VSSS has two product offerings, a stablecoin and an unstable (i.e. leveraged) coin.  
  
Both tokens are collateralized with the same underlying asset. The stablecoin maintains a peg to a target asset, for example USD, via a price feed. Conversely, the unstablecoin offeres leveraged exposure to the underlying asset. It's essentially an equity swap contract with tokenized fixed and floating legs.

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
Each VSSS is collateralized with only one asset, but multliple VSSSs will be deployed, each with its own collateral. This allows the trader a choice in the types and ratios of the collateral underlying their hedge. A blended stablecoin contract is planned to mix multiple VSSS stablecoins into one.
