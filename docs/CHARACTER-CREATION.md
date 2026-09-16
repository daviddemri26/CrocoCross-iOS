# Guide de création des personnages

## Silhouette et articulations

Pour la vue de profil de CrocoCross, les membres doivent se chevaucher comme des volumes anatomiques. Une articulation ne doit pas donner l'impression d'une pièce supplémentaire entre le corps et le membre.

- **Bras :** le dessin du haut du bras comprend le volume de l'épaule (deltoïde) et le biceps. Placer le pivot à l'intérieur de ce volume, puis son ancrage haut sur l'épaule du buste. Le haut du bras recouvre l'épaule peinte sur le buste : éviter deux bosses distinctes. Garder une silhouette musclée, avec un coude plus étroit.
- **Cuisse :** inclure la transition vers la fesse dans le haut de la cuisse. Placer le pivot haut et suffisamment en arrière, dans la hanche. La cuisse recouvre la fesse du bassin ; elle ne commence pas en dessous, au bout d'un second segment. Réserver un chevauchement derrière le pivot pour que les rotations ne découvrent pas de trou.
- **Membres éloignés :** les placer derrière le corps et décaler leurs ancrages vers l'intérieur de la silhouette. Ils ne doivent pas former une deuxième épaule au-dessus du dos. Contrôler séparément leur profondeur et leur décalage, sans copier automatiquement ceux de la jambe.
- **Mains et pieds :** conserver leurs appuis au guidon et au repose-pied. La botte possède son propre pivot de cheville ; plier le genou ne doit pas faire plonger sa semelle.
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

Exemple Rocco, build 10 : ancrage épaule sur le buste `(495/1635, 535/962)`, hanche sur le bassin `(1180/1635, 510/962)`. Pivot du haut du bras `(350/1374, 410/1145)`, longueur 0,21 m ; pivot de cuisse `(440/1536, 400/1024)`, longueur 0,30 m. Ces pivots sont à l'intérieur des volumes peints. Voir le manifeste pour les autres points.

## Mouvement et vérification

La présentation reste indépendante des forces physiques. Pour Rocco attaché, conserver la taille raccordée, le buste limité à environ ±20° par rapport à la moto et les mouvements relatifs filtrés. Une rotation complète de la moto reste possible. Après une chute, les corps physiques détachés reprennent la pose.

Avant de réactiver un personnage :

- vérifier transparence, manifeste, longueurs et accès aux appuis avec le contrôle d'assets adapté ;
- inspecter au minimum la pose neutre, le cabrage, l'air, la compression à l'atterrissage et la chute détachée ;
- regarder une séquence en mouvement, y compris une rotation passant par ±π, pour repérer les claquements et les membres qui se croisent ;
- vérifier le cadrage et la lisibilité sur iPhone et iPad ;
- tester le résultat dans le jeu sur téléphone, en distinguant ces essais subjectifs des contrôles automatiques.

Les autres personnages restent désactivés jusqu'à leur adaptation et leur validation. Le guide ne justifie pas de changer la conduite pour réparer un raccord visuel.
