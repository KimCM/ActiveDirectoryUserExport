# Active Directory - Export der Benutzerdaten

Das Active Directory wird in vielen Unternehmen als Verzeichnis zur Pflege von Benutzer bzw. deren Kontaktdaten verwendet. Da jeder Benutzer sowieso ein Eintrag im Active Directory hat, damit die Windows-Anmeldung funktioniert, ist es nicht sehr aufwändig die passende Telefonnummer und Adresse ebenfalls einzutragen.

Alle Systeme im Unternehmen, die mit Active Directory synchronisieren oder dieses als LDAP-Verzeichnis nutzen, haben direkten Zugriff auf diese Daten. 

Manchmal gibt es aber auch Systeme im Unternehmen, die nicht so leicht mit dem Active Directory synchronisierbar sind. Dazu gehören vielleicht in die Jahre gekommene Telefonanlagen, Programme ohne LDAP-Modul oder andere Legacy-Systeme. In diesen Fällen kann es Sinn machen, die Benutzerdaten aus dem Active Directory automatisch und in regelmäßigen Abständen für diese Systeme in Dateiform bereitzustellen.

Das Script <a href="./user-export.ps1">user-export.ps1</a> exportiert die Benutzerdaten exemplarisch in eine <a href="https://de.wikipedia.org/wiki/CSV_(Dateiformat)">CSV-Datei</a>. Darüber hinaus wird pro Benutzer eine <a href="">vCard</a> erstellt.

## Zeitsteuerung

Ich finde es praktisch dieses Script zeitgesteuert z.B. alle 15 Minuten durch den <a href="https://docs.microsoft.com/de-de/windows/desktop/TaskSchd/using-the-task-scheduler">Task Scheduler</a> ausführen zu lassen. Die Dateien werden auf einem UNC-Pfad abgelegt, so dass andere Scripte diese Daten als Quelle für den Import (z.B. in das Verzeichnis der Telefonanlage) nutzen können.

## Datenschutz

Du solltest vor der Bereitstellung die geltenden Bestimmungen zum Datenschutz beachten und das Script bei Bedarf entsprechend anpassen. Vielleicht benötigst du auch eine für jedes Zielsystem individuell angepasste Variante des Scripts.

## Customizing

Belege im Script `user-export.ps1` folgende Variablen mit sinnvollen Werten:

```ps1
$exportFileNamePrefix = "myCompany"
$exportFolder = "\\fileserver\share\adexport"
```

Auf jeden Fall solltest du die Selektionskriterien anpassen, um  z.B. technische User auszufiltern:

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
z.B:

```ps1
  ...
  -and UserPrincipalName -Like "*@myCompany.de"
  -and UserPrincipalName -NotLike "technischerUser*"
  ...   
```