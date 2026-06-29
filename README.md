# CSD Pool Miner — HiveOS Custom Miner Package (Optimized)

**Version:** v0.2.0-optimized  
**Algorithm:** SHA-256d (Compute Substrate / CSD)  
**Pool:** pool.yamaduo.no:3333 (built-in)  
**Compatible:** Any NVIDIA GPU (GTX 1060+, RTX 20xx/30xx/40xx/50xx, CMP, Tesla, A-series)

## Optimizations (vs v0.1.19 official)

1. **CUDA Kernel Early-Exit** — Checks outer hash first word immediately after SHA-256 compression. Rejects 99.99%+ of nonces before computing the full target comparison. Saves ~7 state-word computations per miss.

2. **Optimized maj() computation** — Uses `(a & b) | (c & (a | b))` instead of textbook `(a & b) ^ (a & c) ^ (b & c)`. One fewer XOR per round = 64 fewer ops per hash.

3. **Expanded Auto-Tune Geometries** — 12 candidate geometries (vs 6 in official) covering:
   - Small GPUs (10-20 SMs): 256-512 blocks
   - Mid-range GPUs (28-46 SMs): 560-1024 blocks  
   - Large GPUs (82+ SMs like CMP 90HX, RTX 4090): 2048-4096 blocks
   - High-occupancy variants: 512 TPB, 128 TPB options

4. **Reduced Global Memory Traffic** — Found-flag polling interval doubled from 256 to 512 nonces, cutting uncoalesced global reads by 50% in the inner mining loop.

5. **NVML Telemetry Enabled** — Real-time temperature, fan speed, power draw monitoring via NVIDIA Management Library.

## Installation (SSH — one command)

```bash
cd /hive/miners/custom && rm -rf csd-pool-miner-v0.2.0-optimized && wget https://github.com/amavaljoh04-lang/csd-hiveos-miner/releases/download/v0.2.0-optimized/csd-pool-miner-v0.2.0-optimized-hiveos.tar.gz && tar -xzf csd-pool-miner-v0.2.0-optimized-hiveos.tar.gz && rm csd-pool-miner-v0.2.0-optimized-hiveos.tar.gz && chmod +x csd-pool-miner-v0.2.0-optimized/*.sh csd-pool-miner-v0.2.0-optimized/csd-gpu-miner
```

## Flight Sheet Configuration

| Field | Value |
|-------|-------|
| **Miner name** | `csd-pool-miner-v0.2.0-optimized` |
| **Installation URL** | `https://github.com/amavaljoh04-lang/csd-hiveos-miner/releases/download/v0.2.0-optimized/csd-pool-miner-v0.2.0-optimized-hiveos.tar.gz` |
| **Hash algorithm** | `sha256d` |
| **Wallet template** | `%WAL%` |
| **Pool URL** | `stratum+tcp://pool.yamaduo.no:3333` |
| **Extra config arguments** | *(laisser vide — ne rien mettre)* |

## Extra Config Options

**Par défaut, ne rien mettre en extra config.** Le miner gère tout automatiquement (auto-tune, thermal management, etc.).

Options avancées (optionnelles, à n'utiliser que si nécessaire) :

| Option | Description | Example |
|--------|-------------|---------|
| `--power-limit <W>` | GPU power limit in watts | `--power-limit 200` |
| `--temp-limit <C>` | Pause mining above this temp | `--temp-limit 85` |
| `--temp-resume <C>` | Resume mining below this temp | `--temp-resume 75` |
| `--no-suggest-diff` | Don't suggest difficulty to pool | `--no-suggest-diff` |

## How It Works

- Automatically detects all NVIDIA GPUs on the rig
- Launches one miner instance per GPU (CUDA backend)
- Auto-tunes optimal CUDA geometry per card at startup (~5s per GPU)
- Reports per-GPU hashrate, temperature, fan speed to HiveOS dashboard
- Built-in pool connection — no external pool configuration needed

## Supported Cards (tested or expected to work)

- CMP 90HX, CMP 70HX, CMP 50HX
- RTX 3060/3070/3080/3090
- RTX 4060/4070/4080/4090
- RTX 5070/5080/5090
- GTX 1060/1070/1080/1080Ti
- Tesla T4, A100, V100
- Any compute capability 5.0+ card

## Troubleshooting

**Miner doesn't start:** Check `miner log` for errors. Common issues:
- No NVIDIA driver: `nvidia-smi` must work
- Wrong wallet format: Must be `0x...` (40 hex chars)

**No stats in HiveOS:** Wait 30-60 seconds after start. The auto-tune phase takes a few seconds per GPU.

**Low hashrate:** Try `--power-limit 250` in extra config for maximum performance (higher power consumption).

## Building from Source

```bash
git clone https://github.com/dangraagu/CSD-Mining-pool-public.git
cd CSD-Mining-pool-public
# Apply optimizations from this repo's kernel
nvcc -ptx -arch=compute_75 -maxrregcount=64 --use_fast_math src/kernels/sha256d.cu -o src/kernels/sha256d.ptx
sed -i 's/^\.version .*/.version 6.3/' src/kernels/sha256d.ptx
cargo build --release --features cuda,nvml
```

## License

Based on [CSD-Mining-pool-public](https://github.com/dangraagu/CSD-Mining-pool-public) — PolyForm Perimeter 1.0.0
