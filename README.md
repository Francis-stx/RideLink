# RideLink 🚗

A decentralized ride-sharing escrow system built on Stacks blockchain using Clarity smart contracts.

## Overview

RideLink enables secure, trustless ride-sharing transactions between riders and drivers through smart contract escrow. The platform ensures fair payment processing while maintaining transparency and security for all parties involved.

## Features

- **Secure Escrow System**: Funds are held in smart contract until ride completion
- **Rating System**: Drivers can be rated by riders to build reputation
- **Flexible Cancellation**: Both parties can cancel rides under appropriate conditions
- **Platform Fee Management**: Automated fee collection for platform sustainability
- **Transparent Transactions**: All ride data stored on-chain for transparency

## Smart Contract Functions

### Public Functions

- `request-ride`: Create a new ride request with pickup/destination and fare
- `accept-ride`: Driver accepts an available ride request
- `start-ride`: Driver starts the ride journey
- `complete-ride`: Driver completes ride and triggers payment
- `rate-driver`: Rider rates driver after ride completion
- `cancel-ride`: Cancel ride request (conditions apply)

### Read-Only Functions

- `get-ride`: Retrieve ride details by ID
- `get-driver-rating`: Get driver's average rating
- `get-escrow-balance`: Check escrowed amount for a ride
- `get-platform-fee`: Current platform fee percentage
- `get-total-rides`: Total number of rides created

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

### For Drivers
1. Monitor available rides using `get-ride`
2. Accept rides using `accept-ride`
3. Start ride with `start-ride`
4. Complete ride and receive payment via `complete-ride`

## Contract Architecture

The contract uses several key data structures:
- `rides`: Main ride information mapping
- `driver-ratings`: Driver reputation system
- `escrow-balances`: Secure fund holding

## Security Features

- Owner-only administrative functions
- Status-based function access control
- Secure fund escrow and release
- Input validation and error handling

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request
