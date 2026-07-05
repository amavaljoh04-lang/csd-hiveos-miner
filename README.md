# WarpMiner v2.1.0-unthrottled (FusionLayer / FXL)

**Fork de** [0xFusionLayer/warpminer](https://github.com/0xFusionLayer/warpminer) **avec les limitations retirées pour CMP 90HX et autres grosses cartes.**

## Modifications vs v2.0.0 officiel

### 1. WorkSize cap retiré (miner.go)
- **Avant :** `workSize = min(Max_work_group_size/16, 8)` → plafonné à 8
- **Après :** `workSize = min(Max_work_group_size/16, 16)` → permet 16 pour les CMP 90HX (meilleure occupancy)

### 2. Budget mémoire VRAM débloqué (miner.go)
- **Avant :** Utilise `Max_mem_alloc_size * 90%` → seulement ~2.5 GB sur NVIDIA (25% de la VRAM)
- **Après :** Détecte les cartes NVIDIA et utilise `Global_mem_size * 80%` → ~8 GB sur CMP 90HX (10 GB VRAM)
- **Résultat :** ~4x plus de threads mining (de ~1150 à ~4000+)

### 3. Multiplicateur compute augmenté (miner.go)
- **Avant :** `Max_compute_units * 6 * 8 = 3936` threads max (CMP 90HX = 82 CUs)
- **Après :** `Max_compute_units * 16 * 8 = 10496` threads max → la mémoire devient le seul bottleneck

### 4. NVIDIA OpenCL allocation override (main.go)
- Définit automatiquement `GPU_MAX_ALLOC_PERCENT=95` au démarrage
- Plus besoin de le mettre manuellement dans les variables d'environnement

### 5. Fallback automatique
- Si l'allocation large échoue (driver trop ancien), retombe automatiquement sur le mode conservateur

## Installation HiveOS (Flight Sheet)

| Champ | Valeur |
|-------|--------|
| **Miner name** | `warpminer` |
| **Installation URL** | *(voir Releases)* |
| **Hash algorithm** | `fusionhash` |
| **Wallet template** | `%WAL%` |
| **Pool URL** | `wss://eu.coin-miners.info:8443` |
| **Extra config** | *(vide ou `-intensity 0.8` si surchauffe)* |

## Compilation depuis les sources

```bash
sudo apt install -y gcc g++ make build-essential ocl-icd-opencl-dev opencl-headers
go build -ldflags="-s -w" -o warpminer .
```

## Gain attendu

| Carte | Avant (v2.0.0) | Après (v2.1.0) | Gain |
|-------|--------|--------|------|
| CMP 90HX (10 GB) | ~0.25 kH/s | ~0.8-1.0 kH/s | **~3-4x** |
| RTX 3090 (24 GB) | ~0.25 kH/s | ~1.5-2.0 kH/s | **~6-8x** |
| RTX 4090 (24 GB) | ~0.30 kH/s | ~2.0-2.5 kH/s | **~7-8x** |

*Gains estimés basés sur le nombre de threads supplémentaires. Résultats réels peuvent varier.*
