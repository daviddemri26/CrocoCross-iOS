# Déclarations de soumission — version 1.0.0 (17)

Réponses préparées à partir du code et des contenus actuels ; les validations administratives restent dans App Store Connect.

## Confidentialité

Réponse proposée : **aucune donnée collectée par le développeur depuis l’app**. Aucun serveur propre, analytics, publicité, identifiant publicitaire ni SDK de suivi. Les préférences, records et files d’attente sont locaux. Game Center utilise `gamePlayerID`, pas `teamPlayerID` ; l’app ne collecte pas les amis.

Apple opère l’authentification et les classements. Les scores, temps et identifiants propres au jeu sont traités par Apple. La politique CrocoCross les décrit explicitement. Cette proposition dépend de l’absence de collecte supplémentaire par l’éditeur : ne pas la reprendre si un backend, une extraction de profils ou un outil d’analyse est ajouté. Apple distingue les traitements purement locaux et les données collectées par ses propres services de celles collectées par le développeur. [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/), [identifiants GameKit](https://developer.apple.com/documentation/gamekit/protecting-the-player-s-privacy-using-scoped-identifiers).

- Tracking : **No**. Aucun écran ATT nécessaire.
- Privacy Policy : URL fournie dans chaque langue.
- Privacy Choices : facultatif ; la section choix/suppression de la politique peut servir.
- Assistance volontaire par e-mail : hors du gameplay, limitée aux informations envoyées par l’utilisateur ; expliquée dans la politique.
- Le site GitHub Pages a ses propres requêtes techniques d’hébergement ; pas d’analytics ajouté.

Manifeste iOS : `NSPrivacyTracking=false`, collecte déclarée vide, UserDefaults **CA92.1** pour les préférences de l’app, SystemBootTime **35F9.1** pour les intervalles audio/haptiques et les mesures du moteur Box2D. Pas d’usage de ces horloges pour identifier un appareil. [Raisons autorisées Apple](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).

## Âge : répondre au contenu, laisser Apple calculer

Ne pas recopier le « 4+ » du clavier : le contenu du jeu est différent. Les chutes d’un crocodile et l’explosion sont stylisées, sans sang, blessure détaillée ni violence humaine réaliste.

| Question | Proposition pour la version actuelle |
|---|---|
| Contrôle parental / assurance de l’âge | Non / Non |
| Navigation web illimitée intégrée | Non ; liens externes fixes uniquement |
| Contenu utilisateur / chat / réseaux sociaux | Non ; pas de publication libre ni de flux social dans CrocoCross |
| Publicité | Non |
| Grossièretés, sexualité, nudité, drogues, sujets médicaux | Aucun |
| Horreur / peur | Aucun thème d’horreur ; les chutes sont des échecs de course cartoon |
| Violence cartoon/fantastique | Présente : chutes répétables, explosion finale ; proposer « Frequent » si le questionnaire distingue la fréquence, car elles peuvent survenir à chaque tentative |
| Violence réaliste / sadique / armes | Aucune |
| Concours / compétitions | Présents, fréquents : classement et défi hebdomadaire ; aucun prix monétaire |
| Jeux d’argent / simulation de paris / loot boxes | Aucun |
| Made for Kids | Non |

L’estimation issue de ces réponses peut atteindre **13+ sur les OS 26+**, notamment pour les compétitions fréquentes. Apple calcule aussi des classifications régionales et pour les anciens OS. La fréquence est une appréciation à confirmer sur le gameplay, pas une classification obtenue par cette préparation. [Définitions officielles Apple](https://developer.apple.com/help/app-store-connect/reference/app-information/age-ratings-values-and-definitions).

## Export / chiffrement

`ITSAppUsesNonExemptEncryption=false`. Aucun chiffrement propriétaire ni bibliothèque cryptographique embarquée ; les connexions et protections de stockage utilisent les services système Apple. Choisir l’exemption correspondant uniquement au chiffrement de l’OS si le questionnaire est présenté. Cette configuration ne remplace pas un examen si la cryptographie de l’app change. [Apple : chiffrement](https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance/).

## Droits / identité / distribution

- Éditeur Apple : David Demri, confirmé sur SweetKeyboard Pro et dans le compte App Store Connect.
- Copyright : 2026 Lafayette Consulting, identique à SweetKeyboard Pro.
- David confirme l’origine des illustrations, musiques et du son de chute ; celui-ci est renommé `rider-fall-impact.wav`, audio inchangé. Voir `docs/SOURCE-PROVENANCE.md`.
- Mixkit Fuel Explosion conserve sa licence distincte et son crédit ; Box2D et l’icône Lucide conservent leurs mentions de licence.
- EULA : contrat standard Apple, sauf choix explicite ultérieur de l’éditeur.
- DSA / statut professionnel et adresse : reprendre la déclaration réelle de l’éditeur au niveau du compte. Aucune adresse ni qualité juridique n’a été inventée.
- Accessibilité Store : le jeu respecte Reduce Motion et possède des labels dans les menus ; ne pas revendiquer VoiceOver pour l’intégralité du gameplay sans validation dédiée.
- Disponibilité : choisir les territoires dans le compte. Les pays exigeant une autorisation locale de jeu restent à traiter manuellement ; aucun numéro de licence locale n’est fourni.
