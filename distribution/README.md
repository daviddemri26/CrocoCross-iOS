# CrocoCross — dossier App Store 1.0.0 (17)

Dossier préparé pour une saisie manuelle dans App Store Connect. L’interface du jeu est en anglais ; la fiche commerciale est disponible en français et en anglais. Rocco et Canyon sont les seuls choix jouables.

## Fichiers à utiliser

| Dossier | Contenu |
|---|---|
| `screenshots/upload/en-US/iphone-6.9/` | 5 images prêtes à importer, dans l’ordre des noms, 1320 × 2868 px |
| `screenshots/upload/en-US/ipad-13/` | 5 images iPad paysage, 2752 × 2064 px |
| `screenshots/upload/fr-FR/` | Les mêmes séries avec titres français ; le jeu reste affiché en anglais |
| `screenshots/raw/` | Captures réelles sans habillage, également aux dimensions acceptées |
| `icons/CrocoCross-1024.png` | Icône marketing 1024 × 1024, opaque ; l’icône App Store provient aussi du build |
| `icons/` | Déclinaisons d’icône ; Xcode dérive automatiquement les tailles iOS du catalogue universel |
| `metadata/en-US/` et `metadata/fr-FR/` | Un fichier texte par champ, prêt à copier sans son nom de fichier |
| `metadata/app-information.json` | Identifiants, prix, catégories et URLs |
| `review/app-review-notes.txt` | Texte anglais pour l’équipe de vérification Apple |
| `review/game-center.json` | Les trois classements à configurer |
| `review/declarations.md` | Réponses proposées et justification : confidentialité, âge, chiffrement, droits |
| `private/app-review-contact.txt` | Contact Apple fourni par l’éditeur, exclu du Git public |
| `config/` | Paramètres d’export, copies du manifeste et des plist/entitlements |
| `web/` | Sources des pages GitHub Pages en français et en anglais |
| `validation.json` | Vérifications techniques des images, textes et fichiers système |
| `VALIDATION.md` | Résultats des captures, de l’archive et de l’export, avec leurs limites |

Utiliser une seule série de 5 captures par langue/appareil : la série `upload` est la présentation recommandée ; `raw` est l’alternative sans titres. Ne pas charger les deux séries ensemble. Les captures ne contiennent ni score inventé ni faux classement.

Les aperçus `preview-*.jpg` sont des planches de contrôle, pas des images à charger sur le Store. La vidéo de présentation est facultative et n’est pas incluse.

## 1. Créer la fiche

Compte Apple : **David Demri**, comme SweetKeyboard Pro. Copyright : **2026 Lafayette Consulting**.

- Nom : **CrocoCross**.
- Plateforme : **iOS** (iPhone + iPad).
- Bundle ID : **com.daviddemri.crococross**.
- SKU proposé : **CROCOCROSS-IOS-001** (identifiant interne, à créer une seule fois).
- Langue principale : **English (U.S.)** ; ajouter **French** pour les textes FR.
- Catégorie : **Games** ; sous-catégories **Racing** et **Sports**.
- Prix : **gratuit**. Aucun achat intégré ni abonnement.
- Version : **1.0.0**. Build préparé : **17**.
- Publication : **manuelle**, après validation Apple.
- Compatibilité native : iOS/iPadOS 18+. Mac et Vision ne sont pas des cibles de cette version ; vérifier les disponibilités « apps iPhone/iPad » correspondantes dans App Store Connect.

## 2. Copier les textes et ajouter les visuels

Copier `name.txt`, `subtitle.txt`, `promotional-text.txt`, `description.txt`, `keywords.txt` et les URLs de la langue choisie. La version initiale n’a pas besoin de texte « Nouveautés ». Les fichiers `beta-*` et `what-to-test.txt` servent à TestFlight, pas à la description publique.

Charger les PNG numérotés 01 à 05 dans les sections iPhone 6,9″ et iPad 13″. Tous sont RGB, opaques, sans canal alpha. Apple peut dériver les tailles inférieures de ces séries. [Spécifications Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications).

## 3. Confidentialité et contrôle Apple

Lire `review/declarations.md`, copier `review/app-review-notes.txt` et compléter le contact avec `private/app-review-contact.txt`. Aucun compte de démonstration n’est nécessaire. Les champs d’adresse/statut professionnel de l’éditeur sont gérés au niveau du compte : reprendre ceux de SweetKeyboard ; ne pas inventer une adresse.

Les pages HTTPS de support et de confidentialité doivent être accessibles avant soumission. Elles sont dédiées à CrocoCross et expliquent Game Center, contrairement à la politique du clavier.

## 4. Game Center

Créer les trois classements de `review/game-center.json`. Les deux hebdomadaires utilisent la même date de départ, un lundi futur à 00:00 UTC, et une durée/récurrence de 604 800 secondes. Ne pas recopier une date de départ devenue passée.

Activer et joindre les classements à la version soumise. Après le début de la première période, vérifier une authentification, une véritable course, son envoi et sa relecture. Le code et les identifiants sont prêts ; cette préparation ne crée pas les classements et ne prétend pas que leurs serveurs sont validés. Les textes publics fournis mettent en avant le jeu et les records locaux.

## 5. Le build : Xcode ou Transporter, puis le navigateur

**Le navigateur ne permet pas de téléverser directement l’app iOS.** La fiche et les images se gèrent dans App Store Connect ; le binaire passe par Xcode Organizer ou Transporter. [Apple : envoyer un build](https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/).

Une archive Release est fournie à côté du ZIP. L’archive compile avec Xcode 26.6 et le SDK iOS 26.5, ce qui respecte le minimum iOS 26 en vigueur. [Exigence SDK Apple](https://developer.apple.com/news/?id=ueeok6yw).

L’export App Store local a été tenté : Xcode a répondu `No Accounts` et absence de profil de distribution pour le bundle. L’archive de développement existe ; elle doit être resignée pour le Store. Aucun IPA App Store ni envoi à Apple n’est annoncé comme réussi.

1. Dans Xcode > Settings > Accounts, connecter le compte Apple Developer de David utilisé pour SweetKeyboard.
2. Vérifier que `com.daviddemri.crococross` existe avec la capacité Game Center dans Certificates, Identifiers & Profiles ; créer la fiche App Store Connect.
3. Ouvrir l’archive dans Xcode Organizer, choisir **Distribute App > App Store Connect**, puis laisser la signature automatique utiliser/créer le profil de distribution approprié.
4. Valider le build, puis l’envoyer lorsque tu es prêt. L’option de ligne de commande fournie utilise `destination=export` : elle produit un IPA local, sans upload.
5. Attendre le traitement Apple et sélectionner le build 17 sur la fiche.
6. Vérifier les déclarations, disponibilités géographiques et classements, puis soumettre manuellement.

## Reproduire

Depuis la racine du projet :

```sh
python3 scripts/generate-project.py
bash scripts/archive-app-store.sh /tmp/crococross-appstore-release
python3 scripts/check-app-store-package.py
```

Le script d’archive ne publie rien. L’export se lance séparément, selon les instructions affichées. `scripts/prepare-store-images.py` nécessite Pillow et compose les images à partir des captures XCTest originales. Les sources de capture sont dans `UITests/AppStoreCaptureTests.swift`.
