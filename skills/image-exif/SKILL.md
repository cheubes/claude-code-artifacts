---
name: image-exif
description: Vérifie ou modifie les données EXIF d'images. Déclencher sur toute demande liée aux métadonnées, propriétés ou informations EXIF d'un ou plusieurs fichiers images.
disable-model-invocation: true
argument-hint: "check <fichier(s)> | edit <fichier>"
allowed-tools: Bash(exiftool *), Read
---

# Skill image-exif

Tu gères les métadonnées EXIF d'images à partir de : `$ARGUMENTS`

---

## Prérequis

Avant toute action, vérifie qu'exiftool est disponible :

```
exiftool -ver
```

Si la commande échoue, arrête-toi et informe l'utilisateur : "exiftool n'est pas installé. Installe-le via `brew install exiftool` (macOS) ou `sudo apt install libimage-exiftool-perl` (Debian/Ubuntu)."

---

## Arguments manquants

Si aucun fichier n'est mentionné après la commande (`check` ou `edit` seul), demande à l'utilisateur de préciser le ou les fichiers à traiter avant de continuer.

---

## Cas 1 — Vérification (`check`)

Si la demande commence par `check` ou ressemble à une demande de lecture/consultation :

### 1a — Lecture des champs

Lance la commande suivante sur chaque fichier mentionné :

```
exiftool -Title -XMP-dc:Creator -IPTC:By-line -IPTC:CopyrightNotice -XMP-dc:Rights -XMP-photoshop:Credit -XMP-photoshop:Source -XMP-xmpRights:WebStatement -XMP-xmpRights:UsageTerms -XMP-xmpRights:Marked -XMP-dc:Description -IPTC:Caption-Abstract <fichier>
```

### 1b — Validation des champs obligatoires

Vérifie chaque champ selon les règles strictes ci-dessous :

| Champ | Tag exiftool | Règle |
|-------|-------------|-------|
| Titre | `-Title` | Ne doit **pas** être vide |
| Créateur (XMP) | `-XMP-dc:Creator` | Doit être **exactement** `Christophe Heubès` |
| Créateur (IPTC) | `-IPTC:By-line` | Doit être **exactement** `Christophe Heubès` |
| Copyright (IPTC) | `-IPTC:CopyrightNotice` | Doit être **exactement** `CC Christophe Heubès` |
| Droits (XMP) | `-XMP-dc:Rights` | Doit être **exactement** `Christophe Heubès - CC BY-NC-SA 4.0` |
| Crédit | `-XMP-photoshop:Credit` | Doit être **exactement** `Christophe Heubès` |
| Source | `-XMP-photoshop:Source` | Ne doit **pas** être vide ; déduite du contexte si possible, sinon demandée à l'utilisateur |
| Web Statement | `-XMP-xmpRights:WebStatement` | Doit être **exactement** `https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr` |
| Conditions d'usage | `-XMP-xmpRights:UsageTerms` | Doit être **exactement** `CC BY-NC-SA 4.0` |
| Marked | `-XMP-xmpRights:Marked` | Doit être **exactement** `True` |
| Description (XMP) | `-XMP-dc:Description` | Ne doit **pas** être vide ; déduite du contexte si possible, sinon demandée à l'utilisateur |
| Légende (IPTC) | `-IPTC:Caption-Abstract` | Ne doit **pas** être vide ; déduite du contexte si possible, sinon demandée à l'utilisateur |

Affiche un tableau récapitulatif pour chaque fichier avec le statut de chaque champ (✓ conforme / ✗ non conforme + valeur actuelle).

### 1c — Correction des écarts

Si au moins un fichier présente des champs non conformes :

1. Propose de corriger automatiquement les écarts détectés
2. Si l'utilisateur accepte, traite **chaque fichier non conforme séparément** :
   a. Pour les champs à valeur fixe (Créateur XMP/IPTC, Copyright IPTC, Droits, Crédit, Web Statement, Conditions d'usage, Marked), applique directement la valeur attendue, sans demander confirmation
   b. Si le champ **Titre** est parmi ses champs non conformes, demande le libellé souhaité pour ce fichier
   c. Si les champs **Source**, **Description** ou **Légende** sont parmi ses champs non conformes, essaie de déduire une valeur pertinente à partir du contexte disponible (contenu de l'image via `Read`, nom de fichier, métadonnées déjà présentes, échanges précédents dans la conversation). Si aucune déduction fiable n'est possible, demande la valeur à l'utilisateur avant de continuer
   d. Construis une commande `exiftool` qui n'inclut **que les champs non conformes** de ce fichier :
      ```
      exiftool -overwrite_original \
        [-Title="..."] \
        [-XMP-dc:Creator="Christophe Heubès"] \
        [-IPTC:By-line="Christophe Heubès"] \
        [-IPTC:CopyrightNotice="CC Christophe Heubès"] \
        [-XMP-dc:Rights="Christophe Heubès - CC BY-NC-SA 4.0"] \
        [-XMP-photoshop:Credit="Christophe Heubès"] \
        [-XMP-photoshop:Source="..."] \
        [-XMP-xmpRights:WebStatement="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr"] \
        [-XMP-xmpRights:UsageTerms="CC BY-NC-SA 4.0"] \
        [-XMP-xmpRights:Marked="True"] \
        [-XMP-dc:Description="..."] \
        [-IPTC:Caption-Abstract="..."] \
        <fichier>
      ```
3. Une fois tous les fichiers traités, affiche un tableau récapitulatif final avec le statut de chaque fichier

**Exemple d'invocation :**
```
/image-exif check photo.jpg
/image-exif check *.jpg
```

---

## Cas 2 — Modification (`edit`)

Si la demande commence par `edit` :

### 2a — Lecture de l'état actuel

Lance `exiftool -Title -XMP-dc:Creator -IPTC:By-line -IPTC:CopyrightNotice -XMP-dc:Rights -XMP-photoshop:Credit -XMP-photoshop:Source -XMP-xmpRights:WebStatement -XMP-xmpRights:UsageTerms -XMP-xmpRights:Marked -XMP-dc:Description -IPTC:Caption-Abstract <fichier>` et affiche les champs sous forme de tableau (valeur actuelle + conformité selon les règles de 1b).

### 2b — Demande des champs contextuels

- **Titre** : si un Titre existe déjà, demande si l'utilisateur souhaite le conserver ou le remplacer ; s'il est vide ou absent, demande directement le libellé souhaité.
- **Source**, **Description**, **Légende** : si l'un de ces champs est vide ou non conforme, essaie de déduire une valeur pertinente à partir du contexte disponible (contenu de l'image via `Read`, nom de fichier, métadonnées déjà présentes, échanges précédents). Si aucune déduction fiable n'est possible, demande la valeur à l'utilisateur.

Ne pas procéder à la modification tant que le Titre et les champs contextuels non conformes ne sont pas confirmés ou fournis.

### 2c — Application des modifications

Construis une commande `exiftool` qui inclut toujours le Titre fourni, ainsi que **tous les autres champs non conformes** identifiés en 2a :

```
exiftool -overwrite_original \
  -Title="<titre fourni>" \
  [-XMP-dc:Creator="Christophe Heubès"] \
  [-IPTC:By-line="Christophe Heubès"] \
  [-IPTC:CopyrightNotice="CC Christophe Heubès"] \
  [-XMP-dc:Rights="Christophe Heubès - CC BY-NC-SA 4.0"] \
  [-XMP-photoshop:Credit="Christophe Heubès"] \
  [-XMP-photoshop:Source="..."] \
  [-XMP-xmpRights:WebStatement="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr"] \
  [-XMP-xmpRights:UsageTerms="CC BY-NC-SA 4.0"] \
  [-XMP-xmpRights:Marked="True"] \
  [-XMP-dc:Description="..."] \
  [-IPTC:Caption-Abstract="..."] \
  <fichier>
```

### 2d — Confirmation

Relis tous les champs avec la commande de 2a et affiche le résultat.

**Exemple d'invocation :**
```
/image-exif edit photo.jpg
```

---

## Cas ambigu

Si l'intention n'est pas clairement identifiable (ni lecture, ni modification évidente), demande une clarification avant d'agir :

> "Souhaites-tu **vérifier** les métadonnées de ce fichier, ou les **modifier** ?"
