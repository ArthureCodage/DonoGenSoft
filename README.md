# DonoGenSoft

**kohya_ss** (entraînement de LoRA) + **Stable Diffusion WebUI Forge Neo** (génération d'images),
installés ensemble en une commande sur une instance GPU louée (vast.ai, RunPod…).

| Outil | Source | Version | Port |
|---|---|---|---|
| Forge Neo | [Haoming02/sd-webui-forge-classic](https://github.com/Haoming02/sd-webui-forge-classic/tree/neo) (branche `neo`) | Python 3.13, torch cu130 | **7860** |
| kohya_ss | [bmaltais/kohya_ss](https://github.com/bmaltais/kohya_ss) | v26.0.0, Python 3.11, torch cu128 | **7861** |

Les deux projets sont inclus comme *sous-modules git* : leurs versions sont figées dans ce repo,
donc chaque instance installe exactement la même chose. Chacun a son propre environnement Python
(installé avec [uv](https://github.com/astral-sh/uv), beaucoup plus rapide que pip).

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

`start.sh` affiche l'identifiant (`dono`) et le mot de passe des deux interfaces.
Le mot de passe est créé au premier lancement et gardé dans `data/password.txt`.

### Encore plus simple : tout automatique au démarrage

Dans le champ **On-start script** (vast.ai) ou **Container Start Command** (RunPod) :

```bash
curl -fsSL https://raw.githubusercontent.com/ArthureCodage/DonoGenSoft/main/bootstrap.sh | bash
```

Il clone le repo dans `/workspace/DonoGenSoft`, installe si ce n'est pas déjà fait, puis lance les deux interfaces.
Au redémarrage d'une instance déjà installée, il relance directement.

---

## Commandes

| Commande | Effet |
|---|---|
| `bash install.sh` | Installe les deux (`install.sh forge` ou `install.sh kohya` pour un seul) |
| `bash start.sh` | Lance les deux en arrière-plan (`start.sh forge` / `start.sh kohya`) |
| `bash stop.sh` | Arrête (`stop.sh forge` / `stop.sh kohya`) |
| `bash update.sh` | Récupère la dernière version de ce repo et réinstalle si besoin |
| `bash update.sh --latest` | Passe en plus kohya_ss et Forge Neo à leur toute dernière version |
| `tail -f logs/forge.log logs/kohya.log` | Suivre ce qui se passe |

Variables utiles : `FORGE_PORT`, `KOHYA_PORT`, `DGS_PASSWORD` (mot de passe imposé),
`FORGE_ARGS` / `KOHYA_ARGS` (options en plus, ex. `FORGE_ARGS="--sage" bash start.sh forge`).

---

## Accéder aux interfaces

**Option 1 — tunnel SSH (le plus sûr, marche partout).** Depuis le PC :

```bash
ssh -p <port-ssh> root@<ip> -L 7860:localhost:7860 -L 7861:localhost:7861
```

puis ouvrir http://localhost:7860 (Forge) et http://localhost:7861 (kohya).

**Option 2 — ports ouverts.**
- *vast.ai* : dans le template, ajouter `-p 7860:7860 -p 7861:7861` aux options Docker ;
  l'adresse publique de chaque port est dans *Instances → IP & ports*.
- *RunPod* : dans le template, ajouter `7860,7861` aux *HTTP ports* ; les liens apparaissent dans *Connect*.

Les interfaces sont protégées par l'identifiant/mot de passe affiché par `start.sh`.

---

## Dossiers partagés (`data/`)

| Dossier | Usage |
|---|---|
| `data/models/checkpoints` | Modèles de base (`.safetensors`) — visibles dans Forge, à indiquer dans kohya |
| `data/loras` | LoRA : mettre ici le dossier de sortie de kohya, ils apparaissent directement dans Forge |
| `data/datasets` | Images d'entraînement |
| `data/hf-cache` | Téléchargements Hugging Face + config `accelerate` |

Forge garde aussi ses dossiers habituels (`forge-neo/models/...`).
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
├── scripts/env.sh  réglages communs (ports, dossiers, uv)
├── kohya_ss/       sous-module bmaltais/kohya_ss
└── forge-neo/      sous-module Haoming02/sd-webui-forge-classic (neo)
```

`data/`, `logs/` et `.uv/` sont créés à l'installation et ne sont pas suivis par git.

## Journal

- 2026-10-24 — Création : kohya_ss v26.0.0 + Forge Neo (`neo` @ 0c388f8), scripts install/start/stop/update/bootstrap.
- 2026-10-24 — Testé dans un conteneur Ubuntu 24.04 + RTX 2060 (pilote CUDA 13.4) : installation complète, les deux interfaces démarrent et s'arrêtent. Corrigés : détection « CUDA UMD Version », plantage du mot de passe (SIGPIPE), cache uv (~16 Go) vidé en fin d'installation.
