# Volatility Swap Stablecoin System
There are two tokens, a stablecoin and an unstablecoin, both collateralized with the same underlying asset. The stablecoin maintains a peg to a target asset, for example USD, via a price feed. Conversely, the unstablecoin offeres leveraged exposure to the underlying asset. Essentially, stablecoin holders are forfeiting their potential gains to unstablecoin holders in exchange for taking on their downside risk.

## Properties of the system
L = leverage of the unstable (i.e. leveraged) coin  
R = collateralization ratio  
C = value of all locked collateral  
S = value of the total supply of the stablecoin  

where R = C/S

L varies with R such that the following is always true:

    
| L = R / (R - 1) |
| --------------- |
  
  
- Market forces determine R and keep it above 1:  
  - As R falls closer to 1:  
    - L increases asymptotically toward infinity, increasing demand for the unstablecoin. R rises again as unstablecoins are bought.  
    - Risk of the peg breaking becomes greater, decreasing demand for the stablecoin. R rises again as stablecoins are sold.  


## The MakerDAO Killer
The products offered by VSSS are very similar to those of MakerDAO but require zero maintainence, have no fees and are easier to conceptualize. Similar to DAI, VSSS's stablecoin is overcollateralized with an underlying asset such as ETH. And similar to a CDP, VSSS's unstablecoin offers leveraged exposure to such an underlying asset. But, unlike a CDP, VSSS's unstablecoin is just a token like any other. It's fungable and highly liquid and, as such, can be bought and sold on exchanges with little hastle or premiums. It's also much simpler to dial in the exact amount of leverage you want.
  
### Equivalence to MakerDAO
Lets demostrate the equivalence to MakerDAO by considering some common use cases. For simplicity, we'll assume the VSSS is collateralized at a ratio of 1.5, the same as MakerDAO.
#### Maximum leverage
We start with 1 ETH. The maximum leverage we can achieve in either system is 3x (though in VSSS this varies).

In MakerDAO, we need to open a CDP by locking up our 1 ETH. This allows us to borrow DAI which we can sell for .66 ETH, putting us at a leverage ratio of 1.6.

To achieve the same result in VSSS, we simply buy .33 ETH worth of the unstablecoin and hold onto our remaining .66 ETH.

In MakerDAO, if we want more leverage we can repeat the above process with our .66 ETH, leaving us with .44 ETH and another CDP. We can keep doing this until we get close to the maximum 3x leverage. At this point we'll have multiple CDPs we need to maintain to avoid liquidations and their resulting fees.

In VSSS we just buy 1 ETH worth of unstablecoins. This will put us at 3x leverage with nothing to worry about but a downward price swing 😬.

