---
name: image-exif
description: Vérifie ou modifie les données EXIF d'images. Déclencher sur toute demande liée aux métadonnées, propriétés ou informations EXIF d'un ou plusieurs fichiers images.
disable-model-invocation: true
argument-hint: "check <fichier(s)> | edit <fichier> <tag=valeur> [<tag=valeur> ...]"
allowed-tools: Bash(exiftool *)
---

# Skill image-exif

Tu gères les métadonnées EXIF d'images à partir de : `$ARGUMENTS`

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

Si au moins un champ est non conforme :

1. Propose de corriger automatiquement tous les écarts détectés
2. Si le champ **Titre** est vide ou manquant, demande le libellé souhaité avant de procéder
3. Une fois toutes les informations réunies, applique les corrections en une seule commande `exiftool` :
   ```
   exiftool -overwrite_original -Title="..." -Creator="Christophe Heubès" -Copyright="CC BY-NC-SA 4.0" -WebStatement="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr" <fichier>
   ```
4. Relis les champs corrigés pour confirmer

**Exemple d'invocation :**
```
/image-exif check photo.jpg
/image-exif check *.jpg
```

---

## Cas 2 — Modification (`edit`)

Si la demande commence par `edit` ou contient une assignation `tag=valeur` :

### 2a — Lecture du Titre existant

Lance `exiftool -Title <fichier>` et note la valeur actuelle du champ Titre (peut être vide ou absent).

### 2b — Demande du Titre

- Si un Titre existe déjà, affiche-le : `Titre actuel : "<valeur>"` puis demande si l'utilisateur souhaite le conserver ou le remplacer.
- Si le Titre est vide ou absent, demande directement le libellé souhaité.

Ne pas procéder à la modification tant que le Titre n'est pas confirmé ou fourni.

### 2c — Application des modifications

Applique en une seule commande `exiftool` le Titre fourni **et** les champs obligatoires suivants (sauf instruction contraire explicite de l'utilisateur) :

```
exiftool -overwrite_original \
  -Title="<titre fourni>" \
  -Creator="Christophe Heubès" \
  -Copyright="CC BY-NC-SA 4.0" \
  -WebStatement="https://creativecommons.org/licenses/by-nc-sa/4.0/deed.fr" \
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
