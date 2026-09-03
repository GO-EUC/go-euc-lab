<?xml version="1.0" encoding="UTF-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
   <settings pass="windowsPE">
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-International-Core-WinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <SetupUILanguage>
            <UILanguage>${vm_inst_os_language}</UILanguage>
         </SetupUILanguage>
         <InputLocale>${vm_inst_os_keyboard}</InputLocale>
         <SystemLocale>${vm_inst_os_language}</SystemLocale>
         <UILanguage>${vm_inst_os_language}</UILanguage>
         <UILanguageFallback>${vm_inst_os_language}</UILanguageFallback>
         <UserLocale>${vm_inst_os_language}</UserLocale>
      </component>
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-PnpCustomizationsWinPE" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <DriverPaths>
            <!-- Nutanix VirtIO driver ISO (second CD-ROM): SCSI pass-through and network drivers. -->
            <PathAndCredentials wcm:action="add" wcm:keyValue="1">
               <Path>${virtio_driver_path}</Path>
            </PathAndCredentials>
         </DriverPaths>
      </component>
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <DiskConfiguration>
            <Disk wcm:action="add">
               <DiskID>0</DiskID>
               <WillWipeDisk>true</WillWipeDisk>
               <CreatePartitions>
                  <!-- Windows RE Tools partition -->
                  <CreatePartition wcm:action="add">
                     <Order>1</Order>
                     <Type>Primary</Type>
                     <Size>300</Size>
                  </CreatePartition>
                  <!-- System partition (ESP) -->
                  <CreatePartition wcm:action="add">
                     <Order>2</Order>
                     <Type>EFI</Type>
                     <Size>100</Size>
                  </CreatePartition>
                  <!-- Microsoft reserved partition (MSR) -->
                  <CreatePartition wcm:action="add">
                     <Order>3</Order>
                     <Type>MSR</Type>
                     <Size>128</Size>
                  </CreatePartition>
                  <!-- Windows partition -->
                  <CreatePartition wcm:action="add">
                     <Order>4</Order>
                     <Type>Primary</Type>
                     <Extend>true</Extend>
                  </CreatePartition>
               </CreatePartitions>
               <ModifyPartitions>
                  <!-- Windows RE Tools partition -->
                  <ModifyPartition wcm:action="add">
                     <Order>1</Order>
                     <PartitionID>1</PartitionID>
                     <Label>WINRE</Label>
                     <Format>NTFS</Format>
                     <TypeID>DE94BBA4-06D1-4D40-A16A-BFD50179D6AC</TypeID>
                  </ModifyPartition>
                  <!-- System partition (ESP) -->
                  <ModifyPartition wcm:action="add">
                     <Order>2</Order>
                     <PartitionID>2</PartitionID>
                     <Label>System</Label>
                     <Format>FAT32</Format>
                  </ModifyPartition>
                  <!-- MSR partition does not need to be modified -->
                  <ModifyPartition wcm:action="add">
                     <Order>3</Order>
                     <PartitionID>3</PartitionID>
                  </ModifyPartition>
                  <!-- Windows partition -->
                  <ModifyPartition wcm:action="add">
                     <Order>4</Order>
                     <PartitionID>4</PartitionID>
                     <Label>OS</Label>
                     <Letter>C</Letter>
                     <Format>NTFS</Format>
                  </ModifyPartition>
               </ModifyPartitions>
            </Disk>
         </DiskConfiguration>
         <ImageInstall>
            <OSImage>
               <InstallFrom>
                  <MetaData wcm:action="add">
                     <Key>/IMAGE/NAME</Key>
                     <Value>${vm_inst_os_image}</Value>
                  </MetaData>
               </InstallFrom>
               <InstallTo>
                  <DiskID>0</DiskID>
                  <PartitionID>4</PartitionID>
               </InstallTo>
            </OSImage>
         </ImageInstall>
         <UserData>
            <AcceptEula>true</AcceptEula>
            <FullName>${build_username}</FullName>
            <Organization>${build_organization}</Organization>
            <ProductKey>
               <Key>${vm_inst_os_kms_key}</Key>
               <WillShowUI>OnError</WillShowUI>
            </ProductKey>
         </UserData>
         <EnableFirewall>false</EnableFirewall>
      </component>
   </settings>
   <settings pass="offlineServicing">
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-LUA-Settings" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <EnableLUA>false</EnableLUA>
      </component>
   </settings>
   <settings pass="generalize">
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Security-SPP" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <SkipRearm>1</SkipRearm>
      </component>
   </settings>
   <settings pass="specialize">
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <OEMInformation>
            <HelpCustomized>false</HelpCustomized>
         </OEMInformation>
         <TimeZone>${vm_guest_os_timezone}</TimeZone>
         <RegisteredOwner />
      </component>
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-ServerManager-SvrMgrNc" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <DoNotOpenServerManagerAtLogon>true</DoNotOpenServerManagerAtLogon>
      </component>
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-OutOfBoxExperience" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <DoNotOpenInitialConfigurationTasksAtLogon>true</DoNotOpenInitialConfigurationTasksAtLogon>
      </component>
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Security-SPP-UX" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <SkipAutoActivation>true</SkipAutoActivation>
      </component>
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <RunSynchronous>
            <!-- Copy only: do not enable WinRM or change the network profile
                 here, that aborts Windows Setup. Volume GUID paths work when
                 the Packer CD has no drive letter. -->
            <RunSynchronousCommand wcm:action="add">
               <Order>1</Order>
               <Description>Copy windows-init.ps1 from the Packer CD to disk</Description>
               <Path>powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Volume | ForEach-Object { $c = Join-Path $_.Path 'windows-init.ps1'; if (Test-Path -LiteralPath $c) { Copy-Item -LiteralPath $c C:\Windows\Temp\windows-init.ps1 -Force } }"</Path>
            </RunSynchronousCommand>
         </RunSynchronous>
      </component>
   </settings>
   <settings pass="oobeSystem">
      <component xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
         <AutoLogon>
            <Password>
               <Value>${build_password}</Value>
               <PlainText>true</PlainText>
            </Password>
            <Enabled>true</Enabled>
            <Username>${build_username}</Username>
         </AutoLogon>
         <OOBE>
            <HideEULAPage>true</HideEULAPage>
            <HideLocalAccountScreen>true</HideLocalAccountScreen>
            <HideOEMRegistrationScreen>true</HideOEMRegistrationScreen>
            <HideOnlineAccountScreens>true</HideOnlineAccountScreens>
            <HideWirelessSetupInOOBE>true</HideWirelessSetupInOOBE>
            <NetworkLocation>Work</NetworkLocation>
            <ProtectYourPC>2</ProtectYourPC>
         </OOBE>
         <UserAccounts>
            <AdministratorPassword>
               <Value>${build_password}</Value>
               <PlainText>true</PlainText>
            </AdministratorPassword>
            <LocalAccounts>
               <LocalAccount wcm:action="add">
                  <Password>
                     <Value>${build_password}</Value>
                     <PlainText>true</PlainText>
                  </Password>
                  <Group>administrators</Group>
                  <DisplayName>${build_username}</DisplayName>
                  <Name>${build_username}</Name>
                  <Description>Build Account</Description>
               </LocalAccount>
            </LocalAccounts>
         </UserAccounts>
         <FirstLogonCommands>
            <!-- The build VM keeps its DHCP lease: Packer discovers the DHCP address
                 through the Prism API and connects WinRM to it, so assigning a static
                 IP mid-build would break the connection. -->
            <SynchronousCommand wcm:action="add">
               <CommandLine>%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"</CommandLine>
               <Description>Set Execution Policy 64-Bit</Description>
               <Order>1</Order>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
               <CommandLine>%SystemRoot%\system32\WindowsPowerShell\v1.0\powershell.exe -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"</CommandLine>
               <Description>Set Execution Policy 32-Bit</Description>
               <Order>2</Order>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
               <!-- Inline WinRM so Packer can connect even if the Packer CD has
                    no drive letter. Do not do this in specialize: Enable-PSRemoting
                    and network-profile changes there abort Windows Setup. -->
               <CommandLine>powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Enable-PSRemoting -SkipNetworkProfileCheck -Force; Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value 1; Set-Item WSMan:\localhost\Service\Auth\Basic -Value 1; Set-Item WSMan:\localhost\Client\Auth\Basic -Value 1; Set-Service winrm -StartupType Automatic; Restart-Service winrm; netsh advfirewall firewall add rule name=PackerWinRM dir=in action=allow protocol=TCP localport=5985"</CommandLine>
               <Order>3</Order>
               <Description>Enable WinRM for Packer</Description>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
               <CommandLine>cmd.exe /c "echo firstlogon %DATE% %TIME%&gt; C:\Windows\Temp\firstlogon-init.log"</CommandLine>
               <Order>4</Order>
               <Description>Record that FirstLogonCommands ran</Description>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
               <CommandLine>powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Get-Volume | ForEach-Object { $c = Join-Path $_.Path 'windows-init.ps1'; if (Test-Path -LiteralPath $c) { Copy-Item -LiteralPath $c C:\Windows\Temp\windows-init.ps1 -Force; Add-Content C:\Windows\Temp\firstlogon-init.log $c } }"</CommandLine>
               <Order>5</Order>
               <Description>Copy windows-init.ps1 from any volume</Description>
            </SynchronousCommand>
            <SynchronousCommand wcm:action="add">
               <CommandLine>cmd.exe /c "if exist C:\Windows\Temp\windows-init.ps1 (powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Windows\Temp\windows-init.ps1) else (echo windows-init.ps1 missing&gt;&gt; C:\Windows\Temp\firstlogon-init.log)"</CommandLine>
               <Order>6</Order>
               <Description>Initial Configuration</Description>
            </SynchronousCommand>
         </FirstLogonCommands>
      </component>
   </settings>
</unattend>
