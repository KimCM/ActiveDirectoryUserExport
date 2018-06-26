# Active Directory - Export der Benutzerdaten

Das Active Directory wird in vielen Unternehmen als Verzeichnis zur Pflege von Benutzern und deren Kontaktdaten verwendet. Da jeder Benutzer zur funktionierenden Windows-Anmeldung an der Domäne sowieso ein Eintrag im Active Directory benötigt, ist es nicht sehr aufwändig die passende Telefonnummer und Adresse des Benutzers ebenfalls einzutragen.

Alle Systeme im Unternehmen die mit Active Directory synchronisieren oder dieses als LDAP-Verzeichnis nutzen, haben danach Zugriff auf diese Daten, so dass diese nicht mehr doppelt geführt werden müssen. 

Manchmal gibt es aber auch Systeme im Unternehmen, die nicht so leicht mit dem Active Directory synchronisierbar sind. Dazu gehören vielleicht in die Jahre gekommene Telefonanlagen, Programme ohne LDAP-Modul oder andere Legacy-Systeme. In diesen Fällen kann es Sinn machen, die Benutzerdaten aus dem Active Directory automatisch und in regelmäßigen Abständen für diese Systeme in Dateiform bereitzustellen. Einen Vorschlag für den automatischen Import fremder Kontaktdaten in Exchange Online gibt es [hier](https://github.com/KimCM/ExchangeOnlineContactImport).

Das Script [user-export.ps1](user-export.ps1) exportiert die Benutzerdaten exemplarisch in eine [CSV-Datei](https://de.wikipedia.org/wiki/CSV_(Dateiformat)). Darüber hinaus wird pro Benutzer eine [vCard](https://de.wikipedia.org/wiki/VCard) erstellt.

## Zeitsteuerung

Meiner Meinung macht es Sinn dieses Script zeitgesteuert z.B. alle 15 Minuten durch den [Task Scheduler](https://docs.microsoft.com/de-de/windows/desktop/TaskSchd/using-the-task-scheduler) ausführen zu lassen. Die Dateien werden auf einem UNC-Pfad abgelegt, so dass andere Scripte diese Daten als Quelle für den Import nutzen können.

## Datenschutz

Du solltest vor der Bereitstellung die geltenden Bestimmungen zum Datenschutz beachten und das Script bei Bedarf anpassen. Vielleicht reicht ein Script für alle Systeme; Vielleicht benötigtst du aber auch eine für jedes Zielsystem individuell angepasste Variante dieses Scripts.

## Customizing

Belege im Script `user-export.ps1` folgende Variablen mit sinnvollen Werten:

```ps1
$exportFileNamePrefix = "myCompany"
$exportFolder = "\\fileserver\share\adexport"
```

Passe auch die Selektionskriterien an deine Bedürfnisse an, um  z.B. technische User oder andere Einträge auszufiltern und somit
zu verhindern, dass diese Daten exportiert werden:

```ps1
Import-Module ActiveDirectory
$ADUsers = Get-AdUser `
  -filter {
   Enabled -eq $true
   -and UserPrincipalName -Like "*@firmenname.de"
   -and UserPrincipalName -NotLike "foo_*"
   -and UserPrincipalName -NotLike "bar*"   
  } `
  -Properties   GivenName, Surname, DisplayName, Initials, ObjectGUID, Title, Department, Company, StreetAddress, PostalCode, City, Country, `
                EmailAddress, wwwHomePage, OfficePhone, MobilePhone, Fax, ipPhone | 
  Select-Object GivenName, Surname, DisplayName, Initials, ObjectGUID, Title, Department, Company, StreetAddress, PostalCode, City, Country, `
                EmailAddress, wwwHomePage, OfficePhone, MobilePhone, Fax, ipPhone
  Sort-Object Surname, GivenName
```
z.B so:

```ps1
  ...
  -and UserPrincipalName -Like "*@myCompany.de"
  -and UserPrincipalName -NotLike "technischerUserName*"
  ...   
```

## Datensatzbeschreibung

| Feldname | Beschreibung des Inhalts | Beispiel |
| --- | --- | --- |
| `GivenName` | Vorname | Kim  |
| `Surname` | Nachname | Meiser |
| `DisplayName` | Anzeigename | Kim Meiser |
| `Initials` | Initialen / Kürzel | KimCM |
| `ObjectGUID` | Eindeutige Identifikation dieses Benutzers, wird idealerweise als Identifikation dieses Datensatzes verwendet | 5B4BE7E1-0F40-4DC7-98DE-07F6BF9CFDBE |
| `Title` | Stellenbezeichnung, Berufsbezeichnung | Chief Architect |
| `Department` | Abteilung | IT |
| `Company` | Organisation, Firma | Mega Business Inc. |
| `StreetAddress` | Straße inkl. Hausnummer | Innovation Street 2a |
| `PostalCode` | Postleitzahl | 12345 |
| `City` | Stadt | Springfield |
| `Country` | Land | DE |
| `Office` | Ort des Büros oder Bürobezeichnung, z.B. Zürich, Saarbrücken oder Frankfurt am Main | Saarbrücken West
| `EmailAddress` | E-Mail-Adresse | github@kimcm.de |
| `wwwHomePage` | Benutzer-Seite im Internet oder Intranet | http://kimcm.de
| `OfficePhone` | Telefon-Nummer Büro Festnetz | +49 681 555-555 |
| `MobilePhone` | Telefon-Nummer mobil | +49 555-56789 |
| `Fax` | Telefax-Nummer | +49 555-56780 |
| `ipPhone` | Skype ID oder SIP-Konto | Kim.Meiser@firmenname.de |