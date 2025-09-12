# RideLink 🚗

A decentralized ride-sharing escrow system built on Stacks blockchain using Clarity smart contracts with integrated dispute resolution and dynamic surge pricing.

## Overview

RideLink enables secure, trustless ride-sharing transactions between riders and drivers through smart contract escrow. The platform ensures fair payment processing while maintaining transparency and security for all parties involved. Now featuring a comprehensive dispute resolution system with staked mediators and intelligent dynamic pricing based on real-time supply and demand metrics.

## Features

- **Secure Escrow System**: Funds are held in smart contract until ride completion
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

## Smart Contract Functions

### Public Functions

#### Core Ride Functions
- `request-ride`: Create a new ride request with dynamic pricing applied
- `accept-ride`: Driver accepts an available ride request (updates availability)
- `start-ride`: Driver starts the ride journey
- `complete-ride`: Driver completes ride and triggers payment
- `rate-driver`: Rider rates driver after ride completion
- `cancel-ride`: Cancel ride request with automatic availability updates

#### Driver Availability Management
- `register-driver-availability`: Register driver as available in specific location
- `unregister-driver-availability`: Remove driver from available pool

#### Dispute Resolution Functions
- `register-mediator`: Register as a mediator with required stake
- `unregister-mediator`: Unregister as mediator and withdraw stake (after cooldown)
- `raise-dispute`: Rider or driver can raise a dispute for a ride
- `vote-on-dispute`: Mediators vote on dispute resolution
- `finalize-dispute`: Execute dispute resolution after voting period

#### Admin Functions
- `update-surge-parameters`: Adjust surge pricing thresholds and limits (owner only)

### Read-Only Functions

#### Core Read Functions
- `get-ride`: Retrieve ride details by ID (includes surge pricing data)
- `get-driver-rating`: Get driver's average rating
- `get-escrow-balance`: Check escrowed amount for a ride
- `get-platform-fee`: Current platform fee percentage
- `get-total-rides`: Total number of rides created

#### Dynamic Pricing Read Functions
- `get-current-surge`: Get real-time surge multiplier for a location
- `get-location-demand`: Get demand metrics for specific location
- `estimate-fare`: Calculate total cost including surge and platform fees
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

### For Riders
1. Call `estimate-fare` to get current pricing with surge
2. Call `request-ride` with pickup location, destination, and base fare
3. System automatically applies current surge multiplier
4. Wait for driver to accept via `accept-ride`
5. Track ride progress through status updates
6. Rate driver after completion using `rate-driver`
7. If issues arise, use `raise-dispute` to initiate dispute resolution

### For Drivers
1. Register availability using `register-driver-availability` for specific locations
2. Monitor available rides using `get-ride` and `get-current-surge`
3. Accept rides using `accept-ride` (automatically removes from available pool)
4. Start ride with `start-ride`
5. Complete ride and receive payment via `complete-ride`
6. Re-register availability or move to new location
7. If issues arise, use `raise-dispute` to initiate dispute resolution

### For Mediators
1. Register as mediator using `register-mediator` with required stake
2. Monitor active disputes
3. Vote on disputes using `vote-on-dispute`
4. Earn rewards for accurate dispute resolution
5. Maintain stake to remain active in the system

## Dynamic Pricing Examples

### High Demand Scenario
```
Location: "Downtown"
Active Requests: 15
Available Drivers: 2
Demand Ratio: 7.5
Surge Multiplier: 2.75x
Base Fare: 1000 STX → Final Fare: 2750 STX
```

### Low Demand Scenario
```
Location: "Suburbs"
Active Requests: 2
Available Drivers: 5
Demand Ratio: 0.4
Surge Multiplier: 1.0x (No Surge)
Base Fare: 1000 STX → Final Fare: 1000 STX
```

## Dispute Resolution Process

1. **Dispute Initiation**: Either party can raise a dispute within 24 hours of ride completion
2. **Mediator Assignment**: Active mediators can vote on the dispute
3. **Voting Period**: 48-hour window for mediators to cast votes
4. **Resolution**: Majority vote determines outcome (refund to rider vs payment to driver)
5. **Stake Distribution**: Winning voters share rewards, losing voters lose portion of stake

## Contract Architecture

The contract uses several key data structures:
- `rides`: Enhanced ride information with surge pricing data
- `driver-ratings`: Driver reputation system
- `escrow-balances`: Secure fund holding
- `location-demand`: Real-time supply/demand tracking per location
- `surge-history`: Historical pricing data for analytics
- `disputes`: Dispute information and voting records
- `mediators`: Registered mediator information and stakes
- `dispute-votes`: Individual mediator votes on disputes

## Security Features

- Owner-only administrative functions
- Status-based function access control
- Secure fund escrow and release
- Input validation and error handling
- Stake-based mediator incentives
- Time-locked dispute resolution
- Consensus-based dispute outcomes
- Automated surge pricing bounds checking
- Location-based demand validation

## Dynamic Pricing Parameters

- **Base Surge Multiplier**: 1.0x (100 basis points)
- **Maximum Surge Multiplier**: 5.0x (500 basis points)
- **High Demand Threshold**: 10 requests per driver
- **Low Demand Threshold**: 3 requests per driver
- **Surge Calculation Period**: 1 hour (6 blocks)

## Dispute Resolution Parameters

- **Minimum Mediator Stake**: 1000 STX tokens
- **Dispute Window**: 24 hours after ride completion
- **Voting Period**: 48 hours for mediator voting
- **Mediator Cooldown**: 7 days after unregistering
- **Stake Slash Rate**: 10% for incorrect votes

## API Examples

### Estimating Fare with Surge
```clarity
;; Get current surge pricing for downtown area
(contract-call? .ridelink get-current-surge "Downtown Manhattan")
;; Returns: {location: "Downtown Manhattan", surge-multiplier: u250, multiplier-decimal: u2}

;; Estimate total cost including platform fees
(contract-call? .ridelink estimate-fare "Downtown Manhattan" u1000000)
;; Returns: {base-fare: u1000000, surge-multiplier: u250, final-fare: u2500000, platform-fee: u12500, total-cost: u2512500}
```

### Checking Location Demand
```clarity
;; Get real-time demand metrics
(contract-call? .ridelink get-location-demand "Airport")
;; Returns: {location: "Airport", active-requests: u8, available-drivers: u3, demand-ratio: u2, last-updated: u12345}
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
