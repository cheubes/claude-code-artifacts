---
name: image-exif
description: Vérifie ou modifie les données EXIF d'images. Déclencher sur toute demande liée aux métadonnées, propriétés ou informations EXIF d'un ou plusieurs fichiers images.
disable-model-invocation: true
argument-hint: "check <fichier(s)> | edit <fichier>"
allowed-tools: Bash(exiftool *)
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

## Cas 1 — Vérification (`check`)

Si la demande commence par `check` ou ressemble à une demande de lecture/consultation :

### 1a — Lecture des champs

Lance la commande suivante sur chaque fichier mentionné :

```
exiftool -Title -Creator -Copyright -WebStatement <fichier>
```

### 1b — Validation des champs obligatoires

Vérifie chaque champ selon les règles strictes ci-dessous :

| Champ | Tag exiftool | Règle |
|-------|-------------|-------|
| Titre | `-Title` | Ne doit **pas** être vide |
| Créateur | `-Creator` | Doit être **exactement** `Christophe Heubès` |
| Copyright | `-Copyright` | Doit être **exactement** `CC BY-NC-SA 4.0` |
| Web Statement | `-WebStatement` | Doit être **exactement** `https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr` |

Affiche un tableau récapitulatif pour chaque fichier avec le statut de chaque champ (✓ conforme / ✗ non conforme + valeur actuelle).

### 1c — Correction des écarts

Si au moins un fichier présente des champs non conformes :

1. Propose de corriger automatiquement les écarts détectés
2. Si l'utilisateur accepte, traite **chaque fichier non conforme séparément** :
   a. Si le champ **Titre** est parmi ses champs non conformes, demande le libellé souhaité pour ce fichier
   b. Construis une commande `exiftool` qui n'inclut **que les champs non conformes** de ce fichier :
      ```
      exiftool -overwrite_original [-Title="..."] [-Creator="Christophe Heubès"] [-Copyright="CC BY-NC-SA 4.0"] [-WebStatement="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr"] <fichier>
      ```
3. Une fois tous les fichiers traités, affiche un tableau récapitulatif final avec le statut de chaque fichier

**Exemple d'invocation :**
```
/image-exif check photo.jpg
/image-exif check *.jpg
```

---

## Cas 2 — Modification (`edit`)

Si la demande commence par `edit` ou contient une assignation `tag=valeur` :

### 2a — Lecture de l'état actuel

Lance `exiftool -Title -Creator -Copyright -WebStatement <fichier>` et affiche les quatre champs sous forme de tableau (valeur actuelle + conformité selon les règles de 1b).

### 2b — Demande du Titre

- Si un Titre existe déjà, demande si l'utilisateur souhaite le conserver ou le remplacer.
- Si le Titre est vide ou absent, demande directement le libellé souhaité.

Ne pas procéder à la modification tant que le Titre n'est pas confirmé ou fourni.

### 2c — Application des modifications

Construis une commande `exiftool` qui inclut toujours le Titre fourni, et **uniquement les autres champs non conformes** identifiés en 2a :

```
exiftool -overwrite_original \
  -Title="<titre fourni>" \
  [-Creator="Christophe Heubès"] \
  [-Copyright="CC BY-NC-SA 4.0"] \
  [-WebStatement="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr"] \
  <fichier>
```

### 2d — Confirmation

Relis les 4 champs avec `exiftool -Title -Creator -Copyright -WebStatement <fichier>` et affiche le résultat.

**Exemple d'invocation :**
```
/image-exif edit photo.jpg
```

---

## Cas ambigu

Si l'intention n'est pas clairement identifiable (ni lecture, ni modification évidente), demande une clarification avant d'agir :

> "Souhaites-tu **vérifier** les métadonnées de ce fichier, ou les **modifier** ?"
