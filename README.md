# 📁 Folder Synchronizer – Veeam Test Task

This project was created as part of a technical assessment for Veeam. 
It demonstrates file synchronization between a source and a replica folder, with full support for logging, automated testing, and SpecFlow scenarios.

---

## ✅ Features

- One-way folder synchronization (Source ➜ Replica)
- Interval-based or one-time execution
- File change detection based on content (MD5 hash)
- Tests
  - Unit tests (NUnit)
  - BDD tests (SpecFlow + NUnit)
- Logging to file and console
  - Quiet mode for test logging (no console output)
- File operations:
  - Copy new files from source to replica
  - Update changed files
  - Delete files from replica if deleted in source
  - Restore files in replica if accidentally removed

---

## 📦 Requirements

- Windows OS
- [.NET 6 SDK](https://dotnet.microsoft.com/en-us/download/dotnet/6.0)
  - I use 6.0.428
- PowerShell 5.0+
- Visual Studio 2022 (Community Edition is sufficient)

---

## ⚙️ Installation & Setup

This project contains only single setup script:

### `VeeamTestTask_CreateProjectsInstallation_RunTests.ps1`

and source pack zipped file:

### `SourcePack.zip`

Simply copy both files into your destination folder where you want to have the project built.
This script performs everything automatically:

1. Unzips `SourcePack.zip`
2. Creates the following solution layout:

```
FolderSyncApp/
├── src/FolderSynchronizer/
├── tests/FolderSynchronizer.UnitTests/
├── tests/FolderSynchronizer.SpecFlowTests/
├── _TestsLogs/
├── _CLITests_SourceFolder
├── _CLITests_ReplicaFolder
├── FolderSyncApp.sln
```

3. Installs required NuGet packages
4. Copies all code files and test assets
5. Builds the project
6. Runs all tests: UnitTests and BDD (SpecFlow with NUnit)
7. Updates the following solution layout, with tests folders:

```
FolderSyncApp/
├── src/FolderSynchronizer/
├── tests/FolderSynchronizer.UnitTests/
├── tests/FolderSynchronizer.SpecFlowTests/
├── _TestsLogs/
├── _UnitTests_SourceFolder/
├── _UnitTests_ReplicaFolder/
├── _SpecFlowTests_SourceFolder/
├── _SpecFlowTests_ReplicaFolder/
├── _CLITests_SourceFolder
├── _CLITests_ReplicaFolder
├── FolderSyncApp.sln
```

> 🟢 Just run the `.ps1` file in PowerShell and everything will be created and run automatically.

---

## 🚀 Usage

### 1. CLI execution (from command line)

To run synchronization manually:

```bash
dotnet run --project src/FolderSynchronizer -- "_CLITests_SourceFolder" "_CLITests_ReplicaFolder" 3 "CLITests.log"
```

Where:
- `_CLITests_SourceFolder`: path to source folder
- `_CLITests_ReplicaFolder`: path to replica folder
- `3`: sync interval in seconds
- `CLITests.log`: log filename (will be saved to `_TestsLogs/`)

---

### 2. Program execution (from Visual Studio)

To run synchronization from Visual Studio:

```bash
run "FolderSynchronizer" (from toolbar)
```

Where:
- `_CLITests_SourceFolder`: path to source folder
- `_CLITests_ReplicaFolder`: path to replica folder
- `3`: sync interval in seconds
- `CLITests.log`: log filename (will be saved to `_TestsLogs/`)

Note:
The project already contains a file launchSettings.json in /Properties folder 
with the same command line as for CLI execution

---

## 🧪 Testing

### 1. Unit Tests (from command line)

Located in: `FolderSynchronizer.UnitTests`

Run with:

```bash
dotnet test tests/FolderSynchronizer.UnitTests
```

Scenarios tested:
- UnitTest1_CopyNewCreatedFileFromSourceToReplica
  - Verifies that a newly created file in the source folder is copied to the replica folder.
- UnitTest2_ChangedContentFileFromSourceToReplica
  - Verifies that if the file already exists but has different content in source, it is updated in replica.
- UnitTest3_DeletedFileFromReplicaWillSynchronizeWithSource
  - Verifies that if a file is deleted from replica but still exists in source, it is restored in replica.
- UnitTest4_DeletedFileFromSourceWillSynchronizeToReplica
  - Verifies that if a file is deleted from source, it is also removed from replica.

Where:
- `_UnitTests_SourceFolder`: path to source folder
- `_UnitTests_ReplicaFolder`: path to replica folder
- no sync interval
- `UnitTests.log`: log filename (will be saved to `_TestsLogs/`)

### 2. BDD Tests as SpecFlow (from command line)

Located in: `FolderSynchronizer.SpecFlowTests`

Run with:

```bash
dotnet test tests/FolderSynchronizer.SpecFlowTests
```

Scenarios tested:
- Copy new file from source ➜ replica
- Recreate deleted file in replica
- Delete file from replica if removed in source
- Sync changed file content from source ➜ replica

Where:
- `_SpecFlowTests_SourceFolder`: path to source folder
- `_SpecFlowTests_ReplicaFolder`: path to replica folder
- no sync interval
- `SPecFlowTests.log`: log filename (will be saved to `_TestsLogs/`)

---

### 3. Tests execution (from Visual Studio)

To run synchronization from Visual Studio:

```bash
switch to "Test Explorer" tab
run "FolderSynchronizer.SpecFlowTests"
run "FolderSynchronizer.UnitTests"
```

Note:
All testing folders and logs are appropriate as for tests running from command line

---

## 📁 Logs

All logs are written to:

```
_TestsLogs/{logFileName}
```

Each log entry has the format:

```
[YYYY-MM-DD HH:MM:SS] INFO: Copied/Updated: ...
[YYYY-MM-DD HH:MM:SS] ERROR: ...
```

---

## 🤫 Quiet Mode

All automated tests use `quietMode = true` to suppress console output during `dotnet test` runs.  
This prevents unnecessary console noise and avoids SpecFlow/NUnit warnings.

---

## 👤 Author

**Krzysztof Dariusz Kamiński**

Veeam test task with logging, full test coverage, and automation.
