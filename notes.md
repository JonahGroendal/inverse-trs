### Squaring
E.g. use the xETHᵘˢᵈ created from the ETH/USD swap to create a xETHᵘˢᵈ/USD swap
Creates USDˣᵉᵗʰ and xETH²ᵘˢᵈ
Gives more leverage
open question: Is this better in any way than just deploying another ETH/USD swap with a lower collateralization ratio?
  - takes the same price change to cause undercollateralization. So that's not any better
  - costs more gas to enter into position. So that's worse
  - lETH/USD swap TVL all goes to overcollateralizing ETH/USD swap: not sure if this is better
  - interest payments would go from l2ETH -> l1ETH -> s1USD

### Shorting
leverage = 1 - xETHᵘˢᵈ leverage
So if ETH/USD is 150% collateralized and thus xETHᵘˢᵈ offers 3x leverage, our short has 1 - 3 = -2x leverage

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

# Similar projects
- USM: https://jacob-eliosoff.medium.com/whats-the-simplest-possible-decentralized-stablecoin-4a25262cf5e8
  - turns out this is pretty much the same project but there are some differences:
    - Has a minimum collateral ratio that disables funders' (i.e. protection sellers) withdrawls if below it
    - Doesn't have an interest rate mechanism
    - Fee calculations are very different. Almost like an AMM
- https://github.com/shortdoom/stablecoin-fun
  - based on OSM but has erc-4626 interface. Uses custom functions for volitile token, not ideal.



  # TODO
- update solidity version
- ? implement IArbToken https://github.com/OffchainLabs/token-bridge-contracts/blob/main/contracts/tokenbridge/arbitrum/IArbToken.sol
  - can upgrade Token contract later
- add info about automatic, continuous liquidating
- add info on how collateralization ratio is maintained
- look into creating variation of contract that makes stablecoin side short by requiring only a portion of it value be depositied to mint. Model after inverse perpetual futures
