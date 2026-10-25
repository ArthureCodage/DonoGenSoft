<div align="center">

# DonoGenSoft

**Entraîne des LoRA et génère des images sur un GPU loué, avec une seule commande.**

kohya_ss + LoRA Creator + Stable Diffusion Forge Neo, prêts en ~15 min sur vast.ai ou RunPod.

![vast.ai](https://img.shields.io/badge/vast.ai-compatible-1f6feb)
![RunPod](https://img.shields.io/badge/RunPod-compatible-673ab7)
![kohya_ss](https://img.shields.io/badge/kohya__ss-v26-8b7cf6)
![Forge Neo](https://img.shields.io/badge/Forge-Neo-f97316)
![CUDA](https://img.shields.io/badge/CUDA-12.8%2B-76B900?logo=nvidia&logoColor=white)

```bash
curl -fsSL https://raw.githubusercontent.com/ArthureCodage/DonoGenSoft/main/bootstrap.sh | bash
```

</div>

<details>
<summary><b>🇬🇧 English summary</b></summary>

DonoGenSoft installs **kohya_ss** (LoRA training), **[LoRA Creator](https://github.com/ArthureCodage/lora-creator)**
(a simple UI on top of kohya) and **Stable Diffusion WebUI Forge Neo** (image generation) together, with one command,
on a rented GPU instance (vast.ai, RunPod…).

- Paste the `curl … | bash` line above in the **On-start script** (vast.ai) or **Container Start Command** (RunPod):
  it clones, installs (~10–15 min) and starts everything. Restarts are instant.
- Forge on port **7860**, kohya_ss on **7861**, LoRA Creator on **7870**, all behind a login (user `dono`, password printed by `start.sh`).
- Shared folders: LoRAs trained in kohya / LoRA Creator show up directly in Forge.
- Versions are pinned with git submodules, so every instance installs exactly the same thing. Environments built with `uv`.
- Manual install: `git clone --recursive https://github.com/ArthureCodage/DonoGenSoft.git && cd DonoGenSoft && bash install.sh && bash start.sh`

Recommended instance: RTX 3090 / 4090 / 5090, driver CUDA ≥ 12.8 (13.0 ideal), 60 GB disk minimum.

</details>

---

**kohya_ss** (entraînement de LoRA) + **LoRA Creator** (interface simplifiée pour kohya) +
**Stable Diffusion WebUI Forge Neo** (génération d'images), installés ensemble en une commande
sur une instance GPU louée (vast.ai, RunPod…).

| Outil | Source | Version | Port |
|---|---|---|---|
| Forge Neo | [Haoming02/sd-webui-forge-classic](https://github.com/Haoming02/sd-webui-forge-classic/tree/neo) (branche `neo`) | Python 3.13, torch cu130 | **7860** |
| kohya_ss | [bmaltais/kohya_ss](https://github.com/bmaltais/kohya_ss) | v26.0.0, Python 3.11, torch cu128 | **7861** |
| LoRA Creator | [ArthureCodage/lora-creator](https://github.com/ArthureCodage/lora-creator) | utilise le Python de kohya_ss | **7870** |

Les trois projets sont inclus comme *sous-modules git* : leurs versions sont figées dans ce repo,
donc chaque instance installe exactement la même chose. Forge et kohya ont chacun leur propre
environnement Python (installé avec [uv](https://github.com/astral-sh/uv), beaucoup plus rapide que pip) ;
LoRA Creator tourne sur celui de kohya_ss, déjà configuré avec les dossiers de ce repo.

---

## Démarrage rapide

Sur l'instance (terminal SSH ou Jupyter) :

```bash
cd /workspace
git clone --recursive https://github.com/ArthureCodage/DonoGenSoft.git
cd DonoGenSoft
bash install.sh
bash start.sh
```

`start.sh` affiche l'identifiant (`dono`) et le mot de passe des trois interfaces.
Le mot de passe est créé au premier lancement et gardé dans `data/password.txt`.

### Encore plus simple : tout automatique au démarrage

Dans le champ **On-start script** (vast.ai) ou **Container Start Command** (RunPod) :

```bash
curl -fsSL https://raw.githubusercontent.com/ArthureCodage/DonoGenSoft/main/bootstrap.sh | bash
```

Il clone le repo dans `/workspace/DonoGenSoft`, installe si ce n'est pas déjà fait, puis lance les trois interfaces.
Au redémarrage d'une instance déjà installée, il relance directement.

---

## Commandes

| Commande | Effet |
|---|---|
| `bash install.sh` | Installe tout (`install.sh forge`, `install.sh kohya` ou `install.sh lora` pour un seul ; `lora` installe aussi kohya) |
| `bash start.sh` | Lance tout en arrière-plan (`start.sh forge` / `kohya` / `lora`) |
| `bash stop.sh` | Arrête (`stop.sh forge` / `kohya` / `lora`) |
| `bash update.sh` | Récupère la dernière version de ce repo et réinstalle si besoin |
| `bash update.sh --latest` | Passe en plus kohya_ss, Forge Neo et LoRA Creator à leur toute dernière version |
| `tail -f logs/*.log` | Suivre ce qui se passe |

Variables utiles : `FORGE_PORT`, `KOHYA_PORT`, `LC_PORT`, `DGS_PASSWORD` (mot de passe imposé),
`FORGE_ARGS` / `KOHYA_ARGS` (options en plus, ex. `FORGE_ARGS="--sage" bash start.sh forge`).

---

## Accéder aux interfaces

**Option 1 — tunnel SSH (le plus sûr, marche partout).** Depuis le PC :

```bash
ssh -p <port-ssh> root@<ip> -L 7860:localhost:7860 -L 7861:localhost:7861 -L 7870:localhost:7870
```

puis ouvrir http://localhost:7860 (Forge), http://localhost:7861 (kohya) et http://localhost:7870 (LoRA Creator).

**Option 2 — ports ouverts.**
- *vast.ai* : dans le template, ajouter `-p 7860:7860 -p 7861:7861 -p 7870:7870` aux options Docker ;
  l'adresse publique de chaque port est dans *Instances → IP & ports*.
- *RunPod* : dans le template, ajouter `7860,7861,7870` aux *HTTP ports* ; les liens apparaissent dans *Connect*.

Les trois interfaces sont protégées par l'identifiant/mot de passe affiché par `start.sh`
(LoRA Creator n'a pas de connexion à lui : DonoGenSoft l'ajoute, le navigateur affiche une fenêtre de connexion).

---

## Dossiers partagés (`data/`)

| Dossier | Usage |
|---|---|
| `data/models/checkpoints` | Modèles de base (`.safetensors`) — visibles dans Forge, à indiquer dans kohya |
| `data/loras` | LoRA : mettre ici le dossier de sortie de kohya, ils apparaissent directement dans Forge |
| `data/datasets` | Images d'entraînement |
| `data/lora-creator` | LoRA Creator : ses datasets, entraînements (`runs/`), LoRA produits, `config.json` |
| `data/hf-cache` | Téléchargements Hugging Face + config `accelerate` |

Forge garde aussi ses dossiers habituels (`forge-neo/models/...`).

**LoRA Creator** est réglé automatiquement : il entraîne avec le kohya_ss de ce repo, propose les modèles
de `data/models/checkpoints` et `forge-neo/models/Stable-diffusion`, et copie chaque LoRA fini dans
`data/loras`, donc directement visible dans Forge. Sa config (`data/lora-creator/config.json`) est
réécrite à chaque `start.sh`.
Tout est dans `/workspace`, donc conservé si l'instance est arrêtée puis relancée.

Télécharger un modèle directement sur l'instance (bien plus rapide que de l'envoyer depuis le PC) :

```bash
cd /workspace/DonoGenSoft/data/models/checkpoints
aria2c -x 16 -s 16 "<lien direct .safetensors>"
```

---

## Choisir l'instance

- **GPU** : RTX 4090 / 5090 (24–32 Go) ou 3090 pour économiser. RTX 50xx → driver récent obligatoire.
- **Driver** : CUDA **≥ 13.0** idéal (Forge Neo utilise torch cu130). Entre 12.8 et 13.0,
  `install.sh` installe automatiquement un torch compatible pour Forge. kohya_ss demande **≥ 12.8**.
- **Image** : n'importe quelle image Ubuntu avec les drivers NVIDIA, par ex.
  `vastai/base-image:cuda-12.8.1-auto` ou un template PyTorch RunPod. Python n'a pas besoin d'être installé.
- **Disque** : 60 Go minimum (les deux environnements ≈ 18 Go une fois installés, pic à ~35 Go pendant l'installation, + modèles), 100 Go pour Flux.
- **Durée d'installation** : environ 10–15 min selon le débit de l'instance.

---

## Structure du repo

```
DonoGenSoft/
├── install.sh      installation (paquets système, uv, sous-modules, environnements Python)
├── start.sh        lancement en arrière-plan
├── stop.sh         arrêt
├── update.sh       mise à jour
├── bootstrap.sh    clone + install + start, pour le script de démarrage de l'instance
├── scripts/env.sh  réglages communs (ports, dossiers, uv, config LoRA Creator)
├── scripts/lora_creator_serve.py  lance LoRA Creator avec connexion obligatoire
├── kohya_ss/       sous-module bmaltais/kohya_ss
├── lora-creator/   sous-module ArthureCodage/lora-creator
└── forge-neo/      sous-module Haoming02/sd-webui-forge-classic (neo)
```

`data/`, `logs/` et `.uv/` sont créés à l'installation et ne sont pas suivis par git.

## Journal

- 2026-10-24 — Création : kohya_ss v26.0.0 + Forge Neo (`neo` @ 0c388f8), scripts install/start/stop/update/bootstrap.
- 2026-10-24 — Testé dans un conteneur Ubuntu 24.04 + RTX 2060 (pilote CUDA 13.4) : installation complète, les deux interfaces démarrent et s'arrêtent. Corrigés : détection « CUDA UMD Version », plantage du mot de passe (SIGPIPE), cache uv (~16 Go) vidé en fin d'installation.
- 2026-10-25 — Ajout de LoRA Creator (sous-module, port 7870) derrière une connexion. Testé dans Docker + RTX 2060 : install `lora` (5 min), connexion refusée sans mot de passe, légendes auto WD14 OK via kohya.
