There are two tokens, a stablecoin and an unstablecoin, both collateralized with the same underlying asset. The stablecoin maintains a peg to a target asset, for example USD, via a price feed. Conversely, the unstablecoin offeres leveraged exposure to the underlying asset. Essentially, stablecoin holders are forfeiting their potential gains to unstablecoin holders in exchange for taking on their downside risk.

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
