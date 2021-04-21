module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",     // Localhost (default: none)
      port: 7545,            // Standard Ethereum port (default: none)
      network_id: "97",       // Any network (default: none)
    },
  },
  compilers: {
    solc: {
      version: "0.6.12",    
      settings: {         
        optimizer: {
          enabled: true,
          runs: 999999
        },
        evmVersion: "istanbul"
      }
    }
  },
  db: {
    enabled: false
  }
};
