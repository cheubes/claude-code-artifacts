---
name: image-optimize
description: Optimise des images pour le web avec ImageMagick - redimensionne et compresse en place. Déclencher sur toute demande d'optimisation, de réduction de poids ou de redimensionnement d'images.
disable-model-invocation: true
argument-hint: "[--audit] [--width N] [--quality N] [--webp] <fichier(s)>"
allowed-tools: Bash(magick *), Bash(stat *), Bash(du *)
---

# Skill image-optimize

Tu optimises des images pour le web à partir de : `$ARGUMENTS`

---

## Prérequis

Vérifie que `magick` est disponible :

```
magick -version
```

Si la commande échoue, arrête et informe l'utilisateur : "ImageMagick n'est pas installé. Installe-le via `brew install imagemagick`."

---

## Arguments manquants

Si aucun fichier n'est mentionné, demande à l'utilisateur de préciser le ou les fichiers à traiter avant de continuer.

---

## Paramètres

Parse `$ARGUMENTS` pour extraire :

| Flag | Défaut | Description |
|------|--------|-------------|
| `--audit` | absent | Affiche l'analyse sans rien modifier (voir section dédiée) |
| `--width N` | `2400` | Largeur/hauteur maximale en pixels |
| `--quality N` | `85` | Qualité JPEG (1–100) |
| `--webp` | absent | Convertit en WebP (voir section dédiée) |

Tout argument qui n'est pas un flag est un fichier à traiter.

---

## Analyse préalable

Pour chaque fichier, récupère ses dimensions et son poids :

```
magick identify -format "%w %h\n" <fichier>
stat -f "%z" <fichier>
```

Construis un tableau récapitulatif :

| Fichier | Dimensions | Poids | Action prévue |
|---------|-----------|-------|---------------|
| photo.jpg | 4000×3000 | 8,2 Mo | redimensionne → 1920×1440 + qualité 85 % |
| banner.jpg | 1200×800 | 420 Ko | qualité 85 % uniquement (dimensions OK) |

Règles d'affichage de la colonne "Action prévue" :
- Si au moins une dimension dépasse `--width` : indique le redimensionnement cible (calcule la dimension manquante en conservant le ratio)
- Sinon : "qualité N % uniquement (dimensions OK)"
- Si `--webp` : ajoute "→ WebP" à l'action

Si `--audit` est présent, **arrête ici** : affiche le tableau et termine sans demander de confirmation ni modifier aucun fichier.

Sinon, demande confirmation avant de continuer :

> "Optimiser ces N fichiers ?"

---

## Traitement

Pour chaque fichier, exécute :

```
magick <fichier> -resize <WIDTH>x<WIDTH>> -quality <QUALITY> <fichier>
```

Le suffixe `>` dans `-resize` garantit que les images plus petites que le seuil ne sont pas agrandies.

---

## Cas `--webp`

La conversion WebP modifie l'extension du fichier. Avant de traiter quoi que ce soit :

1. Rappelle à l'utilisateur que les fichiers `.jpg`/`.png` originaux seront **supprimés** après conversion.
2. Demande une confirmation explicite supplémentaire : "Cela supprimera les originaux. Confirmes-tu ?"

Si confirmé, pour chaque fichier `photo.jpg` :

```
magick photo.jpg -resize <WIDTH>x<WIDTH>> -quality <QUALITY> photo.webp
rm photo.jpg
```

---

## Rapport final

Affiche un tableau comparatif après traitement :

| Fichier | Avant | Après | Gain |
|---------|-------|-------|------|
| photo.jpg | 8,2 Mo | 1,1 Mo | −87 % |
| banner.jpg | 420 Ko | 95 Ko | −77 % |

Calcule les poids "Après" avec `stat -f "%z" <fichier>`.
