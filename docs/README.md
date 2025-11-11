# Documentatie voor scripts

Deze `docs/README.md` bevat een overzicht van de scripts in deze repository. De scripts zijn gegroepeerd per onderdeel van Microsoft 365 en volgen een consistent `Werkwoord‑ZelfstandigNaamwoord`‑patroon in hun bestandsnamen.

## Structuur van de repository

- **scripts/exchange/** – scripts voor Exchange Online rapportage.
- **scripts/teams/** – scripts voor Microsoft Teams beheer en rapportage.
- **scripts/users/** – scripts voor gebruikersbeheer.

## Overzicht van de scripts

### Exchange
- **Get‑ResourceMailboxesReport.ps1** – genereert een overzicht van resource‑mailboxen, inclusief e‑mailadres, laatste aanmelding en mailboxgrootte.
- **Get‑SharedMailboxOwnersReport.ps1** – toont de eigenaren en aanvullende eigenschappen van gedeelde mailboxen.
- **Get‑SharedMailboxesWithoutPermissions.ps1** – lijst van gedeelde mailboxen waar geen toegangsrechten zijn ingesteld.

### Teams
- **Get‑ESETeamsWithOwners.ps1** – filtert en exporteert Teams die een eigenaar hebben en toont de eigenaar(s).
- **Get‑TeamsWithSingleOwnerNoMembers.ps1** – zoekt Teams met slechts één eigenaar en geen leden, zodat je deze kunt herzien of opschonen.

### Users
- **Get‑InactiveGuestUsers.ps1** – vindt gastgebruikers die gedurende een jaar niet actief zijn geweest. De periode kan als parameter worden aangepast.

## Naamgevingsconventies

Scripts worden benoemd met een combinatie van een werkwoord en een zelfstandig naamwoord (`Get`, `Set`, `Export` etc.) en maken gebruik van PascalCase, zodat direct duidelijk is wat een script doet. Volg dit patroon wanneer je nieuwe scripts toevoegt.

## Licentie

Deze repository bevat een `LICENSE.md`‑bestand met de voorwaarden voor gebruik. Lees dit bestand voordat je de scripts hergebruikt of deelt.
