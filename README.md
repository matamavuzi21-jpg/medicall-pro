# MediCall Pro — v1.0 (Phase 1 : Prototype)

Application professionnelle d'appel de patients pour hôpitaux et centres de santé (RDC).

## Structure du projet

```
lib/
  main.dart                    # Point d'entrée, initialisation Supabase
  theme/app_theme.dart         # Charte graphique (couleurs, police Poppins, Material 3)
  models/patient_call.dart     # Modèle de données PatientCall + ServiceType
  services/
    supabase_service.dart      # Authentification, écriture et écoute temps réel
    tts_service.dart           # Synthèse vocale (multilingue, prêt fr/ln/kg/sw/lu)
  screens/
    login_screen.dart          # Connexion du personnel
    call_patient_screen.dart   # Saisie + appel du patient
    tv_display_screen.dart     # Écran TV salle d'attente (affichage + voix)
```

## Base de données Supabase — table `patient_calls`

```sql
create table patient_calls (
  id uuid primary key,
  patient_name text not null,
  service text not null,
  salle text,
  called_at timestamptz not null default now(),
  status text not null default 'appele',
  called_by text
);

alter table patient_calls enable row level security;

create policy "Le personnel authentifié peut tout faire"
  on patient_calls for all
  using (auth.role() = 'authenticated');

-- Active la réplication temps réel (nécessaire pour l'écran TV)
alter publication supabase_realtime add table patient_calls;
```

## Base de données Supabase — table `profiles` (gestion des utilisateurs)

```sql
create table profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null,
  full_name text not null default '',
  role text not null default 'agent',   -- agent | superviseur | directeur
  service text,
  actif boolean not null default true,
  created_at timestamptz not null default now()
);

alter table profiles enable row level security;

-- Chacun peut lire son propre profil ; superviseurs/directeurs lisent tout.
create policy "Lecture des profils"
  on profiles for select
  using (
    auth.uid() = id
    or exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role in ('superviseur', 'directeur')
    )
  );

-- Seul un directeur peut modifier les rôles et statuts des comptes.
create policy "Modification réservée aux directeurs"
  on profiles for update
  using (
    exists (
      select 1 from profiles p
      where p.id = auth.uid() and p.role = 'directeur'
    )
  );
```

### Edge Function `admin-create-user`

La création d'un compte (auth + profil) nécessite la clé `service_role`,
qui ne doit **jamais** se trouver dans l'application. On déploie donc une
Edge Function côté Supabase :

```bash
supabase functions new admin-create-user
```

```ts
// supabase/functions/admin-create-user/index.ts
import { createClient } from 'jsr:@supabase/supabase-js@2';

Deno.serve(async (req) => {
  const { email, password, full_name, role, service } = await req.json();

  const supabaseAdmin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
  );

  const { data, error } = await supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: true,
  });
  if (error) return new Response(error.message, { status: 400 });

  await supabaseAdmin.from('profiles').insert({
    id: data.user.id,
    email,
    full_name,
    role,
    service,
  });

  return new Response('OK', { status: 200 });
});
```

```bash
supabase functions deploy admin-create-user
```

Cette fonction doit être appelée uniquement par un utilisateur `directeur`
(vérification possible en ajoutant un contrôle du JWT appelant dans la
fonction avant la création).

## Synthèse vocale — langues locales

Langues gérées : français, kiswahili, lingala, kikongo, tshiluba
(`lib/models/app_language.dart`). Le choix est fait via le sélecteur sur
l'écran TV et mémorisé localement (`shared_preferences`).

**Limitation technique à connaître :** les moteurs TTS embarqués
(Android `TalkBack`/Google TTS, iOS, Windows) proposent des voix fiables
pour le **français** et le **kiswahili**, mais **aucun moteur grand public
actuel ne couvre nativement le lingala, le kikongo ou le tshiluba**.

Pour ces trois langues, `TtsService` détecte l'absence de voix
(`isLanguageAvailable`) et bascule automatiquement sur la voix française
pour lire le texte traduit — un rendu imparfait mais toujours plus utile
qu'un silence. Un badge ⓘ prévient l'utilisateur dans le sélecteur.

Deux pistes pour une prononciation native fidèle en production :

1. **Moteur cloud** supportant ces langues (à évaluer : Google Cloud TTS,
   Azure Speech, ou un modèle open-source entraîné sur du lingala/tshiluba)
   — nécessite une connexion internet ou un serveur local à l'hôpital.
2. **Phrases pré-enregistrées** par un locuteur natif pour les segments
   fixes ("est attendu à", "consultation", etc.), combinées à l'épellation
   du nom du patient — fonctionne hors-ligne, qualité constante.

Les traductions actuelles (`lib/services/announcement_builder.dart`) sont
des formulations courantes à faire valider par un locuteur natif de
chaque langue avant déploiement (variantes régionales en RDC).

## Historique des appels

`HistoryScreen` (accessible depuis l'icône 🕓 de l'écran d'appel) permet de
retrouver tout appel passé, avec trois filtres combinables :
- **date** (sélecteur de calendrier, "aujourd'hui" par défaut) ;
- **service** (chips horizontaux : Consultation, Laboratoire, etc.) ;
- **recherche** par nom de patient.

Chaque ligne affiche l'heure, le service, la salle, l'agent qui a passé
l'appel et un badge de statut. Si des appels sont en attente dans la file
hors-ligne locale (voir section précédente), un bandeau orange le signale
en haut de l'écran, car ils n'apparaîtront ici qu'une fois synchronisés.

## Fonctionnement hors-ligne

MediCall Pro reste utilisable même en cas de coupure réseau, avec deux
niveaux de résilience complémentaires :

### 1. File d'attente locale (SQLite) — pour les micro-coupures

Chaque appel patient est **d'abord écrit sur l'appareil** (`LocalDb`,
table `pending_calls`) avant toute tentative d'envoi. Si le réseau est
indisponible au moment de l'appel :
- l'agent voit un badge orange/gris *"Hors-ligne · N en attente"* dans
  l'appBar (`SyncStatusBadge`) plutôt qu'une erreur bloquante ;
- `OfflineQueueService` réessaie automatiquement dès que la connectivité
  revient (`connectivity_plus`), sans action de l'agent.

Cela couvre les coupures Wi-Fi ponctuelles, un serveur temporairement
indisponible, ou un agent qui se déplace dans une zone mal couverte.

### 2. Déploiement en réseau local — pour l'indépendance à Internet

Pour un hôpital sans accès Internet fiable, la recommandation est
d'**auto-héberger Supabase** (`supabase start` via Docker, ou une
installation serveur classique) sur une machine du réseau local de
l'hôpital plutôt que d'utiliser le cloud Supabase. Tous les postes
d'accueil, écrans TV et l'application se connectent alors à l'IP locale
du serveur (Wi-Fi ou Ethernet), et **rien ne transite par Internet** :

```
lib/services/supabase_service.dart
  url: 'http://192.168.1.10:8000'   // IP du serveur local de l'hôpital
```

Avantages : latence quasi nulle, aucune dépendance à un fournisseur
Internet, données médicales qui ne quittent jamais l'établissement.
Inconvénient : nécessite une machine dédiée (mini-PC ou serveur) et une
personne pour la maintenance de base (sauvegardes, mises à jour).

## Tableau de bord du directeur

`DashboardScreen` (icône 📊 depuis l'écran d'appel) donne une vue
d'ensemble de l'activité, pour une date choisie :
- **KPI** : nombre total d'appels du jour, service le plus actif ;
- **Répartition par service** (graphique en barres) ;
- **Répartition par heure de la journée** (24 barres, pics d'affluence) ;
- **Activité par agent**, triée du plus au moins actif.

**Limite actuelle, assumée honnêtement** : le modèle ne capture que
l'heure de l'*appel*, pas l'heure d'arrivée du patient. Un vrai "temps
d'attente moyen" nécessite d'ajouter un ticket d'accueil horodaté à
l'arrivée (évolution future listée dans la roadmap). Le tableau de bord
l'indique clairement à l'utilisateur plutôt que d'afficher un chiffre
inventé.

Sécurité : comme pour la gestion des utilisateurs, l'icône est visible
dans l'UI mais l'accès aux données doit être restreint aux rôles
`superviseur`/`directeur` via une policy RLS sur `patient_calls` (à
ajouter selon le même modèle que celle de `profiles`, voir plus haut).

## Configuration à faire avant le premier lancement

1. Créer un projet sur [supabase.com](https://supabase.com) (ou l'auto-héberger sur le réseau local de l'hôpital pour le mode hors-ligne).
2. Exécuter le SQL ci-dessus dans l'éditeur SQL de Supabase.
3. Remplacer `VOTRE_PROJET` et `VOTRE_CLE_ANON_PUBLIQUE` dans `lib/services/supabase_service.dart`.
4. Créer les comptes du personnel dans Supabase Auth (ou activer l'inscription).

## Lancer le projet

```bash
flutter pub get
flutter run                 # Android / iOS / Windows selon l'appareil connecté
flutter run -d chrome       # Version Web
```

## Prochaines étapes (Phase 2)

- [x] Écran "Historique des appels" avec filtres par service/date
- [x] Gestion des utilisateurs (rôles : agent, superviseur, directeur)
- [x] Sélecteur de langue (fr, sw, ln, kg, lu) branché sur `TtsService`
- [ ] Tableau de bord temps d'attente par service
- [x] Mode réseau local (Supabase self-hosted) pour fonctionnement hors-ligne
- [ ] Logo définitif (SVG) : croix médicale + ondes sonores + cercle de flux
