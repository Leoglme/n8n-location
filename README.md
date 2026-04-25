# n8n Rental Listings Monitor

Automated rental listing monitoring with [n8n](https://n8n.io). The workflow checks listing sites on a schedule, filters by your criteria, stores results in Google Sheets, and sends Telegram notifications for new listings (with AI-generated summaries via Groq).

**Currently supported:**
- **Bienici** (API `realEstateAds.json` ; `zoneIdsByTypes.zoneIds` = **`zone_ids_bienici`** dans la Config, défaut **-7465** = Ille-et-Vilaine côté Bienici ; autres critères: prix, pièces, surface, etc. depuis la Config)
- **Trente Cinq Notaires** (annonces notaires, page Bruz — scraped from HTML, locations only)
- **Action Logement** (API, 50 km autour de Rennes, T2/T3, loyer max depuis Config)
- **Giboire** (Bretagne / Pays de la Loire — scraped from HTML; filtres depuis Config: prix max, surface min/max, nombre de chambres 1 = T2, 2 = T3)
- **Afedim** (Ille-et-Vilaine — scraped from HTML; filtres depuis Config: pièces min/max, surface min/max, budget max)
- **Cogir Immobilier** (cogir.fr, endpoint `data_listing_formrecherche.html` ; location maison/appartement, T2–T3, filtres depuis Config: surface min/max et loyer max)
- **Néotoa** (neotoa.fr, page de recherche HTML ; location maison/appartement T2–T3, filtres depuis Config: loyer max via paramètre `budget`)
- **CDC Habitat** (cdc-habitat.fr, page de recherche HTML Ille-et-Vilaine ; location appartement/maison T2–T3, filtres depuis Config: loyer max via `nbLoyerMax`)
- **Oqoro** (oqoro.com, page de recherche HTML avec `data-lots` JSON ; bbox **étendu** (carte, pas rayon), location non meublée T2–T3, filtres depuis Config: loyer max et surface min/max)
- **Century 21** (century21.fr, page annonces HTML ; Ille-et-Vilaine d-35_ille_et_vilaine ; filtres depuis Config: surface min/max, prix max, pièces min/max via URL s-/b-/p-)
- **Blot Immobilier** (blot-immobilier.fr, POST `admin-ajax.php` : `search_form_validate` pour les IDs puis `view_result` pour le HTML des cartes ; Ille-et-Vilaine 35, location maison + appartement ; filtres depuis Config : `estate_rentmax`, surfaces, `estate_nb_rooms`, même structure de formulaire que le site)
- **Citya Immobilier** (citya.com, GET liste location appartement + maison Ille-et-Vilaine ; paramètres d’URL `prixMax`, `surfaceMin`, `nbrePiecesMin` depuis Config ; parsing JSON-LD `application/ld+json`, repli sur le DOM `#list_results`)
- **Laforêt** (laforet.com, GET `/louer/rechercher` ; Rennes 35238 + rayon 50 km fixe dans l’URL, types maison + appartement ; `filter[max]`, `filter[rooms]`, `filter[surface]` depuis Config ; parsing HTML des cartes `article.min-w-0`, loyer affiché traité comme CC, déduplication par `data-counter-id-value`, y compris blocs « à proximité »)
- **Cabinet Rolland & Girot** (cabinet-rolland-girot.com, GET `/location/appartement--maison?price=` ; seul `price` = `prix_max_cc` depuis Config ; parsing HTML `article.node--realestate--teaser`, `id_site` = référence agence ex. `5480SN`, loyer carte = CC, surface/pièces via `field--surface` / `field--rooms`, pas de pagination côté workflow)
- **Notaire & Breton** (notaireetbreton.bzh, GET liste location appartement + maison individuelle Ille-et-Vilaine ; `field_price_value[max]` = `prix_max_cc`, `field_living_space_value[min]` = `surface_min_m2` depuis Config ; vignettes Drupal puis **une requête par fiche** pour surface, pièces, loyer + charges (CC), meublé ; exclusion si description ou HTML contient collocation / colocation ; `id_site` = `data-history-node-id`)
- **Ouest France Immo** (API `ouestfrance-immo.com/api/annonces` ; **Ille-et-Vilaine 35** entier, `url=/louer/ille-et-vilaine-35/`, `idslieu=535` ; filtres depuis Config: pièces min, surface min/max, prix max ; tri date_desc, pas de pagination)
- **Foncia** (API fnc-api.prod.fonciatech.net ; **Ille-et-Vilaine 35** entier via `localities.slugs: ille-et-vilaine-35` ; filtres depuis Config: pièces min/max, surface min/max, prix max)
- **La Française Immobilière** (scraped from HTML ; toutes annonces, pas de filtre ville côté site ; Config: nb_chambres min/max = pièces−1, prix max ; tri date-desc)
- **Guenno Immobilier** (API guenno.com/biens/recherche ; `town=RENNES` ; `realty_type` 1+2 (appartement + maison) ; bbox `north`/`south`/`east`/`west` large (zone étendue) ; Config: pièces min/max, prix max, surface min)
- **Lamotte** (lamotte.fr/annonces ; dép. 35, HTML ; Config: pièces min/max, prix max, surface min/max)
- **Kermarrec Habitation** (kermarrec-habitation.fr/location ; **sans** filtre `ville` ni `rayon` — liste type Grand Ouest sur le site ; HTML ; Config: pièces min/max, prix max)
- **Nestenn** (nestenn.com/listing ; 35 Ille-et-Vilaine, HTML ; Config: pièces min/max, prix max, surface min)
- **Square Habitat** (API `api.ca-immobilier.fr` — `POST` vers `…/arts/bien/v2/api/fo/bien` ; `localisations.codesDepartements: ['35']` — Ille-et-Vilaine, **sans** commune ni rayon ; Config: pièces min/max, prix max, surface min/max)
- **Immonot** (immonot.com, annonces notaires / HTML `il-card--LOCA` ; critères alignés sur la recherche location, parsing des cartes liste)
- **Cesson Immobilier** (cesson-immobilier.fr, page `louer-a-cesson.php` + fiches détail pour compléter loyer / surface / pièces)
- **Villejean Beauregard Immobilier** (villejean-beauregard-immobilier.fr, `catalog/advanced_search_result.php` + parsing des annonces)
- **Logic-Immo** (logic-immo.com, agrégateur : POST `serp-bff/search` puis GET `classifiedList/…` ; polygone ~50 km Rennes, critères Config pièces / surface / prix max, cookie optionnel `logic_immo_cookie` ; champs normalisés depuis `rawData`, `tracking`, `mainDescription`, etc.)
- **Lamy Immobilier** (lamy-immobilier.fr, GET `/_ajax/our_ads` : réponse JSON + fragment HTML `itemsListHtml` ; filtre `Ille-et-Vilaine`, `rental`, appartement+maison, bbox carte, pièces / loyer / surface min depuis la Config ; `source`: `lamy_immobilier`)
- **Parthenay Immobilier** (parthenay-immobilier.fr, POST `data_listing-location_formrecherchelocation.html` : JSON `data.resultats.data` + HTML `output` ; `surfacemin` / `prixmax` depuis la Config ; filtre T2–T3 sur le champ `piece` **après** la réponse — pas de filtre pièces côté formulaire ; une seule requête, **pas** de surface max ni de pagination côté workflow ; `source`: `parthenay_immobilier`)
- **Dany Richard Immobilier** (dany-richard-immo.com, GET [`/location/`](https://www.dany-richard-immo.com/location/) : pas de filtre côté site — pré-filtre sur la liste, **une requête par fiche** restante, parsing `.product--attributes` (surface, loyer + charges, référence) ; excl. parkings sur l’URL ; `source`: `dany_richard`)
- **Cabinet Chateaubriand** (cabinetchateaubriand.com, GET [`/recherche-de-bien/`](https://www.cabinetchateaubriand.com/recherche-de-bien/) avec `status[]=location`, `max-price` / `min-area` (et `max-area` si renseigné) depuis la Config ; HTML **RealHomes** `rh-ultra-list-card` : lien `/bien/…`, titre, loyer, ville, surface, pièces (titre / T2) ; `source`: `cabinet_chateaubriand`)
- **Arthurimmo.com** (réseau national, GET [`recherche,basic.htm`](https://www.arthurimmo.com/recherche,basic.htm) avec `transactions=louer`, `localization=Ille-Et-Vilaine (35)`, `pieces[]` de `pieces_min` à `pieces_max`, `max_price` = `prix_max_cc`, `min_surface` / `max_surface` depuis la Config ; HTML cartes annonces `arthurimmo.com/annonces/location/…/id.htm` ; `source`: `arthurimmo`)
- **Agence MPI** (agencempi.com, GET `catalog/advanced_search_result.php` avec `C_28=Location`, `C_27` / `C_27_tmp` = **types de bien** fixes **1+2** (appartement + maison) — *pas* le nombre de pièces, `C_33_MIN` / `C_33_MAX` = `pieces_min` / `pieces_max`, `C_31_MAX` = `prix_max_cc`, `C_34_MIN` / `C_34_MAX` = surface ; **User-Agent** type navigateur obligatoire sur la requête ; parse `div.listing-item` / `fiches/…`, `data-productId`, `id_site` = réf. agence si présente ; `source`: `agence_mpi`)
- **Nicolazo Notaires** (nicolazo.notaires.fr, nœud **Code** : GET page liste → cookies `Set-Cookie` + `_token` dans le HTML → GET filtrée `LOCATION`, `prix_max_cc`, `pieces_min` / `pieces_max`, surface, `parPage=20` ; parse `bloc-annonce` **location** uniquement, loyer `€ / mois`, lien `detail-annonces-immobilieres-…/id.html` ; `source`: `nicolazo_notaires`)
- **Inova Immo** (inova-immo.com, GET `recherche-des-biens` avec `status[]=location`, `type[]=appartement|maison`, `max-price` = `prix_max_cc`, `min-area` = `surface_min_m2` ; parse cartes `rh-ultra-list-card-*`, prix `€ / par mois`, surface, pièces via titre `T2/T3…` ; `source`: `inova_immo`)
- **Stella At Home** (stella-at-home.fr, GET `catalog/advanced_search_result.php` avec paramètres `C_*` + **User-Agent navigateur obligatoire** ; parse `div.listing-item` / `fiches/…`, `data-productId`, prix `product-price`, surface/pièces `data-list__item--*` ; exclusion colocation ; `source`: `stella_at_home`)
- **Keredes** (keredes.coop, GET `location/ancien` avec query `price_max`, `surface_min`, `rooms[]` = `pieces_min`..`pieces_max`, département 35 ; parse liens `a.bienCard`, prix `€ / mois`, surface, pièces depuis titre ; `source`: `keredes`)
- **Loquin Immobilier** (immobilier-liffre.com, **2 requêtes** : GET liste `index.php?action=list&ctypmandatmeta=l` (prix+surface depuis Config) → extraire URLs `/fr/annonces-immobilieres/offre/.../bien/<id>/...html` → GET détail pour loyer CC / charges / surface / pièces / ville ; `source`: `loquin_immobilier`)

**Maintenance :** à chaque **nouvelle agence ou source** branchée dans le workflow, ajouter une puce ici (**Currently supported**), mettre à jour **What it does** (étape 2 si besoin), **Project structure**, la chaîne de **Fusion** ci-dessous, et le paramétrage Config si un nouveau champ apparaît.

---

## What it does

1. **Runs on a schedule** (e.g. every 30 seconds for testing; you can change this in the workflow).
2. **Fetches listings** from Bienici, Trente Cinq Notaires, Action Logement, Giboire, Afedim, Ouest France Immo, Foncia, La Française Immobilière, Guenno Immobilier, Lamotte, Kermarrec Habitation, Nestenn, Square Habitat, Cogir Immobilier, Néotoa, CDC Habitat, Oqoro, Century 21, Blot Immobilier, Citya Immobilier, Laforêt, Cabinet Rolland & Girot, Notaire & Breton, Immonot, Cesson Immobilier, Villejean Beauregard Immobilier, Logic-Immo, **Lamy Immobilier**, **Parthenay Immobilier**, **Dany Richard Immobilier**, **Cabinet Chateaubriand**, **Arthurimmo.com (Ille-et-Vilaine 35)**, **Agence MPI**, **Nicolazo Notaires**, **Inova Immo**, **Stella At Home**, **Keredes**, and **Loquin Immobilier** ; **Bienici** : `zone_ids_bienici` défaut -7465, Ille-et-Vilaine + critères Config ; Trente Cinq Notaires: page 1, locations only; Action Logement: API, 50 km Rennes, T2/T3, max rent from Config; Giboire: Ille-et-Vilaine 35, price/surface/rooms from Config; Afedim: Ille-et-Vilaine, pièces/surface/budget from Config; Ouest France Immo: API Ille-et-Vilaine 35 (département, idslieu 535), pièces/surface/prix from Config, tri date_desc; Foncia: API Ille-et-Vilaine 35 (slug département), pièces/surface/prix from Config; La Française Immobilière: HTML, nb_chambres/prix from Config, tri date-desc; Guenno: API Rennes, `realty_type` 1+2, bbox large (N/S/E/O), pièces min/max, prix max, surface min from Config; Lamotte: HTML dép. 35, pièces/surface/prix from Config; Kermarrec: HTML sans ville/rayon, pièces/prix from Config; Nestenn: HTML 35 Ille-et-Vilaine, pièces/prix/surface from Config; Square Habitat: API département 35 (Ille-et-Vilaine), `codesDepartements`, pièces/surface/prix from Config; Cogir: API form-urlencoded avec surface/prix depuis Config; Néotoa: HTML avec budget max depuis Config; CDC Habitat: HTML Ille-et-Vilaine avec budget max depuis Config; Oqoro: HTML avec `data-lots` JSON, bbox large, loyer/surface depuis Config; Century 21: HTML annonces Ille-et-Vilaine, surface/prix/pièces depuis Config via URL; Blot: deux requêtes AJAX `search_form_validate` + `view_result`, loyer max et critères alignés sur le formulaire location; Citya: GET catalogue Ille-et-Vilaine avec `prixMax` / `surfaceMin` / `nbrePiecesMin` depuis Config, extractions JSON-LD puis liste HTML; Laforêt: GET recherche location Rennes + 50 km, budget / pièces min / surface min depuis Config, parsing des vignettes HTML, loyer carte = CC; Rolland Girot: GET `/location/appartement--maison`, `price` = loyer max depuis Config, parsing `node--realestate--teaser`, `id_site` = référence agence, loyer carte = CC; Notaire & Breton: GET liste 35 avec prix max et surface min dans l’URL, puis fetch fiche pour caractéristiques, loyer CC = loyer + charges si présents, exclusion collocation ; Immonot, Cesson Immobilier, Villejean Beauregard, Logic-Immo, Lamy (`/_ajax/our_ads`, `itemsListHtml`), Parthenay (POST `data_listing-location_formrecherchelocation`, filtre `piece` en post-traitement), Dany Richard (liste + fiches), Chateaubriand (recherche location + parse cartes), Arthurimmo (recherche département 35, parse cartes liste), Agence MPI (`advanced_search_result` + parse `listing-item`) : voir **Currently supported**).
3. **Filters** results by your criteria (cities, neighbourhoods, min/max price, surface, etc.).
4. **Deduplicates** against a Google Sheet: only listings not already in the sheet are processed.
5. **Saves** new listings to the sheet and **sends a Telegram message** with a short summary generated by Groq (LLM).

---

## Requirements

- [Docker](https://docs.docker.com/get-docker/) and Docker Compose
- **Telegram**: a bot token (from [@BotFather](https://t.me/BotFather)) and the chat ID where you want notifications
- **Groq**: an API key from [console.groq.com](https://console.groq.com) (used for message summaries)
- **Google Sheets**: OAuth2 credentials (Client ID + Client Secret) for the Google Sheets node in n8n

---

## Quick start

### 1. Clone and configure environment

```bash
git clone <your-repo-url>
cd n8n-location
cp .env.example .env
```

Edit `.env` and set:

| Variable | Description |
|----------|-------------|
| `N8N_ENCRYPTION_KEY` | Long random string for n8n encryption (e.g. 64 hex chars). |
| `TELEGRAM_BOT_TOKEN` | Your Telegram bot token. |
| `GROQ_API_KEY` | Your Groq API key (no `Bearer ` prefix). |
| `GOOGLE_OAUTH_CLIENT_ID` | Google OAuth2 client ID for Sheets. |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Google OAuth2 client secret. |

### 2. Start n8n

```bash
docker compose up -d
```

### 3. Open n8n and complete setup

1. Open **http://localhost:5678** in your browser.
2. Log in with the basic auth user/password from `docker-compose.yml` (default: `admin` / `change_me`).
3. On first run, create your n8n owner account. The entrypoint script will then import the workflow from `workflows/recherche_appart_rennes.json` if present.
4. In the workflow **"Recherche Appart Rennes T2/T3"**:
   - Set the **Google Sheets** credential (OAuth2 with your Client ID/Secret from `.env`).
   - Link the workflow to your Google Sheet (document ID and sheet name).
   - **Activate** the workflow (toggle **Active** so the schedule trigger runs).

Search criteria (price, surface, rooms, cities, `zone_ids_bienici` for Bienici) are defined in the **Config critères (défaut)** node and drive the Bienici API URL and the filters applied to listings.

---

## Project structure

```
n8n-location/
├── docker-compose.yml    # n8n service, env, volumes
├── docker-entrypoint.sh  # First-run: wait for owner, import workflow
├── .env.example          # Template for required env vars
├── .env                  # Your secrets (not committed)
├── workflows/
│   └── recherche_appart_rennes.json   # Main workflow (all sources in "Currently supported", incl. Immonot, Cesson, Villejean Beauregard, Logic-Immo, Lamy, Parthenay, Dany Richard, Chateaubriand, Arthurimmo, Agence MPI, Nicolazo Notaires, Inova Immo, Stella At Home, Keredes, Loquin Immobilier, + Sheet + Groq + Telegram)
├── .github/workflows/
│   └── deploy-n8n.yml    # Optional: deploy to VPS on push
└── README.md
```

---

## Changing the schedule

In the n8n editor, open the **Cron - Vérif annonces** node and adjust the interval (e.g. seconds for testing, or switch to minutes/hours for production). Save and keep the workflow **Active**.

---

## Adding more listing sources later

The workflow already has merge nodes that combine:

- **Fusionner branches:** Bienici + Trente Cinq Notaires (Bienici: API `realEstateAds.json`, `zone_ids_bienici` = -7465 / 35 ; TCN: HTTP → parse/transform to common format).
- **Fusionner branches 2:** above + Action Logement (POST API → same format).
- **Fusionner branches 3:** above + Giboire (HTTP page recherche location → parse HTML → same format; filters from Config: price, surface, rooms; 1 chambre = T2, 2 chambres = T3).
- **Fusionner branches 4:** above + Afedim (HTTP page location Ille-et-Vilaine → parse HTML → same format; filters from Config: pièces, surface, budget).
- **Fusionner branches 5:** above + Ouest France Immo (API annonces Ille-et-Vilaine 35, sans rayon → same format; filters from Config: pièces min, surface min/max, prix max; tri=date_desc).
- **Fusionner branches 6:** above + Foncia (API search Ille-et-Vilaine 35, sans rayon → same format; filters from Config: pièces min/max, surface min/max, prix max).
- **Fusionner branches 7:** above + La Française Immobilière (HTML page location, all listings; filters from Config: nb_chambres min/max = pièces−1, prix max; tri date-desc).
- **Fusionner branches 8:** above + Guenno Immobilier (API guenno.com/biens/recherche, town=RENNES, types 1+2, bbox large ; filters from Config: pièces min/max, prix max, surface min).
- **Fusionner branches 9:** above + Lamotte (lamotte.fr/annonces, dép. 35, HTML; filters from Config: pièces min/max, prix max, surface min/max).
- **Fusionner branches 10:** above + Kermarrec Habitation (kermarrec-habitation.fr/location, sans `ville` ni `rayon`, HTML; filters from Config: pièces min/max, prix max).
- **Fusionner branches 11:** above + Nestenn (nestenn.com/listing, 35 Ille-et-Vilaine, HTML; filters from Config: pièces min/max, prix max, surface min).
- **Fusionner branches 12:** above + Square Habitat (API api.ca-immobilier.fr, `codesDepartements` 35, sans commune/rayon ; filters from Config: pièces min/max, prix max, surface min/max).
- **Fusionner branches 13:** above + CA Immobilier (API `www.ca-immobilier.fr/louer/recherche/resultat`, form-urlencoded ; Rennes 35000 + zones 2–3, T2/T3 via critères, filtres depuis Config: surface min/max, loyer max).
- **Fusionner branches 14:** above + Cogir Immobilier (cogir.fr `data_listing_formrecherche.html`, form-urlencoded ; location maison/appartement T2–T3, filtres depuis Config: surface min/max, loyer max).
- **Fusionner branches 15:** above + Néotoa (neotoa.fr recherche HTML ; location maison/appartement T2–T3, budget max depuis Config).
- **Fusionner branches 16:** above + CDC Habitat (cdc-habitat.fr recherche HTML Ille-et-Vilaine ; location appartement/maison T2–T3, budget max depuis Config).
- **Fusionner branches 17:** above + Oqoro (oqoro.com recherche HTML, bbox large ; location non meublée T2–T3, budget/surface depuis Config, données extraites depuis `data-lots` JSON).
- **Fusionner branches 18:** above + Century 21 (century21.fr annonces HTML ; Ille-et-Vilaine d-35_ille_et_vilaine ; surface min/max, prix max, pièces min/max depuis Config).
- **Fusion + Blot:** above + Blot Immobilier (`wp-admin/admin-ajax.php` : `search_form_validate` pour les IDs, puis `view_result` pour le HTML ; Ille-et-Vilaine 35, location ; loyer max / surfaces / pièces depuis Config, comme le formulaire web).
- **Fusion + Citya:** above + Citya (GET liste location Ille-et-Vilaine ; `prixMax`, `surfaceMin`, `nbrePiecesMin` depuis Config ; JSON-LD + fallback `#list_results`).
- **Fusion + Laforêt:** above + Laforêt (GET `/louer/rechercher`, Rennes 35238 + zone 50 km figée, `filter[max]` / `filter[rooms]` / `filter[surface]` depuis Config ; HTML `article.min-w-0`).
- **Fusion + Rolland Girot:** above + Cabinet Rolland & Girot (GET `/location/appartement--maison?price=`, loyer max depuis Config ; HTML Drupal `node--realestate--teaser`, référence agence en `id_site`).
- **Fusion + Notaire Breton:** above + Notaire & Breton (GET liste 35, filtres URL depuis Config, parsing teaser + requêtes fiches, exclusion collocation).
- **Fusion + Immonot:** above + Immonot (immonot.com, cartes location HTML).
- **Fusion + Cesson Immobilier:** above + Cesson Immobilier (cesson-immobilier.fr, formulaire + fiches).
- **Fusion + Villejean Beauregard:** above + Villejean Beauregard Immobilier (recherche catalogue + parsing).
- **Fusion + Logic-Immo:** above + Logic-Immo (serp-bff + `classifiedList`, annonces multi-agences).
- **Fusion + Lamy:** above + **Lamy Immobilier** (`GET /_ajax/our_ads` → `itemsListHtml` + parse cartes, filtres Config).
- **Fusion + Parthenay:** above + **Parthenay Immobilier** (POST `data_listing-location_formrecherchelocation` → JSON + filtre `piece` en post-traitement, une seule requête).
- **Fusion + Dany Richard:** above + **Dany Richard Immobilier** (GET liste `/location/` + pré-filtre pièces/loyer, puis requêtes fiches, comme Notaire & Breton).
- **Fusion + Chateaubriand:** above + **Cabinet Chateaubriand** (GET recherche location, `max-price` / `min-area` / `max-area` depuis la Config, parse `rh-ultra-list-card`).
- **Fusion + Arthurimmo:** above + **Arthurimmo.com** (GET `recherche,basic.htm` département 35, `pieces[]` / loyer / surface depuis la Config, parse liens `annonces/location/…`).
- **Fusion + Agence MPI:** above + **Agence MPI** (GET `catalog/advanced_search_result.php`, paramètres `C_*` + User-Agent, parse `listing-item` / fiches).
- **Fusion + Nicolazo Notaires:** above + **Nicolazo** (Code : session + token + liste filtrée, parse `bloc-annonce` location).
- **Fusion + Inova Immo:** above + **Inova** (GET liste `recherche-des-biens` + parse `rh-ultra-list-card-*`).
- **Fusion + Stella At Home:** above + **Stella At Home** (GET `advanced_search_result` + parse `listing-item`).
- **Fusion + Keredes:** above + **Keredes** (GET `location/ancien` + parse `bienCard`).
- **Fusion + Loquin Immobilier:** above + **Loquin** (liste + détail).
  **Dernière fusion avant Normaliser annonces** : … → **Fusion + Chateaubriand** → **Fusion + Arthurimmo** → **Fusion + Agence MPI** → **Fusion + Nicolazo Notaires** → **Fusion + Inova Immo** → **Fusion + Stella At Home** → **Fusion + Keredes** → **Fusion + Loquin Immobilier** → **Normaliser annonces** (tête de chaîne inchangée jusqu’à Lamy/Parthenay/…).

To add another agency or site:

1. **Update this README** (new bullet under **Currently supported**, and the fusion list above if you add a merge).
2. Duplicate or mirror the Bienici branch: a trigger/config → HTTP or scrape node → transform to the same format (e.g. `titre`, `ville`, `quartier`, `surface_m2`, `loyer_cc`, `url`, etc.).
3. Connect that branch into the merge chain (e.g. après **Fusion + Agence MPI** ou avant **Normaliser annonces**) so every source still reaches **Normaliser annonces** (défaut actuel : ajouter un **Merge (append)** après la dernière **Fusion** existante, puis vers **Normaliser**).
4. The rest of the pipeline (normalize → filter → id_global → sheet + dedup → Groq → Telegram) stays the same.

Keeping a common schema (fields used in the workflow) makes it easy to add more sources without changing the rest of the logic.

---

## Security notes

- Change `N8N_BASIC_AUTH_PASSWORD` in `docker-compose.yml` (and use strong values for production).
- Do not commit `.env`; it is listed in `.gitignore`.
- For production (e.g. VPS), use HTTPS and restrict access to the n8n port.

---

## License

Private / use as you like. n8n is [Apache 2.0](https://github.com/n8n-io/n8n/blob/master/LICENSE).
