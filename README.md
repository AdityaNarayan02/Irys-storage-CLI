# Irys-storage-CLI

## 1. Create iris directory
```
mkdir -p ~/iris && cd ~/iris
```
## 2. Create your .env file (edit as needed)
```
nano ~/.irys_env
```
### 3. Copy this template in the .env
```
export IRYS_PRIVATE_KEY=your_private_key_here           #hex string, no 0x prefix
export IRYS_RPC_URL=https://sepolia.drpc.org
export IRYS_TOKEN=ethereum
export IRYS_NETWORK=devnet
export IRYS_WALLET=0xYourWalletAddressHere
```
##### Replace `your_private_key_here` with a fresh wallet's keys and `0xYourWalletAddressHere` with the respective wallet address

## 4. Download installation file
```
wget -O iris.sh https://raw.githubusercontent.com/AdityaNaryan02/Irys-storage-CLI/main/irys.sh
```
```
chmod +x irys.sh
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

