# Mobilné technológie 2026/2027

Repozitár študenta pre predmet **Mobilné technológie** (UPTI UCM Trnava).
Celú prácu počas semestra odovzdávate v tomto jedinom repozitári.

| Priečinok | Obsah |
|---|---|
| [`ulohy/`](ulohy/) | úlohy riešené na cvičeniach |
| [`projekt/`](projekt/) | semestrálny projekt – mobilná aplikácia |
| [`tema/`](tema/) | spracovanie dohodnutej témy |

Údaje o sebe vyplňte v súbore [`student.txt`](student.txt).

## Pravidlá

- Súbory `README.md` **nemeňte** – obsahujú zadania a môžu sa počas semestra aktualizovať.
- Riešenie priebežne **commitujte a pushujte**.
- Používanie LLM nástrojov sa **očakáva**. Skoro každá aktivita musí obsahovať popis, ako ste ich použili
  (nástroje, na čo, kľúčové prompty, čo ste upravili sami).
- Za odovzdané riešenie zodpovedáte vy – musíte mu rozumieť a vedieť ho vysvetliť.
- Nikdy necommitujte API kľúče, heslá ani osobné údaje.

## Založenie repozitára

Na začiatku semestra si vytvorte vlastný repozitár zo šablóny:

1. Otvorte šablónu https://github.com/UPTI-UCM-TT-MCE/mt_2026
2. Kliknite na **Use this template → Create a new repository**.
3. Nastavte:
   - **Owner:** váš GitHub účet,
   - **Repository name:** `mt_2026-priezvisko` (bez diakritiky, napr. `mt_2026-novak`),
   - **Private**.
4. Kliknite na **Create repository**.
5. V novom repozitári otvorte **Settings → Collaborators → Add people** a pridajte vyučujúceho: **`MichalCernansky`**.
6. Repozitár si naklonujte k sebe:

   ```bash
   git clone https://github.com/<vas-ucet>/mt_2026-priezvisko.git
   cd mt_2026-priezvisko
   ```

7. Vyplňte [`student.txt`](student.txt), commitnite a pushnite.

   ```bash
   git add student.txt
   git commit -m "Updated student info"
   git push
   ```

Nerobte **fork** – použite **Use this template**.

## Aktualizácia zo šablóny

Počas semestra budú do šablóny pribúdať nové zadania (napr. `ulohy/u3/`).
Do svojho repozitára ich stiahnete takto:

**Prvýkrát** – pridajte šablónu ako ďalší remote:

```bash
git remote add template https://github.com/UPTI-UCM-TT-MCE/mt_2026.git
```

**Pri každej aktualizácii:**

```bash
git fetch template
git merge template/main --allow-unrelated-histories -m "Update from template"
git push
```

Ak git hlási konflikt v súbore, ktorý ste sami upravili (napr. `student.txt`),
ponechajte svoju verziu a dokončite merge:

```bash
git checkout --ours student.txt
git add student.txt
git commit -m "Update from template"
git push
```
