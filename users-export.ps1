# Selektiert alle Benutzer im Active Directory und exportiert
# die zugehörigen Benutzerdaten als
# * CSV-Datei
# * vCard 4.0

# Alle erzeugten Dateien beginnen mit FIRMENNAME.
$exportFileNamePrefix = "FIRMENNAME"
$exportFolder = "export"

# Ermittlung aller zu exportierenden Benutzer aus dem Active Directory.
# Exportiert werden sollen alle Benutzer, deren Benutzeranmeldename auf @firmenname.de endet.
# Ausnahmen: Technische Benutzer (foo_*, bar*) sollen nicht exportiert werden.

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

# Ordner erstellen für alle automatisch erzeugten Dateien
$existExportFolder = Test-Path -Path $exportFolder
if ($existExportFolder -eq $false) { New-Item -Type Directory -Path $exportFolder }
				
# Exportiere Benutzer in eine CSV-Datei.
$csvPath  = $($exportFolder) + "\" + $exportFileNamePrefix + "-users.csv";
$ADUsers | Export-csv $csvPath -encoding "UTF8" -NoTypeInformation


# Exportiere Benutzer in eine vCard v4.0 Datei.

Get-ChildItem "$($exportFolder)\*.vcf" | Remove-Item
ForEach ($user in $ADUsers) {

  $vCardPath = $exportFolder + "\" + $exportFileNamePrefix + "-individual-" + $($user.GivenName) + "_" + $($user.Surname) + ".vcf"
  if (Test-Path $vCardPath) {
    Remove-Item $vCardPath
  }  
   
  # BEGIN: Jede vCard muss mit dieser Eigenschaft beginnen
  Add-Content -Path $vCardPath -Value "BEGIN:VCARD"
  
  # VERSION: Version der vCard-Spezifikation. In den Versionen 3.0 und 4.0 muss diese auf die BEGIN-Eigenschaft folgen.
  Add-Content -Path $vCardPath -Value "VERSION:4.0"
 
  # N: Strukturierte Darstellung von Namen der Person, Ort oder Sache, der das vCard-Objekt zugeordnet ist. 
  Add-Content -Path $vCardPath -Value "N:$($user.Surname);$($user.GivenName)"
  
  # FN: Formatierte Zeichenfolge mit dem vollständigen Namen des vCard-Objekts.
  Add-Content -Path $vCardPath -Value "FN:$($user.DisplayName)"
 
  # TITLE: Angabe der Stellenbezeichnung, funktionellen Stellung oder Funktion der mit dem vCard-Objekt verbundenen Person inneraalb einer Organisation.
  Add-Content -Path $vCardPath -Value "TITLE:$($user.Title)"
  
  # ORG: Name und gegebenenfalls Einheit(en) der Organisation, der das vCard-Objekt zugeordnet ist. 
  #      Diese Eigenschaft basiert auf den Attributen „Organization Name“ und „Organization Unit“ des X.520-Standards.
  Add-Content -Path $vCardPath -Value "ORG:$($user.Company);$($user.Department)"
  
  # TEL: Normalform einer numerischen Zeichenkette für eine Telefonnummer zur telefonischen Kommunikation mit dem vCard-Objekt.
  if ($($user.OfficePhone)) { Add-Content -Path $vCardPath -Value "TEL;WORK;VOICE;$($user.OfficePhone)" }
  if ($($user.MobilePhone)) { Add-Content -Path $vCardPath -Value "TEL;CELL;VOICE;$($user.MobilePhone)" }
  if ($($user.Fax)) { Add-Content -Path $vCardPath -Value "TEL;WORK;FAX;$($user.Fax)" }
    
  # Strukturierte Darstellung der physischen Anschrift des vCard-Objekts.
  Add-Content -Path $vCardPath -Value "ADR;WORK:$($user.StreetAddress);$($user.PostalCode);$($user.City);$($user.Country)"
  
  # EMAIL: E-Mail-Adresse zur Kommunikation mit dem vCard-Objekt.
  Add-Content -Path $vCardPath -Value "EMAIL;WORK;INTERNET:$($user.EmailAddress)"

  # IMPP:sip: Skype ID zur Kommunikation mit dem vCard-Objekt. IMPP gem. RFC 4770 ftp://ftp.rfc-editor.org/in-notes/rfc4770.txt
  Add-Content -Path $vCardPath -Value "IMPP;sip:$($user.ipPhone)"
  
  # X-SKYPE: Die Skype ID des vCard-Objekts, diesmal als vCard extension.
  Add-Content -Path $vCardPath -Value "X-SKYPE:$($user.ipPhone)"

  # KIND: Art des Objekts, das die vCard beschreibt: 
  #       Eine Person (individual), eine Organisation (organization) oder eine Gruppe (group).
  Add-Content -Path $vCardPath -Value "KIND:individual"
  
  
  # REV: Zeitstempel der letzten Aktualisierung der vCard.
  Add-Content -Path $vCardPath -Value "REV:$((get-date).ToUniversalTime().ToString("yyyyMMddTHHmmssfffffffZ"))"
  
  # END: Jede vCard muss mit dieser Eigenschaft enden.
  Add-Content -Path $vCardPath -Value "END:VCARD"
}