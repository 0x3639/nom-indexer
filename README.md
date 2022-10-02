# NoM Indexer
An indexer for Network of Momentum that fetches information from a Zenon node and stores it in a PostgreSQL database in such a way to provide efficient access to on-chain information that is not readily available via the node RPC API.

Please note that the indexer is still WIP.

## Building from source
The Dart SDK is required to build the server from source (https://dart.dev/get-dart).
Use the Dart SDK to install the dependencies and compile the program by running the following commands:
```
dart pub get
dart compile exe bin/main.dart
```

## Setup and configuration
Install PostgreSQL 14 and create a database for the indexer to use. Set the setting ```synchronous_commit = off``` in ```postgresql.conf``` to improve write speed on the initial indexing.

Make a copy of the example.config.yaml file and name the copy "config.yaml". Set your desired configuration in the file.

## Running the indexer
```
dart run bin/main
```

Initially it will take some time for the indexer to index the network up to the current height.
