# Rubis et le Royaume des Amis

Jeu de plateforme 2D (Godot 4). Tous les dessins sont générés par code : aucune image ni extension n'est nécessaire.

## Ouvrir le projet
1. Décompresse l'archive.
2. Ouvre Godot 4.x, clique sur **Import**, choisis `project.godot`, puis **Import & Edit**.
3. Appuie sur **F5**, puis sur **COMMENCER L'AVENTURE**.

## Histoire
Rubis le chevalier, Robin l'archère, Mira la magicienne et Bolt le robot vivent en paix dans le royaume de Verdalia.
Le monstre Grogoth capture Robin, Mira et Bolt. Rubis, seul libre, doit traverser 6 niveaux pour les sauver.
Cinq scènes animées racontent l'histoire avant le jeu (bouton « PASSER L'HISTOIRE » disponible). À la fin, deux scènes finales : la libération (Grogoth s'effondre, les cages s'ouvrent, les amis courent vers Rubis) puis une animation de victoire (feux d'artifice, confettis, couronne).

## Les personnages
| Personnage | Rôle |
| --- | --- |
| Rubis (rouge) | Chevalier, le héros que tu contrôles |
| Bolt (jaune) | Robot, ami prisonnier du niveau 2 |
| Robin (vert) | Archère, amie prisonnière du niveau 4 |
| Mira (violet) | Magicienne, amie prisonnière du niveau 6 |
| Grogoth | Monstre des ombres, boss final (4 coups sur la tête) |
| Gluants, gobelins, chauves-souris | Ennemis (sauter dessus pour les vaincre) |

## Les niveaux
| Niveau | Difficulté | Contenu |
| --- | --- | --- |
| 1 - Les Collines Vertes | FACILE | Apprendre à courir et sauter, gluants lents |
| 2 - Le Sentier des Gluants | FACILE | Libérer Bolt |
| 3 - La Forêt Murmurante | MOYEN | Gobelins plus rapides, plus de pics, plateforme dans un gouffre |
| 4 - La Clairière Hantée | MOYEN | Pont de plateformes au-dessus du vide, libérer Robin |
| 5 - Les Gorges Sombres | DIFFICILE | Grands sauts, pics en série, chauves-souris |
| 6 - L'Antre de Grogoth | DIFFICILE | Derniers gouffres, combat contre Grogoth, libérer Mira |

## Commandes
| Touche | Action |
| --- | --- |
| Flèches, ou Q / D (clavier AZERTY) | Se déplacer |
| F, X ou K | Tirer un rayon de lumière (après avoir pris l'épée au niveau 6) |
| Espace, Z ou flèche haut | Sauter (maintenir = saut plus haut) |
| P ou Échap | Pause |
| R | Recommencer le niveau |
| M | Couper / remettre la musique |
| + / - (pavé numérique ou touches = et -) | Volume de la musique +10 % / -10 % |

Les touches lettres sont basées sur la position physique des touches : sur un clavier QWERTY, ce sont A / D / W.

## Règles
- Sauter sur un ennemi par le haut le vainc ; le toucher de côté, toucher des pics ou tomber coûte une vie.
- 3 vies par niveau. Les drapeaux sont des points de passage.
- Chaque niveau cache **3 clés**. Avec les 3 clés, la cage de l'ami se déverrouille (il suffit alors de la toucher). Dans les niveaux sans ami, les 3 clés ouvrent le portail de sortie.
- Au niveau 6, ramasse l'**Épée de lumière** sur son socle à l'entrée de l'arène : elle tire des rayons (F / X) qui blessent Grogoth et tuent les ennemis. Sauter sur sa tête marche toujours. Grogoth a 6 points de vie : il faut le vaincre pour ouvrir la cage de Mira.
- Clé : 100 pts, ennemi : 50 pts, ami libéré : 200 pts, Grogoth : 500 pts.

## Sons et musique
Tout est généré par code (aucun fichier audio). Bruitages : saut, clé, ennemi écrasé, rayon de lumière, épée, coup sur Grogoth, point de passage, ami libéré, dégâts, défaite, niveau terminé, victoire, boutons.
Musique : un thème doux pour le titre et l'histoire, puis un thème par difficulté (vert, crépuscule, nuit maudite).
Le volume de la musique se règle avec le curseur « MUSIQUE » des menus (titre, pause, etc.) ou avec M, + et -. Le réglage est mémorisé (`user://rubis_settings.cfg`).

## Interface
- `scripts/hud_bar.gd` : barre du haut (niveau, difficulté, vies, clés, amis, score, guide des touches). La bordure suit la couleur de la difficulté.
- `scripts/frame_panel.gd` : cadre des menus (pierre sombre, bordure dorée, rubis aux coins, ruban pour le titre, couleurs différentes pour titre, pause, niveau terminé, défaite et victoire).
- `scripts/ui_style.gd` : style des boutons et du curseur de volume.
- `scripts/sfx.gd` : bruitages, musiques et réglage du volume.

## Modifier le jeu
- `scripts/art.gd` : dessin des personnages (Rubis, amis, ennemis, Grogoth), de la clé et de la cage.
- `scripts/scenery.gd` : décors pixel art (forêt mystérieuse, étangs, blocs, herbe, plantes, lucioles) et 3 palettes (jour, crépuscule, nuit maudite).
- `scripts/cutscene.gd` : textes et dessins des scènes d'histoire (tableau `SCENES`).
- `scripts/game.gd` : les niveaux (fonctions `build_0` à `build_5`), les textes et la logique du jeu.
- `scripts/player.gd` : vitesse (`SPEED`), saut (`JUMP_SPEED`), gravité.

Dans `build_N`, `ground(a, b)` crée un sol, `plat(x, y, largeur)` une plateforme, `spikes(x, largeur)` des pics,
`add_key(x, y)` place une clé, `foe(type, x, hauteur, gauche, droite, vitesse)` un ennemi (0 gluant, 1 gobelin) et `bat(...)` une chauve-souris.
