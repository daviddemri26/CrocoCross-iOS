# Validation — CrocoCross 1.0.0 (17)

Préparation du 16 septembre 2026, à partir du code natif `1df60bc` et des changements de cette passe Store. Les documents historiques de validation restent dans `docs/` ; ils ne remplacent pas les résultats de ce candidat.

## Résultats obtenus

- Archive **Release arm64 iOS réussie**, Xcode 26.6 / SDK iOS 26.5, minimum iOS 18, iPhone et iPad. Bundle `com.daviddemri.crococross`, version 1.0.0, build 17.
- Signature Apple Development vérifiée avec `codesign --verify --deep --strict`. Le manifeste de confidentialité et le son renommé sont présents dans l’app archivée, avec les empreintes attendues.
- **Capture UI Release réussie sur iPhone 17 Pro Max et iPad Pro 13 pouces (M5)**, simulateurs iOS 26.5. L’automatisation ouvre les vrais écrans et utilise les commandes normales du jeu. Aucun score ni mouvement n’est injecté. Game Center est désactivé pour ces captures.
- Le premier essai iPad n’a pas ouvert How to à temps ; la seconde exécution du même scénario a réussi. Les images livrées proviennent de cette exécution réussie. Ce résultat ne constitue pas un test d’endurance ni un test de redimensionnement de fenêtre.
- **20 captures avec titres**, cinq par langue et appareil, et **12 captures brutes**. Dimensions : iPhone 1320 × 2868 ; iPad paysage 2752 × 2064. Images opaques RGB, orientation iPad normalisée depuis les métadonnées de capture. Les quatre séries ont été inspectées visuellement.
- **12 tailles d’icône**, dont 1024 × 1024, dérivées du dessin existant ; aucune transparence.
- **193 contrôles du dossier réussis** : dimensions, opacité, longueurs des champs, copies des fichiers système, paramètres d’export, liens locaux des pages et exclusion du contact privé. Détail : `validation.json`.
- Décodage intégral des deux sons utilisés réussi : chute originale **4,09 s**, explosion **2,35 s**. Le renommage de la chute conserve exactement les octets : SHA-256 `228f570ceabf993e83907366e50a630f583e743c0371f9a603f0235ef63e31c2`.
- Pages web examinées dans le navigateur en largeur bureau et mobile ; absence de débordement horizontal à 390 px. La publication GitHub est gérée par `.github/workflows/pages.yml` ; les preuves HTTPS finales sont conservées avec les livrables locaux.

## Ce qui reste à faire avant soumission

L’export App Store a été tenté et **a échoué** : `No Accounts` et absence de profil de distribution pour le bundle. L’archive signée pour le développement est disponible ; aucun IPA App Store ni téléversement Apple n’a été produit. Connecter le compte Apple Developer dans Xcode, puis utiliser Organizer pour la distribution.

Créer manuellement la fiche App Store Connect et les trois classements Game Center. Vérifier ensuite l’authentification et l’envoi/relecture d’une véritable course. Les simulateurs de capture ne vérifient pas ces services.

La build 17 n’a pas été installée sur l’iPhone physique pendant cette préparation. La dernière installation physique appartient à la passe précédente ; elle ne vaut pas validation de distribution de cette archive. Les paramètres de conduite n’ont pas été modifiés ici.

## Livrables et preuves locales

Dans le checkout principal, `artifacts/app-store-release/` contient le ZIP de remise, l’archive `.xcarchive` et `evidence/` : journaux de construction/export, résultats audio et archives de capture. Ce dossier est exclu du Git public. Le numéro du contact App Review reste dans `distribution/private/`, également exclu du Git public ; il est inclus seulement dans le ZIP local destiné à l’éditeur.
