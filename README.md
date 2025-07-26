# Renewable Energy Certificate Trading Platform

A comprehensive blockchain-based platform for tracking, verifying, and trading renewable energy certificates using Stacks smart contracts.

## Overview

This platform consists of five interconnected smart contracts that manage the entire lifecycle of renewable energy production, verification, and carbon credit generation:

1. **Solar Panel Performance Verification** - Tracks and verifies energy generation from distributed solar installations
2. **Wind Farm Output Monitoring** - Validates renewable energy production from wind installations
3. **Grid Integration Optimization** - Manages renewable energy integration with existing power infrastructure
4. **Energy Storage Coordination** - Optimizes battery storage systems to balance renewable energy supply
5. **Carbon Credit Generation** - Converts verified renewable energy production into tradeable carbon credits

## Key Features

### Solar Panel Performance Verification
- Register solar panel installations with capacity and location data
- Record daily energy generation readings
- Verify performance against expected output
- Calculate efficiency ratings and performance metrics

### Wind Farm Output Monitoring
- Track wind farm installations and turbine specifications
- Monitor real-time energy production data
- Validate output against weather conditions
- Generate performance certificates

### Grid Integration Optimization
- Manage renewable energy feed into the grid
- Track grid stability metrics
- Optimize energy distribution
- Monitor integration efficiency

### Energy Storage Coordination
- Register battery storage systems
- Track charge/discharge cycles
- Optimize storage allocation
- Balance supply and demand

### Carbon Credit Generation
- Convert verified renewable energy into carbon credits
- Track credit ownership and transfers
- Manage credit marketplace
- Ensure compliance with standards

## Contract Architecture

Each contract maintains its own state while providing interfaces for cross-contract data sharing:

- **Data Integrity**: All energy production data is cryptographically verified
- **Transparency**: Public visibility of all renewable energy metrics
- **Traceability**: Complete audit trail from energy generation to carbon credits
- **Scalability**: Modular design supports additional renewable energy sources

## Getting Started

### Prerequisites
- Clarinet CLI installed
- Node.js and npm
- Stacks wallet for testing

### Installation

\`\`\`bash
git clone <repository-url>
cd renewable-energy-trading
npm install
clarinet check
\`\`\`

### Running Tests

\`\`\`bash
npm test
\`\`\`

### Deployment

\`\`\`bash
clarinet deploy --testnet
\`\`\`

## Usage Examples

### Registering a Solar Installation

\`\`\`clarity
(contract-call? .solar-verification register-installation
u1000 ;; capacity in watts
"residential" ;; installation type
{ lat: 40.7128, lng: -74.0060 } ;; location
)
\`\`\`

### Recording Energy Generation

\`\`\`clarity
(contract-call? .solar-verification record-generation
u1 ;; installation id
u850 ;; energy generated in wh
u1640995200 ;; timestamp
)
\`\`\`

### Generating Carbon Credits

\`\`\`clarity
(contract-call? .carbon-credits generate-credits
u1 ;; source installation
u1000 ;; verified energy amount
"solar" ;; energy source type
)
\`\`\`

## API Reference

### Solar Verification Contract
- \`register-installation\` - Register new solar installation
- \`record-generation\` - Record energy generation data
- \`verify-performance\` - Verify installation performance
- \`get-installation-data\` - Retrieve installation information

### Wind Farm Monitoring Contract
- \`register-wind-farm\` - Register wind farm installation
- \`record-wind-generation\` - Record wind energy production
- \`validate-output\` - Validate production against conditions
- \`get-farm-metrics\` - Get performance metrics

### Grid Integration Contract
- \`register-grid-connection\` - Register grid connection point
- \`record-grid-feed\` - Record energy fed to grid
- \`optimize-distribution\` - Optimize energy distribution
- \`get-grid-status\` - Get current grid status

### Energy Storage Contract
- \`register-storage-system\` - Register battery storage
- \`record-storage-cycle\` - Record charge/discharge cycle
- \`optimize-storage\` - Optimize storage allocation
- \`get-storage-metrics\` - Get storage performance data

### Carbon Credits Contract
- \`generate-credits\` - Generate carbon credits from verified energy
- \`transfer-credits\` - Transfer credits between parties
- \`retire-credits\` - Retire credits for compliance
- \`get-credit-balance\` - Get credit balance for address

## Testing

The platform includes comprehensive tests covering:
- Contract deployment and initialization
- Energy generation recording and verification
- Grid integration scenarios
- Storage optimization algorithms
- Carbon credit generation and trading

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License - see LICENSE file for details

## Support

For technical support or questions, please open an issue in the repository.
