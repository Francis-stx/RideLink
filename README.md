# RideLink 🚗

A decentralized ride-sharing escrow system built on Stacks blockchain using Clarity smart contracts with integrated dispute resolution, dynamic surge pricing, and multi-token payment support.

## Overview

RideLink enables secure, trustless ride-sharing transactions between riders and drivers through smart contract escrow. The platform ensures fair payment processing while maintaining transparency and security for all parties involved. Now featuring a comprehensive dispute resolution system with staked mediators, intelligent dynamic pricing based on real-time supply and demand metrics, and support for multiple payment tokens including STX and SIP-010 tokens.

## Features

- **Secure Escrow System**: Funds are held in smart contract until ride completion
- **Multi-Token Payment Support**: Accept STX and various SIP-010 tokens for ride payments
- **Dynamic Token Pricing**: Real-time exchange rate management for supported tokens
- **Dynamic Surge Pricing**: Intelligent fare adjustment based on real-time supply and demand
- **Rating System**: Drivers can be rated by riders to build reputation
- **Flexible Cancellation**: Both parties can cancel rides under appropriate conditions
- **Platform Fee Management**: Automated fee collection for platform sustainability
- **Transparent Transactions**: All ride data stored on-chain for transparency
- **Dispute Resolution System**: Staked mediators can resolve conflicts between riders and drivers
- **Mediator Staking**: Arbitrators must stake tokens to participate in dispute resolution
- **Multi-Party Voting**: Disputes resolved through mediator consensus with stake-based incentives
- **Location-Based Analytics**: Real-time tracking of demand and supply metrics per location
- **Surge History Tracking**: Historical pricing data for analytics and optimization
- **Token Analytics**: Track payment volume and usage statistics per token

## Multi-Token Payment System

### Supported Payment Options
- **STX**: Native Stacks token (default)
- **SIP-010 Tokens**: Any compliant fungible token
- **Dynamic Pricing**: Automatic conversion rates relative to STX
- **Real-time Updates**: Token prices can be adjusted by platform owner

### Token Management Features
- Add new payment tokens with custom exchange rates
- Update token prices based on market conditions
- Deactivate/reactivate tokens as needed
- Track payment volume and usage per token
- Automatic conversion calculations for fare estimation

### Payment Flow
1. Platform owner adds supported tokens with STX-relative pricing
2. Riders select preferred payment token when requesting rides
3. Smart contract automatically calculates fare in chosen token
4. Escrow holds tokens until ride completion or dispute resolution
5. Drivers receive payment in the same token used by rider

## Dynamic Pricing Algorithm

The platform implements a sophisticated surge pricing mechanism that adjusts fares based on:

### Supply & Demand Metrics
- **Active Requests**: Number of pending ride requests in a location
- **Available Drivers**: Number of drivers ready to accept rides
- **Demand Ratio**: Real-time calculation of requests vs available drivers

### Surge Multipliers
- **Base Rate**: 1.0x (no surge)
- **Low Demand**: ≤3 requests per driver (no surge)
- **Medium Demand**: 3-10 requests per driver (moderate surge)
- **High Demand**: ≥10 requests per driver (maximum surge up to 5.0x)

### Dynamic Adjustments
- Real-time pricing updates based on location-specific metrics
- Automatic driver availability tracking
- Historical surge data for pattern analysis
- Token-specific fare calculations with exchange rate conversions

## Smart Contract Functions

### Token Management Functions (Owner Only)
- `add-supported-token`: Add a new payment token with exchange rate
- `update-token-price`: Update token's STX exchange rate
- `deactivate-token`: Temporarily disable a payment token
- `reactivate-token`: Re-enable a previously deactivated token

### Public Functions

#### Core Ride Functions
- `request-ride`: Create a new ride request with multi-token support and dynamic pricing
- `accept-ride`: Driver accepts an available ride request (updates availability)
- `start-ride`: Driver starts the ride journey
- `complete-ride`: Driver completes ride and triggers payment in selected token
- `rate-driver`: Rider rates driver after ride completion
- `cancel-ride`: Cancel ride request with automatic refund in original token

#### Driver Availability Management
- `register-driver-availability`: Register driver as available in specific location
- `unregister-driver-availability`: Remove driver from available pool

#### Dispute Resolution Functions
- `register-mediator`: Register as a mediator with required stake
- `unregister-mediator`: Unregister as mediator and withdraw stake (after cooldown)
- `raise-dispute`: Rider or driver can raise a dispute for a ride
- `vote-on-dispute`: Mediators vote on dispute resolution
- `finalize-dispute`: Execute dispute resolution with multi-token refunds after voting period

#### Admin Functions
- `update-surge-parameters`: Adjust surge pricing thresholds and limits (owner only)

### Read-Only Functions

#### Token Read Functions
- `get-token-info`: Get details about a supported token
- `is-token-supported`: Check if a token is active for payments
- `get-token-stats`: Get usage statistics for a token
- `get-token-volume`: Get total payment volume for a token
- `calculate-fare-in-token`: Calculate ride cost in specific token including surge pricing

#### Core Read Functions
- `get-ride`: Retrieve ride details by ID (includes token and surge pricing data)
- `get-driver-rating`: Get driver's average rating
- `get-escrow-balance`: Check escrowed amount and token for a ride
- `get-platform-fee`: Current platform fee percentage
- `get-total-rides`: Total number of rides created

#### Dynamic Pricing Read Functions
- `get-current-surge-pricing`: Get real-time surge multiplier for a location
- `get-location-metrics`: Get demand metrics for specific location
- `get-surge-history`: Historical surge data for analytics
- `get-surge-parameters`: Current surge pricing configuration

#### Dispute Read Functions
- `get-dispute`: Get dispute details by ride ID
- `get-mediator`: Get mediator information
- `is-mediator-active`: Check if a mediator is currently active
- `get-mediator-stake`: Get current stake amount for a mediator
- `get-dispute-votes`: Get vote count for a specific dispute

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/ridelink.git

# Install Clarinet
curl -L https://github.com/hirosystems/clarinet/releases/latest/download/clarinet-linux-x64.tar.gz | tar xvz

# Check contract
clarinet check

# Run tests
clarinet test
```

## Usage

### For Platform Owners
1. Deploy contract and add supported payment tokens using `add-supported-token`
2. Set initial STX exchange rates for each token
3. Monitor token usage with `get-token-stats`
4. Update token prices as needed using `update-token-price`
5. Manage token availability with `deactivate-token` and `reactivate-token`

### For Riders
1. Check supported tokens using `is-token-supported`
2. Calculate fare in preferred token using `calculate-fare-in-token`
3. Call `request-ride` with pickup location, destination, base fare, and chosen payment token
4. System automatically applies current surge multiplier and converts to token amount
5. Wait for driver to accept via `accept-ride`
6. Track ride progress through status updates
7. Rate driver after completion using `rate-driver`
8. If issues arise, use `raise-dispute` to initiate dispute resolution

### For Drivers
1. Register availability using `register-driver-availability` for specific locations
2. Monitor available rides using `get-ride` and `get-current-surge-pricing`
3. Accept rides using `accept-ride` (automatically removes from available pool)
4. Start ride with `start-ride`
5. Complete ride and receive payment in rider's chosen token via `complete-ride`
6. Re-register availability or move to new location
7. If issues arise, use `raise-dispute` to initiate dispute resolution

### For Mediators
1. Register as mediator using `register-mediator` with required stake
2. Monitor active disputes
3. Vote on disputes using `vote-on-dispute`
4. Earn rewards for accurate dispute resolution
5. Maintain stake to remain active in the system

## Multi-Token Payment Examples

### Adding a New Token
```clarity
;; Platform owner adds USDA stablecoin with 1:1 STX rate
(contract-call? .ridelink add-supported-token .usda-token u2 u10000)
;; token-type: u2 (SIP-010), price: u10000 (1:1 ratio in basis points)

;; Add another token with 2:1 STX rate (1 token = 2 STX)
(contract-call? .ridelink add-supported-token .premium-token u2 u20000)
```

### Requesting Ride with Different Tokens
```clarity
;; Request ride paying with STX
(contract-call? .ridelink request-ride "Downtown" "Airport" u1000000 .stx-token)

;; Request ride paying with USDA
(contract-call? .ridelink request-ride "Downtown" "Airport" u1000000 .usda-token)

;; Request ride paying with premium token (costs less tokens due to 2:1 rate)
(contract-call? .ridelink request-ride "Downtown" "Airport" u1000000 .premium-token)
```

### Calculating Fares in Different Tokens
```clarity
;; Calculate fare in STX with surge pricing
(contract-call? .ridelink calculate-fare-in-token u1000000 "Downtown" .stx-token)
;; Returns: {base-fare, surge-multiplier, final-fare-stx, platform-fee, total-stx, estimated-token-amount}

;; Calculate same ride in USDA
(contract-call? .ridelink calculate-fare-in-token u1000000 "Downtown" .usda-token)
;; Returns converted amount based on token's exchange rate
```

### Checking Token Information
```clarity
;; Check if token is supported
(contract-call? .ridelink is-token-supported .usda-token)
;; Returns: true/false

;; Get token details
(contract-call? .ridelink get-token-info .usda-token)
;; Returns: {is-active, token-type, price-in-stx, added-at, deactivated-at}

;; Get token usage statistics
(contract-call? .ridelink get-token-stats .usda-token)
;; Returns: {total-rides, total-volume, last-used}
```

## Dynamic Pricing Examples

### High Demand Scenario
```
Location: "Downtown"
Active Requests: 15
Available Drivers: 2
Demand Ratio: 7.5
Surge Multiplier: 2.75x
Base Fare: 1000 STX → Final Fare: 2750 STX

With USDA (1:1): 2750 USDA
With Premium Token (2:1): 1375 Premium Tokens
```

### Low Demand Scenario
```
Location: "Suburbs"
Active Requests: 2
Available Drivers: 5
Demand Ratio: 0.4
Surge Multiplier: 1.0x (No Surge)
Base Fare: 1000 STX → Final Fare: 1000 STX

With USDA (1:1): 1000 USDA
With Premium Token (2:1): 500 Premium Tokens
```

## Dispute Resolution Process

1. **Dispute Initiation**: Either party can raise a dispute within 24 hours of ride completion
2. **Mediator Assignment**: Active mediators can vote on the dispute
3. **Voting Period**: 48-hour window for mediators to cast votes
4. **Resolution**: Majority vote determines outcome (refund to rider vs payment to driver)
5. **Token Refund/Payment**: Funds distributed in original payment token based on resolution
6. **Stake Distribution**: Winning voters share rewards, losing voters lose portion of stake

## Contract Architecture

The contract uses several key data structures:
- `rides`: Enhanced ride information with token and surge pricing data
- `driver-ratings`: Driver reputation system
- `escrow-balances`: Secure fund holding with token type tracking
- `location-demand`: Real-time supply/demand tracking per location
- `surge-history`: Historical pricing data for analytics
- `supported-tokens`: Active payment tokens with exchange rates
- `token-stats`: Payment volume and usage statistics per token
- `disputes`: Dispute information and voting records
- `mediators`: Registered mediator information and stakes
- `dispute-votes`: Individual mediator votes on disputes

## Security Features

- Owner-only administrative functions
- Status-based function access control
- Secure fund escrow and release with multi-token support
- Input validation and error handling
- Token activation/deactivation controls
- Exchange rate validation and bounds checking
- Stake-based mediator incentives
- Time-locked dispute resolution
- Consensus-based dispute outcomes
- Automated surge pricing bounds checking
- Location-based demand validation
- Token transfer validation and error handling

## Dynamic Pricing Parameters

- **Base Surge Multiplier**: 1.0x (10000 basis points)
- **Maximum Surge Multiplier**: 5.0x (50000 basis points)
- **High Demand Threshold**: 5 active requests minimum
- **Low Supply Threshold**: 2 available drivers minimum
- **Surge Calculation Period**: Real-time per location

## Dispute Resolution Parameters

- **Minimum Mediator Stake**: 1000 STX tokens
- **Dispute Window**: 24 hours (144 blocks) after ride completion
- **Voting Period**: 48 hours (288 blocks) for mediator voting
- **Mediator Cooldown**: 7 days (1008 blocks) after unregistering
- **Stake Slash Rate**: 10% for incorrect votes

## Multi-Token Parameters

- **Token Type STX**: u1 (native token)
- **Token Type SIP-010**: u2 (fungible tokens)
- **Exchange Rate Format**: Basis points (10000 = 1:1 ratio)
- **Minimum Exchange Rate**: Greater than 0
- **Real-time Conversion**: Automatic fare calculation in any supported token

## Error Codes

- `u100`: Owner-only function
- `u101`: Resource not found
- `u102`: Unauthorized access
- `u103`: Invalid status
- `u104`: Insufficient funds
- `u105`: Resource already exists
- `u106`: Invalid rating
- `u107`: Dispute window closed
- `u108`: Dispute already exists
- `u109`: Voting period ended
- `u110`: Voting period still active
- `u111`: Already voted
- `u112`: Not a mediator
- `u113`: Mediator cooldown active
- `u114`: Invalid vote
- `u115`: Insufficient stake
- `u116`: Invalid multiplier
- `u117`: Invalid location
- `u118`: Token not supported
- `u119`: Token already supported
- `u120`: Token transfer failed
- `u121`: Invalid token price
- `u122`: Token not active

## API Examples

### Token Management
```clarity
;; Add USDA stablecoin
(contract-call? .ridelink add-supported-token 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token u2 u10000)

;; Update token price (owner only)
(contract-call? .ridelink update-token-price 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token u11000)

;; Check token support
(contract-call? .ridelink is-token-supported 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token)
```

### Fare Estimation with Multiple Tokens
```clarity
;; Estimate fare in STX
(contract-call? .ridelink calculate-fare-in-token u1000000 "Downtown Manhattan" 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.stx-token)

;; Estimate same ride in USDA
(contract-call? .ridelink calculate-fare-in-token u1000000 "Downtown Manhattan" 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token)
```

### Request Ride with Token Selection
```clarity
;; Request ride with STX
(contract-call? .ridelink request-ride "Airport" "Downtown" u2000000 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.stx-token)

;; Request ride with USDA
(contract-call? .ridelink request-ride "Airport" "Downtown" u2000000 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token)
```

### Token Analytics
```clarity
;; Get token statistics
(contract-call? .ridelink get-token-stats 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token)
;; Returns: {total-rides: u150, total-volume: u50000000, last-used: u12345}

;; Get token volume
(contract-call? .ridelink get-token-volume 'SP2C2YFP12AJZB4MABJBAJ55XECVS7E4PMMZ89YZR.usda-token)
;; Returns: (some u50000000)
```

## Benefits of Multi-Token Support

### For Riders
- **Payment Flexibility**: Choose preferred payment method
- **Stablecoin Option**: Avoid volatility with stablecoin payments
- **Cost Optimization**: Select token with favorable exchange rates
- **Transparent Pricing**: See exact costs in chosen token before confirming

### For Drivers
- **Diverse Income Streams**: Accept multiple payment types
- **Immediate Settlement**: Receive payment in same token as rider paid
- **Reduced Conversion Costs**: No need to manually convert tokens
- **Market Flexibility**: Benefit from various token economics

### For Platform
- **Broader User Base**: Attract users with different token preferences
- **Reduced Barriers**: Lower entry barriers with multiple payment options
- **Market Adaptability**: Adjust to changing token preferences
- **Competitive Advantage**: Stand out with flexible payment options
