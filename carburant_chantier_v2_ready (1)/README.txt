
Carburant Chantier V2 — Déploiement rapide

Fichiers :
- index.html : application prête à héberger
- schema.sql : tables + sécurité Supabase

Étapes :
1) Dans Supabase > SQL Editor, exécuter schema.sql
2) Héberger index.html sur Vercel / Netlify / GitHub Pages
3) Créer un premier compte dans l’application
4) Dans Supabase > Table Editor > profiles, passer ce premier compte en role = admin
5) Recharger l’application

Déploiement Vercel le plus simple :
- Créer un dossier avec index.html
- Aller sur vercel.com
- New Project
- Import from local folder ou glisser le dossier
- Deploy

Remarques :
- Le compte admin n’est pas auto-créé pour éviter qu’un utilisateur se déclare admin lui-même.
- Les rôles magasinier et pointeur peuvent s’inscrire depuis l’application.
- L’application est en HTML statique, donc simple à héberger et utilisable sur téléphone et PC.
