# Threat Model — Rootpath

## 1. Assets (ce qu'on protège / ce qui a de la valeur dans le scénario)

- Le compte `root` et ses privilèges complets sur la VM cible.
- Les données synthétiques du labo : `user.txt` et `root.txt` (flags).
- L'intégrité de la tâche planifiée exécutée par root (cron/systemd timer).
- La configuration sudo de l'opérateur (`operator`).
- La VM elle-même : elle ne doit jamais devenir un pivot vers la machine hôte ou vers un autre réseau.

## 2. Threats (menaces considérées)

| # | Menace | Description |
|---|--------|--------------|
| T1 | Injection de commande OS | Un attaquant envoie une entrée malveillante à la fonctionnalité "ping" de l'application web pour exécuter des commandes arbitraires en tant que `websvc`. |
| T2 | Abus de tâche planifiée root | Depuis le compte `websvc`, l'attaquant modifie un script/fichier exécuté par root via cron pour obtenir une exécution de code en root. |
| T3 | Abus de règle sudo restreinte | Depuis un accès `operator`, l'attaquant détourne le script de sauvegarde autorisé en sudo pour lire/écrire des fichiers arbitraires en root. |
| T4 | Évasion vers l'hôte (hors scope, à prévenir) | Un attaquant tente de sortir de la VM pour atteindre la machine hôte ou le réseau de production. |

(T4 n'est pas un objectif pédagogique du labo — c'est une menace qu'on doit activement empêcher, pas un chemin d'attaque prévu.)

## 3. Threat actor / attacker profile

- Un étudiant/apprenant local, avec un accès réseau à la VM cible (via le réseau privé host-only) mais sans accès physique ni identifiants valides au départ.
- Il dispose d'outils standards : navigateur, `curl`, client SSH, utilitaires Linux classiques.
- Il n'a pas accès à des exploits kernel ni à des frameworks d'exploitation automatisés (interdit par le sujet, IV.1).

## 4. Assumptions (hypothèses)

- La VM tourne uniquement sur un réseau privé/host-only, jamais exposée à Internet ou à un réseau de production (IV.1).
- Toutes les données (comptes, flags, logs) sont synthétiques — aucune donnée réelle n'est en jeu.
- L'attaquant n'a pas de contrôle sur l'hyperviseur ni sur la machine hôte.
- Le poste attaquant est distinct de la cible (pas de test en localhost uniquement).

## 5. Isolation controls (contrôles mis en place)

- Réseau **privé/host-only** dédié (`192.168.56.0/24`), pas de bridge public.
- Le service web tourne sous l'utilisateur dédié `websvc`, jamais en root.
- Aucun montage de socket Docker, pas de conteneur privilégié, pas de montage complet du système de fichiers hôte (IV.1).
- Pas d'accès Internet requis après déploiement (fonctionnement hors-ligne possible).

## 6. Potential misuse (usage détourné à surveiller)

- Le labo ne doit être utilisé que dans un cadre d'entraînement local autorisé. Toute utilisation des techniques enseignées ici contre des systèmes tiers, d'entreprise ou publics est strictement interdite et hors du périmètre du projet (cf. Introduction du sujet).