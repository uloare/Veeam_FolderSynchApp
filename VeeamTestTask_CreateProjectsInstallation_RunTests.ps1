###################################################
#   Krzysztof Dariusz Kaminski
#   Veeam test task - Two Folder Synchronization
###################################################




#---------------------------------------------------------------------------------------------------------------------------------------------------
#   REQUIREMENTS:
#       - Visual Studio Community 2022
#       - .NET 6 SDK must be installed as this one is stable for SpecFlow
#       - PowerShell terminal
#   USAGE:
#       Run this script in PowerShell from the folder where SourcePack.zip is located
#       In the same folder all the projects will be created
#---------------------------------------------------------------------------------------------------------------------------------------------------
$separator = "   ----------------------------------------------------------------------------------------------------------------------------------"

$sourceFolder = "_CLITests_SourceFolder"
$replicaFolder = "_CLITests_ReplicaFolder"
$logInterval = 3
$logFileName = "CLITests.log"




Write-Host $separator -ForegroundColor Cyan
Write-Host "   1... Unpack SourcePack.zip "
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We need to unpack all the code from SourcePack.zip into temporary folder, before we place it into the projects 
#---------------------------------------------------------------------------------------------------------------------------------------------------
# Unpack all
$root = $PWD
$zipPath = Join-Path $root "SourcePack.zip"
$tempExtract = Join-Path $root "temp_extract"
if (!(Test-Path $tempExtract)) {
    New-Item -ItemType Directory -Path $tempExtract | Out-Null
}
Expand-Archive -Path $zipPath -DestinationPath $tempExtract -Force
Get-ChildItem -Path $tempExtract -Recurse




Write-Host $separator -ForegroundColor Cyan
Write-Host "   2... Create whole structure of the projects"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We need to create a new solution (.sln) with three projects:
#       FolderSynchronizer – the actual folder synchronization code (C# console)
#       FolderSynchronizer.SpecFlowTests – tests written using SpecFlow and NUnit
#       FolderSynchronizer.UnitTests – classic NUnit test project (without SpecFlow)
#
#   Desired structure of those projects looks like:
#       FolderSyncApp/
#       ├── src/FolderSynchronizer/                
#       ├── tests/FolderSynchronizer.SpecFlowTests/
#       ├── tests/FolderSynchronizer.UnitTests/
#       ├── _TestsLogs
#       ├── _CLITests_SourceFolder
#       ├── _CLITests_ReplicaFolder
#       ├── FolderSyncApp.sln     
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Create main catalog
mkdir FolderSyncApp
cd FolderSyncApp

# Create folders for projects structure
# src   - keeps source code
# tests - keeps tests (SpecFlow and NUnit)
# docs  - keeps test task info from Veeam
# logs  - logs folder will be created after first run
mkdir src
mkdir tests
mkdir docs

# Create separate folders for Source and Replica, to be used from command line
mkdir $sourceFolder -Force
mkdir $replicaFolder -Force




Write-Host $separator -ForegroundColor Cyan
Write-Host "   3... Create main FolderSynchronizer project"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   This is the main console project that contains the core synchronization logic
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Create main project in C# using .NET 6
dotnet new console -n FolderSynchronizer -o src/FolderSynchronizer --framework net6.0

# Add initial .editorconfig for consistency
@"
root = true
[*]
indent_style = space
indent_size = 4
charset = utf-8
end_of_line = lf
insert_final_newline = true
"@ | Out-File -FilePath ".editorconfig" -Encoding utf8




Write-Host $separator -ForegroundColor Cyan
Write-Host "   4... Create SpecFlow test project"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   This project will store BDD tests written in SpecFlow and NUnit
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Create test project in C# using SpecFlow with NUnit
dotnet new nunit -n FolderSynchronizer.SpecFlowTests -o tests/FolderSynchronizer.SpecFlowTests --framework net6.0

# Create solution and add both projects
dotnet new sln -n FolderSyncApp

# Add projects to solution
dotnet sln add src/FolderSynchronizer/FolderSynchronizer.csproj

# Reference main project in test project                                        
dotnet sln add tests/FolderSynchronizer.SpecFlowTests/FolderSynchronizer.SpecFlowTests.csproj

# Add reference to the main project
dotnet add tests/FolderSynchronizer.SpecFlowTests/FolderSynchronizer.SpecFlowTests.csproj reference src/FolderSynchronizer/FolderSynchronizer.csproj




Write-Host $separator -ForegroundColor Cyan
Write-Host "   5... Add NuGet packages for SpecFlow + NUnit"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   Packages:
#       SpecFlow.NUnit                      - SpecFlow Core Integration with NUnit
#       SpecFlow.Tools.MsBuild.Generation   - Generates Gherkin (.feature) step code when building a project
#       NUnit3TestAdapter                   - Needed to make tests visible and executable in VS - Test Explorer
#       Microsoft.NET.Test.Sdk              - Allows you to run tests with dotnet test and IDE  
#   
#   We expect to have:
#       <PackageReference> entries will appear in the FolderSynchronizer.SpecFlowTests.csproj file
#       We will be able to add .feature files and Visual Studio will automatically generate C# code for them
#       After adding test scenarios, you will be able to run them via dotnet test or Test Explorer
#
#   Final step:
#       After the packages are added, we need to build all to make sure all the packages are working correctly
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Go to test project
cd tests/FolderSynchronizer.SpecFlowTests

# Install packages
dotnet add package SpecFlow.NUnit
dotnet add package SpecFlow.Tools.MsBuild.Generation
dotnet add package NUnit3TestAdapter
dotnet add package Microsoft.NET.Test.Sdk

# Get back to the main folder
cd ../..

# Build all
dotnet build




Write-Host $separator -ForegroundColor Cyan
Write-Host "   6... Create pure NUnit test project (UnitTests)"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We create third project for standalone NUnit test without SpecFlow
#   Project name: FolderSynchronizer.UnitTests
#   Location:     tests/FolderSynchronizer.UnitTests
#   Purpose:      Keep a clean separation between SpecFlow tests and classic unit tests
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Create new unit test project
dotnet new nunit -n FolderSynchronizer.UnitTests -o tests/FolderSynchronizer.UnitTests --framework net6.0

# Add it to the solution
dotnet sln add tests/FolderSynchronizer.UnitTests/FolderSynchronizer.UnitTests.csproj

# Reference FolderSynchronizer.csproj in this test project
dotnet add tests/FolderSynchronizer.UnitTests/FolderSynchronizer.UnitTests.csproj reference src/FolderSynchronizer/FolderSynchronizer.csproj

# Build all 
dotnet build




Write-Host $separator -ForegroundColor Cyan
Write-Host "   7... Create .feature file and step implementation (.cs)"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We will create the first SpecFlow test describing the folder synchronization scenario:
#       The file is in the source folder
#       We start the synchronization
#       We expect the file to appear in the replica folder
#---------------------------------------------------------------------------------------------------------------------------------------------------

Write-Host "   7.1. Create SpecFlow tests folders"

# Go to test project
cd tests/FolderSynchronizer.SpecFlowTests

# Create structured folders
mkdir Features
mkdir StepDefinitions

#-----------
Write-Host "   7.2. Add Gherkin test file into project and structure"

# Find file FolderSynchronization.feature (regardless of the structure in ZIP)
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "FolderSynchronization.feature" | Select-Object -First 1

# Destination path FolderSyncApp\tests\FolderSynchronizer.SpecFlowTests\Features
$destPath = Join-Path $root "FolderSyncApp\tests\FolderSynchronizer.SpecFlowTests\Features"

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

# Get back to the main folder
cd ../..
dir




Write-Host $separator -ForegroundColor Cyan
Write-Host "   8... Add implementation code into projects and structurize them in proper places"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We will add all the code files into projects in a proper structure
#---------------------------------------------------------------------------------------------------------------------------------------------------

Write-Host "   8.1. Add FolderSynchronizationSteps.cs into project and structure"

# Find file FolderSynchronizationSteps.cs (regardless of the structure in ZIP)
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "FolderSynchronizationSteps.cs" | Select-Object -First 1

# Destination path FolderSyncApp\tests\FolderSynchronizer.SpecFlowTests\StepDefinitions
$destPath = Join-Path $root "FolderSyncApp\tests\FolderSynchronizer.SpecFlowTests\StepDefinitions"

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

#-----------
Write-Host "   8.2. Add FolderSyncService.cs into project and structure"

# Find file FolderSyncService.cs (regardless of the structure in ZIP)
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "FolderSyncService.cs" | Select-Object -First 1

# Destination path FolderSyncApp\src\FolderSynchronizer
$destPath = Join-Path $root "FolderSyncApp\src\FolderSynchronizer"

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

#-----------
Write-Host "   8.3. Add ILogger.cs into project and structure"

# Find file Program.cs (regardless of the structure in ZIP)
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "ILogger.cs" | Select-Object -First 1

# Destination path FolderSyncApp\src\FolderSynchronizer
$destPath = Join-Path $root "FolderSyncApp\src\FolderSynchronizer"

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

#-----------
Write-Host "   8.4. Add Logger.cs into project and structure"

# Find file Program.cs (regardless of the structure in ZIP)
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "Logger.cs" | Select-Object -First 1

# Destination path FolderSyncApp\src\FolderSynchronizer
$destPath = Join-Path $root "FolderSyncApp\src\FolderSynchronizer"

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

#-----------
Write-Host "   8.5. Add UnitTestWithoutSpecFlow.cs into FolderSynchronizer.UnitTests"

# Find the test file regardless of the structure in ZIP
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "UnitTestWithoutSpecFlow.cs" | Select-Object -First 1

# Destination path
$destPath = Join-Path $root "FolderSyncApp\tests\FolderSynchronizer.UnitTests"

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

#-----------
Write-Host "   8.6. Replace default Program.cs with the proper one in project and structure"

# Find file Program.cs (regardless of the structure in ZIP)
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "Program.cs" | Select-Object -First 1

# Destination path FolderSyncApp\src\FolderSynchronizer
$destPath = Join-Path $root "FolderSyncApp\src\FolderSynchronizer"

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force




Write-Host $separator -ForegroundColor Cyan
Write-Host "   9... Add test files into Source folder to be synchronized with Replica folder"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We will add the test filed into SurceFolder
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Destination path "FolderSyncApp\$sourceFolder" => "FolderSyncApp\_CLITests_SourceFolder"
$destPath = Join-Path $root "FolderSyncApp\$sourceFolder"

#-----------
Write-Host "   9.1. Add Test_TextFile.txt into SourceFolder"

# Find the test file: .txt
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "Test_TextFile.txt" | Select-Object -First 1

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

#-----------
Write-Host "   9.2. Add Test_VeeamTestTask.pdf into SourceFolder"

# Find the test file: .pdf
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "Test_VeeamTestTask.pdf" | Select-Object -First 1

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

#-----------
Write-Host "   9.3. Add Test_FreeColorPicker.exe into SourceFolder"

# Find the test file: .exe
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "Test_FreeColorPicker.exe" | Select-Object -First 1

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force

#-----------
Write-Host "   9.4. Add Test_MissEyebrows2025Winner.png into SourceFolder"

# Find the test file: .png
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "Test_MissEyebrows2025Winner.png" | Select-Object -First 1

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force




Write-Host $separator -ForegroundColor Cyan
Write-Host "   10... Add document file into docs folder"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We will add Veeam docs file about the task
#---------------------------------------------------------------------------------------------------------------------------------------------------

Write-Host "   10.1 Add Veeam_test_task_C_.pdf into docs folder"

# Find file Veeam_test_task_C_.pdf (regardless of the structure in ZIP)
$stepFile = Get-ChildItem -Path $tempExtract -Recurse -Filter "Veeam_test_task_C_.pdf" | Select-Object -First 1

# Destination path FolderSyncApp\docs
$destPath = Join-Path $root "FolderSyncApp\docs"

# Copy file
Copy-Item -Path $stepFile.FullName -Destination $destPath -Force




Write-Host $separator -ForegroundColor Cyan
Write-Host "   11.. Remove all temporary, unpacked data and redundant UnitTest1.cs"
Write-Host $separator -ForegroundColor Cyan
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We will remove temporary unpacked data
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Remove all redundant files and temp folder
Remove-Item $tempExtract -Recurse -Force
Remove-Item tests/FolderSynchronizer.SpecFlowTests/UnitTest1.cs
Remove-Item tests/FolderSynchronizer.UnitTests/UnitTest1.cs




Write-Host $separator -ForegroundColor Yellow
Write-Host "   12.. Create launchSettings.json for FolderSynchronizer project for Visual Studio debugging.. "
Write-Host $separator -ForegroundColor Yellow
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   Create launchSettings.json for FolderSynchronizer project
#   Note:
#      You will be able to run the program from Visual Studio with all setup
#---------------------------------------------------------------------------------------------------------------------------------------------------

# JSON content with dynamic variables interpolated correctly
$launchSettingsContent = @"
{
  "profiles": {
    "FolderSynchronizer": {
      "commandName": "Project",
      "commandLineArgs": "$sourceFolder $replicaFolder $logInterval $logFileName",
      "workingDirectory": "`$(ProjectDir)\\..\\..\\"
    }
  }
}
"@

# Create Properties folder if it doesn't exist
$propertiesPath = "src/FolderSynchronizer/Properties"
if (!(Test-Path $propertiesPath)) {
    New-Item -ItemType Directory -Path $propertiesPath | Out-Null
}

# Save the JSON to launchSettings.json
$launchSettingsPath = Join-Path $propertiesPath "launchSettings.json"
$launchSettingsContent | Set-Content -Path $launchSettingsPath -Encoding UTF8




Write-Host $separator -ForegroundColor Green
Write-Host "   13.. All created and setup"
Write-Host "            - all projects (logic, tests, standalone), file structure"
Write-Host ""
Write-Host "        Now, do the final build"
Write-Host $separator -ForegroundColor Green
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We will build all
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Build all
dotnet build




Write-Host $separator -ForegroundColor Magenta
Write-Host "   14.. Run all tests to verify folder synchronization: SppecFlowTest and UnitTests"
Write-Host ""
Write-Host "        You may also open the .sln in Visual Studio and run the SpecFlowTests, UnitTests in Test Explorer manually"
Write-Host $separator -ForegroundColor Magenta
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We will run all the tests: SpecFlowTests and simple UnitTests
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Run all tests
dotnet test




Write-Host $separator -ForegroundColor Magenta
Write-Host "   15.. Run standalone project to verify folder synchronization in 3 seconds interval"
Write-Host "            - all is running as test task expected from command line: ""SourceFolder"" ""ReplicaFolder"" ""Interval"" ""logFileName"""
Write-Host ""
Write-Host "        Now, do the changes in some of those source tests files"
Write-Host "            - add new file/files into SourceFolder or change existing files, delete etc., all will be synchronized with ReplicaFolder"
Write-Host "            - add new file/files into ReplicaFolder, all will be synchronized with SourceFolder, what means - deleted"
Write-Host ""
Write-Host "        Watch the logs in the logs folder"
Write-Host ""
Write-Host "        Thank you."
Write-Host $separator -ForegroundColor Magenta
#---------------------------------------------------------------------------------------------------------------------------------------------------
#   We will run standalone application to synchronize Surce and Replica folder in 3 seconds interval
#---------------------------------------------------------------------------------------------------------------------------------------------------

# Run all tests
dotnet run --project src/FolderSynchronizer -- $sourceFolder $replicaFolder $logInterval $logFileName