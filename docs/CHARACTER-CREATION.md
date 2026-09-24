# Guide de création des personnages

## Silhouette et articulations

Pour la vue de profil de CrocoCross, les membres doivent se chevaucher comme des volumes anatomiques. Une articulation ne doit pas donner l'impression d'une pièce supplémentaire entre le corps et le membre.

- **Bras :** le dessin du haut du bras comprend le volume de l'épaule (deltoïde) et le biceps. Placer le pivot à l'intérieur de ce volume, puis son ancrage haut sur l'épaule du buste. Le haut du bras recouvre l'épaule peinte sur le buste : éviter deux bosses distinctes. Garder une silhouette musclée, avec un coude plus étroit.
- **Cuisse :** inclure la transition vers la fesse dans le haut de la cuisse. Placer le pivot haut et suffisamment en arrière, dans la hanche. La cuisse recouvre la fesse du bassin ; elle ne commence pas en dessous, au bout d'un second segment. Réserver un chevauchement derrière le pivot pour que les rotations ne découvrent pas de trou.
- **Membres éloignés :** les placer derrière le corps et décaler leurs ancrages vers l'intérieur de la silhouette. Ils ne doivent pas former une deuxième épaule au-dessus du dos. Contrôler séparément leur profondeur et leur décalage, sans copier automatiquement ceux de la jambe.
- **Mains et pieds :** conserver leurs appuis au guidon et au repose-pied. Pour la main, utiliser le centre de prise dans la paume, pas les jointures ou le bout des doigts. Aligner ce point sur la poignée réellement visible, puis vérifier que les deux bras atteignent leur cible dans toute la plage de mouvement. La botte possède son propre pivot de cheville ; plier le genou ne doit pas faire plonger sa semelle.
- **Taille :** conserver un point de raccord commun entre bassin et buste. Pas de séparation ou d'étirement de la taille pendant une réception.

Ces règles sont les préférences explicites de David, précisées lors des essais de Rocco du 16 septembre 2026. Adapter les proportions aux futurs personnages ; les coordonnées de Rocco ne sont pas universelles.

## Préparer les dessins

Créer des calques transparents cohérents en perspective, lumière, contours et costume : buste/tête, bassin/queue, haut du bras avec épaule, avant-bras/main, cuisse avec volume de fesse, mollet et botte. Les extrémités cachées restent complètes et arrondies pour permettre les rotations. Éviter de dessiner une articulation supplémentaire déjà fixée sur le buste ou le bassin.

Conserver les PNG sources et leur provenance. Décrire les générations/modifications dans les prompts du personnage et enregistrer les dimensions et empreintes des images retenues. Ajuster d'abord les ancrages et la calibration dans le manifeste. Si un dessin ne contient pas les volumes nécessaires, retravailler le calque ; un déplacement de pivot ne peut pas créer une épaule absente.

## Calibrer le rig

1. Garder la moto et ses dimensions physiques comme référence. Ajuster le personnage sans changer les sensations de conduite.
2. Définir les points normalisés `pivot`, `proximal`, `distal`, `shoulder`, `hip`, `spine` et les appuis nécessaires. Les coordonnées du manifeste partent du coin supérieur gauche de chaque PNG.
3. Pour un membre, faire coïncider `pivot` et `proximal`, puis reporter les mêmes extrémités dans `calibration` et `orientation`. Mesurer la longueur entre articulations, pas la longueur totale du dessin, qui dépasse derrière le pivot.
4. Régler la longueur avant l'épaisseur. Un épaississement transversal peut renforcer la musculature sans déplacer les articulations ; ne pas étirer le membre en fonction de la suspension.
5. Choisir la longueur des deux segments pour atteindre les appuis dans toutes les postures autorisées. Prévoir une marge afin d'éviter un coude ou un genou soudainement tendu à fond.
6. Vérifier le recouvrement épaule/bras et fesse/cuisse à l'échelle du jeu, puis en gros plan. Le rig proche doit masquer les raccords du corps et les membres éloignés.

Exemple Rocco, build 11 : ancrage épaule sur le buste `(465/1635, 535/962)`, hanche sur le bassin `(1145/1635, 575/962)`. Pivot du haut du bras `(350/1374, 410/1145)`, longueur 0,21 m ; pivot de cuisse `(440/1536, 400/1024)`, longueur 0,30 m. Ces pivots sont à l'intérieur des volumes peints. Après le premier raccord, affiner par petits déplacements : la correction de la build 11 abaisse et recule légèrement la hanche et recule le bras, selon la référence annotée de David. Ne pas remonter systématiquement davantage une articulation déjà bien intégrée. Voir le manifeste pour les autres points.

## Mouvement et vérification

La présentation reste indépendante des forces physiques. Pour Rocco attaché, conserver la taille raccordée, le buste limité à environ ±20° par rapport à la moto et les mouvements relatifs filtrés. Une rotation complète de la moto reste possible. Après une chute, les corps physiques détachés reprennent la pose. Les bras et les jambes libérés utilisent `DetachedLimbMotion` : inertie et amortissement cosmétiques, angles initialisés depuis la pose attachée, coudes/genoux limités et pivots toujours raccordés. L’horloge vient des pas physiques interpolés de `GameSession` (ralenti et pause inclus), jamais du temps du décor ou des coordonnées écran. La conduite, les collisions et la trajectoire des corps Box2D restent inchangées.

Avant de réactiver un personnage :

- vérifier transparence, manifeste, longueurs et accès aux appuis avec le contrôle d'assets adapté ;
- inspecter au minimum la pose neutre, le cabrage, l'air, la compression à l'atterrissage et la chute détachée ;
- regarder une séquence en mouvement, y compris une rotation passant par ±π, pour repérer les claquements et les membres qui se croisent ;
- vérifier le cadrage et la lisibilité sur iPhone et iPad ;
- tester le résultat dans le jeu sur téléphone, en distinguant ces essais subjectifs des contrôles automatiques.

Les autres personnages restent désactivés jusqu'à leur adaptation et leur validation. Le guide ne justifie pas de changer la conduite pour réparer un raccord visuel.

Build 12 : la prise de Rocco est calibrée à `(1000/1634, 190/962)` sur la moto et `(1020/1536, 785/1024)` dans la paume. Le point `contact` coïncide avec `distal`, la calibration et l’orientation de l’avant-bras. Sa longueur jusqu’à la prise est 0,28 m. Un contrôle natif suit les deux paumes par rapport à leurs poignées pendant 180 images et dans les poses de réception/cabrage.

## Corrections anatomiques de Kenji — à réutiliser pour les prochains personnages

Consignes explicites de David, 22 septembre 2026 :

- **Préserver ce qui est validé.** Pour Kenji, la tête, le buste, le biceps, l'avant-bras et la main sur le guidon sont approuvés. Une correction du bassin ou de la botte ne doit pas déplacer silencieusement cette partie haute. Conserver le même point de taille dans l'espace lors du remplacement d'un calque.
- **Bassin strictement de profil.** Dessiner une seule fesse/hanche vue de côté. Ne pas montrer deux fesses comme dans une vue de dos ou un short vu de trois quarts arrière. Le premier bassin de Kenji donnait la bonne direction de profil ; la version à deux lobes a été rejetée.
- **Pas de jambe dans le bassin.** Le calque bassin/queue ne contient ni morceau de cuisse, ni moignon cylindrique, ni prolongement de jambe. La cuisse séparée rentre profondément dans la hanche, bien en arrière, près de l'attache de la queue. Le chevauchement doit former un seul volume, sans raccord rapporté.
- **Taille et queue.** Soigner la continuité buste/fessier. La queue doit rester visible derrière le personnage, naturellement rattachée et dégagée du buste. Le raccord taille/bassin ne doit pas ressembler à deux dessins collés.
- **Transparence réelle et propre.** Contrôler les contours sur fonds clairs et sombres. Un canal alpha présent ne suffit pas : aucun halo brun, bleu ou noir autour de la queue, du pelage ou des vêtements. Ajuster le dessin et les couleurs du pelage, conserver les sources générées intactes et noter les variantes rejetées.
- **Entrée du tibia dans la botte.** Le pivot de cheville est dans l'ouverture supérieure de la botte, jamais dans sa pointe, son avant ou un simple disque décoratif latéral. Le tibia doit rentrer par le dessus avec un chevauchement peint. Une rotation maîtrisée de la botte est possible pour respecter l'anatomie, en gardant l'appui sur le repose-pied.
- **Mesures et regard visuel.** Une erreur numérique nulle sur l'appui ne prouve pas que l'anatomie est correcte. Vérifier aussi l'axe tibia/ouverture, l'insertion du haut de cuisse, le contour de la fesse et la visibilité de la queue en pose neutre, cabrage, réception, rotation et chute, en gros plan et à l'échelle du jeu.

Ces consignes complètent les règles de Rocco ci-dessus et doivent guider chaque futur personnage. Ne pas recopier ses coordonnées, ses masques ou son épaississement musculaire sur un autre animal.
