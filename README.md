# Irys-storage-CLI

## 1. Create iris directory
```
mkdir -p ~/irys && cd ~/irys
```
## 2. Create your .env file (edit as needed)
```
nano ~/.irys_env
```
### 3. Copy this template in the .env
```
# ~/.irys_env
# Private key (no 0x)
export IRYS_PRIVATE_KEY=YOUR_PRIVATE_KEY_HERE

# RPC used to talk to the chain (Sepolia example)
export IRYS_RPC_URL=https://sepolia.drpc.org

# Token & wallet
export IRYS_TOKEN=ethereum
export IRYS_WALLET=0xYourWalletAddressHere

# Preferred "network" for CLI behaviour (mainnet or devnet) — optional,
# but if you want to use Sepolia RPC without forcing the devnet bundler,
# you can leave this blank or set to "devnet" deliberately.
# export IRYS_NETWORK=devnet

# Optional: explicit uploader/bundler host override (recommended)
# - Use devnet.irys.xyz for the Irys devnet bundler
# - Use uploader.irys.xyz for mainnet bundler
# - Or set to an alternate uploader (e.g., turbo.ardrive.io) if you want to use that service.
export IRYS_BUNDLER_URL=https://devnet.irys.xyz

```
##### Replace `your_private_key_here` with a fresh wallet's keys and `0xYourWalletAddressHere` with the respective wallet address
##### Also remember to fund your wallet with some Ethereum Sepolia 🔴

## 4. Download installation file
```
wget -O irys.sh https://raw.githubusercontent.com/AdityaNarayan02/Irys-storage-CLI/main/irys.sh
```
```
chmod +x irys.sh
```
```
source ~/.irys_env
```
```
./irys.sh install
```
## 5. Explore the CLI
```
source ~/.irys_env
```
```
./irys.sh fund
# → asks: Enter amount in wei: 200000000000000

./irys.sh balance
# → prints balance directly

./irys.sh upload
# → asks: Enter file path: my.png
# → asks: Enter MIME type: image/png
```

### 6. Extra CMDs
```
./irys.sh upload-dir
./irys.sh price
```

THANK YOU, IF YOU LIKE MY WORK STAR THE REPO🌟

