# RideLink 🚗

A decentralized ride-sharing escrow system built on Stacks blockchain using Clarity smart contracts with integrated dispute resolution.

## Overview

RideLink enables secure, trustless ride-sharing transactions between riders and drivers through smart contract escrow. The platform ensures fair payment processing while maintaining transparency and security for all parties involved. Now featuring a comprehensive dispute resolution system with staked mediators for handling ride conflicts.

## Features

- **Secure Escrow System**: Funds are held in smart contract until ride completion
- **Rating System**: Drivers can be rated by riders to build reputation
- **Flexible Cancellation**: Both parties can cancel rides under appropriate conditions
- **Platform Fee Management**: Automated fee collection for platform sustainability
- **Transparent Transactions**: All ride data stored on-chain for transparency
- **Dispute Resolution System**: Staked mediators can resolve conflicts between riders and drivers
- **Mediator Staking**: Arbitrators must stake tokens to participate in dispute resolution
- **Multi-Party Voting**: Disputes resolved through mediator consensus with stake-based incentives

## Smart Contract Functions

### Public Functions

#### Core Ride Functions
- `request-ride`: Create a new ride request with pickup/destination and fare
- `accept-ride`: Driver accepts an available ride request
- `start-ride`: Driver starts the ride journey
- `complete-ride`: Driver completes ride and triggers payment
- `rate-driver`: Rider rates driver after ride completion
- `cancel-ride`: Cancel ride request (conditions apply)

#### Dispute Resolution Functions
- `register-mediator`: Register as a mediator with required stake
- `unregister-mediator`: Unregister as mediator and withdraw stake (after cooldown)
- `raise-dispute`: Rider or driver can raise a dispute for a ride
- `vote-on-dispute`: Mediators vote on dispute resolution
- `finalize-dispute`: Execute dispute resolution after voting period

### Read-Only Functions

#### Core Read Functions
- `get-ride`: Retrieve ride details by ID
- `get-driver-rating`: Get driver's average rating
- `get-escrow-balance`: Check escrowed amount for a ride
- `get-platform-fee`: Current platform fee percentage
- `get-total-rides`: Total number of rides created

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
1. Call `request-ride` with pickup location, destination, and fare
2. Wait for driver to accept via `accept-ride`
3. Track ride progress through status updates
4. Rate driver after completion using `rate-driver`
5. If issues arise, use `raise-dispute` to initiate dispute resolution

### For Drivers
1. Monitor available rides using `get-ride`
2. Accept rides using `accept-ride`
3. Start ride with `start-ride`
4. Complete ride and receive payment via `complete-ride`
5. If issues arise, use `raise-dispute` to initiate dispute resolution

### For Mediators
1. Register as mediator using `register-mediator` with required stake
2. Monitor active disputes
3. Vote on disputes using `vote-on-dispute`
4. Earn rewards for accurate dispute resolution
5. Maintain stake to remain active in the system

## Dispute Resolution Process

1. **Dispute Initiation**: Either party can raise a dispute within 24 hours of ride completion
2. **Mediator Assignment**: Active mediators can vote on the dispute
3. **Voting Period**: 48-hour window for mediators to cast votes
4. **Resolution**: Majority vote determines outcome (refund to rider vs payment to driver)
5. **Stake Distribution**: Winning voters share rewards, losing voters lose portion of stake

## Contract Architecture

The contract uses several key data structures:
- `rides`: Main ride information mapping
- `driver-ratings`: Driver reputation system
- `escrow-balances`: Secure fund holding
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

## Dispute Resolution Parameters

- **Minimum Mediator Stake**: 1000 STX tokens
- **Dispute Window**: 24 hours after ride completion
- **Voting Period**: 48 hours for mediator voting
- **Mediator Cooldown**: 7 days after unregistering
- **Stake Slash Rate**: 10% for incorrect votes

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

MIT License - see LICENSE file for details