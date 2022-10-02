import 'package:postgresql2/postgresql.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import '../indexer/nom_indexer.dart';

import '../config/config.dart';

class Table {
  static String get momentums => 'Momentums';
  static String get balances => 'Balances';
  static String get accounts => 'Accounts';
  static String get accountBlocks => 'AccountBlocks';
  static String get pillars => 'Pillars';
  static String get sentinels => 'Sentinels';
  static String get stakes => 'Stakes';
  static String get tokens => 'Tokens';
  static String get projects => 'Projects';
  static String get projectPhases => 'ProjectPhases';
  static String get votes => 'Votes';
  static String get fusions => 'Fusions';
  static String get cumulativeRewards => 'CumulativeRewards';
  static String get rewardTransactions => 'RewardTransactions';
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  late final Connection _conn;

  final _uri =
      'postgres://${Config.databaseUsername}:${Config.databasePassword}@${Config.databaseAddress}:${Config.databasePort}/${Config.databaseName}';

  final String _momentumColumns =
      'height BIGINT PRIMARY KEY, hash TEXT, timestamp BIGINT, txCount INT, producer TEXT';

  final String _accountColumns =
      '''address TEXT PRIMARY KEY, blockCount BIGINT, publicKey TEXT, delegate TEXT DEFAULT '' NOT NULL, delegationStartTimestamp BIGINT DEFAULT 0 NOT NULL''';

  final String _balanceColumns =
      'address TEXT, tokenStandard TEXT, balance BIGINT, unique(address, tokenStandard)';

  final String _tokenColumns =
      'tokenStandard TEXT PRIMARY KEY, name TEXT, symbol TEXT, domain TEXT, decimals INT, owner TEXT, totalSupply BIGINT, maxSupply BIGINT, isBurnable BOOL, isMintable BOOL, isUtility BOOL';

  final String _accountBlockColumns =
      '''hash TEXT PRIMARY KEY, momentumHash TEXT, momentumTimestamp BIGINT, momentumHeight BIGINT, blockType SMALLINT,
      height BIGINT, address TEXT, toAddress TEXT, amount BIGINT, tokenStandard TEXT, data TEXT, method TEXT, input JSONB,
      pairedAccountBlock TEXT DEFAULT '' NOT NULL, descendantOf TEXT DEFAULT '' NOT NULL''';

  final String _pillarColumns =
      '''ownerAddress TEXT PRIMARY KEY, producerAddress TEXT, withdrawAddress TEXT, name TEXT, rank INT,
      giveMomentumRewardPercentage SMALLINT, giveDelegateRewardPercentage SMALLINT, isRevocable BOOL,
      revokeCooldown INT, revokeTimestamp BIGINT, weight BIGINT, epochProducedMomentums SMALLINT, epochExpectedMomentums SMALLINT,
      slotCostQsr BIGINT DEFAULT 0 NOT NULL, spawnTimestamp BIGINT DEFAULT 0 NOT NULL, votingActivity REAL DEFAULT 0 NOT NULL, isRevoked BOOL DEFAULT false NOT NULL''';

  final String _sentinelColumns =
      '''owner TEXT PRIMARY KEY, registrationTimestamp BIGINT, isRevocable BOOL, revokeCooldown TEXT, active BOOL''';

  final String _stakeColumns =
      '''id TEXT PRIMARY KEY, address TEXT, startTimestamp BIGINT, expirationTimestamp BIGINT, znnAmount BIGINT, durationInSec INT, isActive BOOL, cancelId TEXT''';

  final String _projectColumns =
      '''id TEXT PRIMARY KEY, votingId TEXT, owner TEXT, name TEXT, description TEXT, url TEXT, znnFundsNeeded BIGINT, qsrFundsNeeded BIGINT,
      creationTimestamp BIGINT, lastUpdateTimestamp BIGINT, status SMALLINT, yesVotes SMALLINT DEFAULT 0 NOT NULL, noVotes SMALLINT DEFAULT 0 NOT NULL, totalVotes SMALLINT DEFAULT 0 NOT NULL''';

  final String _projectPhaseColumns =
      '''id TEXT PRIMARY KEY, projectId TEXT, votingId TEXT, name TEXT, description TEXT, url TEXT, znnFundsNeeded BIGINT, qsrFundsNeeded BIGINT,
      creationTimestamp BIGINT, acceptedTimestamp BIGINT, status SMALLINT, yesVotes SMALLINT DEFAULT 0 NOT NULL, noVotes SMALLINT DEFAULT 0 NOT NULL, totalVotes SMALLINT DEFAULT 0 NOT NULL''';

  final String _voteColumns =
      '''id SERIAL PRIMARY KEY, momentumHash TEXT, momentumTimestamp BIGINT, momentumHeight BIGINT, voterAddress TEXT, projectId TEXT, phaseId TEXT, votingId TEXT, vote SMALLINT''';

  final String _fusionColumns =
      '''id TEXT PRIMARY KEY, address TEXT, beneficiary TEXT, momentumHash TEXT, momentumTimestamp BIGINT, momentumHeight BIGINT, qsrAmount BIGINT, expirationHeight BIGINT, isActive BOOL, cancelId TEXT''';

  final String _cumulativeRewardColumns =
      '''id SERIAL PRIMARY KEY, address TEXT, rewardType SMALLINT, amount BIGINT, tokenStandard TEXT''';

  final String _rewardTransactionColumns =
      '''hash TEXT PRIMARY KEY, address TEXT, rewardType SMALLINT, momentumTimestamp BIGINT, momentumHeight BIGINT, amount BIGINT, tokenStandard TEXT''';

  initialize() async {
    _conn = await connect(_uri);
    await Future.wait([
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.momentums} ($_momentumColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.accounts} ($_accountColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.balances} ($_balanceColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.tokens} ($_tokenColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.accountBlocks} ($_accountBlockColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.pillars} ($_pillarColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.sentinels} ($_sentinelColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.stakes} ($_stakeColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.projects} ($_projectColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.projectPhases} ($_projectPhaseColumns)'),
      _conn
          .execute('CREATE TABLE IF NOT EXISTS ${Table.votes} ($_voteColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.fusions} ($_fusionColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.cumulativeRewards} ($_cumulativeRewardColumns)'),
      _conn.execute(
          'CREATE TABLE IF NOT EXISTS ${Table.rewardTransactions} ($_rewardTransactionColumns)'),
    ]);
    await _conn.execute(
        'CREATE UNIQUE INDEX ON ${Table.cumulativeRewards} (address, rewardType, tokenStandard)');
    print('Connected to database');
  }

  dispose() {
    _conn.close();
  }

  Future<int> getLatestHeight() async {
    final r = await _conn.query('SELECT MAX(height) FROM momentums').toList();
    return r.isNotEmpty && r[0][0] != null ? r[0][0] : 0;
  }

  Future<TxData?> getTransactionData(String blockHash) async {
    final r = await _conn
        .query('SELECT method, inputs FROM ${Table.accountBlocks}')
        .toList();
    return r.isNotEmpty && r[0][0] != null
        ? TxData(method: r[0][0], inputs: r[0][1])
        : null;
  }

  Future<String> getProjectIdFromVotingId(String votingId) async {
    final r = await _conn.query(
        'SELECT id FROM projects WHERE votingId = @votingId',
        {'votingId': votingId}).toList();
    return r.isNotEmpty && r[0][0] != null ? r[0][0] : '';
  }

  Future<List<String>> getProjectAndPhaseIdFromVotingId(String votingId) async {
    final r = await _conn.query(
        'SELECT projectId, id FROM projectPhases WHERE votingId = @votingId',
        {'votingId': votingId}).toList();
    return r.isNotEmpty ? [r[0][0], r[0][1]] : [];
  }

  Future<int> getVoteCountForProjects(
      String voterAddress, List<String> ids) async {
    final r = await _conn.query(
        'SELECT DISTINCT projectId FROM votes where voterAddress = @voterAddress and projectId LIKE ANY (@ids)',
        {'voterAddress': voterAddress, 'ids': ids}).toList();
    return r.isNotEmpty ? r.length : 0;
  }

  Future<int> getVoteCountForPhases(
      String voterAddress, List<String> ids) async {
    final r = await _conn.query(
        'SELECT DISTINCT phaseId FROM votes where voterAddress = @voterAddress and phaseId LIKE ANY (@ids)',
        {'voterAddress': voterAddress, 'ids': ids}).toList();
    return r.isNotEmpty ? r.length : 0;
  }

  Future<dynamic> getRewardDetails(String receiveBlockHash) async {
    final rewardContracts = [
      'z1qxemdeddedxpyllarxxxxxxxxxxxxxxxsy3fmg',
      'z1qxemdeddedxsentynelxxxxxxxxxxxxxwy0r2r',
      'z1qxemdeddedxstakexxxxxxxxxxxxxxxxjv8v62'
    ];
    final r = await _conn.query(
        '''SELECT T1.amount as rewardAmount, T2.address as source, T1.tokenStandard
                  FROM accountblocks T1
                  INNER JOIN accountBlocks T2
                    ON T1.descendantOf = T2.pairedAccountBlock and T2.method = 'Mint'
                  WHERE T1.hash = @hash and (T1.tokenStandard = 'zts1znnxxxxxxxxxxxxx9z4ulx' or T1.tokenStandard = 'zts1qsrxxxxxxxxxxxxxmrhjll') and T2.address = ANY(@contracts)
                  ORDER BY T1.momentumHeight DESC LIMIT 1''',
        {'hash': receiveBlockHash, 'contracts': rewardContracts}).toList();
    if (r.isNotEmpty) {
      return {
        'rewardAmount': r[0][0],
        'source': r[0][1],
        'tokenStandard': r[0][2]
      };
    }
    return {};
  }

  insertMomentum(Momentum momentum) async {
    final json = momentum.toJson();
    json['txCount'] = momentum.content.length;
    await _conn.execute(
        'INSERT INTO ${Table.momentums} VALUES (@height, @hash, @timestamp, @txCount, @producer) ON CONFLICT (height) DO NOTHING',
        json);
  }

  insertAccount(AccountBlock block) async {
    final json = block.toJson();
    json['blockCount'] = block.height;
    await _conn.execute(
        'INSERT INTO ${Table.accounts} VALUES (@address, @blockCount, @publicKey) ON CONFLICT (address) DO UPDATE SET blockCount = @blockCount',
        json);
  }

  updateAccountDelegate(
      String address, String delegate, int delegationStartTimestamp) async {
    await _conn.execute('''
        UPDATE ${Table.accounts}
        SET delegate = @delegate, delegationStartTimestamp = @delegationStartTimestamp
        WHERE address = @address
        ''', {
      'address': address,
      'delegate': delegate,
      'delegationStartTimestamp': delegationStartTimestamp
    });
  }

  insertBalance(String? address, BalanceInfoListItem balance) async {
    await _conn.execute(
        'INSERT INTO ${Table.balances} VALUES (@address, @tokenStandard, @balance) ON CONFLICT (address, tokenStandard) DO UPDATE SET balance = @balance',
        {
          'address': address,
          'tokenStandard': balance.token!.tokenStandard.toString(),
          'balance': balance.balance
        });
  }

  insertAccountBlock(AccountBlock block, TxData? data) async {
    final json = block.toJson();
    json['pairedAccountBlock'] =
        block.pairedAccountBlock?.hash.toString() ?? '';
    json['method'] = data?.method ?? '';
    json['input'] = data?.inputs ?? {};
    json['momentumHash'] =
        block.confirmationDetail?.momentumHash.toString() ?? '';
    json['momentumTimestamp'] =
        block.confirmationDetail?.momentumTimestamp ?? '';
    json['momentumHeight'] = block.confirmationDetail?.momentumHeight ?? '';

    await _conn.execute('''
        INSERT INTO ${Table.accountBlocks}
        VALUES (@hash, @momentumHash, @momentumTimestamp, @momentumHeight, @blockType, @height, @address, @toAddress, @amount, @tokenStandard, @data, @method, @input, @pairedAccountBlock)
        ON CONFLICT (hash) DO UPDATE SET method = @method, input = @input, pairedAccountBlock = @pairedAccountBlock
        ''', json);

    if (block.pairedAccountBlock?.hash != null) {
      await _conn.execute('''
        UPDATE ${Table.accountBlocks}
        SET pairedAccountBlock = @hash
        WHERE hash = @pairedAccountBlock
        ''', json);
    }

    if (block.descendantBlocks.isNotEmpty) {
      await Future.forEach(block.descendantBlocks, (AccountBlock b) async {
        await _conn.execute('''
        UPDATE ${Table.accountBlocks}
        SET descendantOf = @hash
        WHERE hash = @descendantBlock
        ''', {
          'hash': block.hash.toString(),
          'descendantBlock': b.hash.toString()
        });
      });
    }
  }

  insertToken(Token token) async {
    await _conn.execute(
        'INSERT INTO ${Table.tokens} VALUES (@tokenStandard, @name, @symbol, @domain, @decimals, @owner, @totalSupply, @maxSupply, @isBurnable, @isMintable, @isUtility) ON CONFLICT (tokenStandard) DO UPDATE SET domain = @domain, totalSupply = @totalSupply, maxSupply = @maxSupply',
        token.toJson());
  }

  insertPillar(PillarInfo pillar) async {
    final json = pillar.toJson();
    json['giveMomentumRewardPercentage'] = pillar.giveMomentumRewardPercentage;
    json['giveDelegateRewardPercentage'] = pillar.giveDelegateRewardPercentage;
    json['epochProducedMomentums'] = pillar.currentStats.producedMomentums;
    json['epochExpectedMomentums'] = pillar.currentStats.expectedMomentums;

    await _conn.execute('''
        INSERT INTO ${Table.pillars} VALUES (@ownerAddress, @producerAddress, @withdrawAddress, @name, @rank,
        @giveMomentumRewardPercentage, @giveDelegateRewardPercentage, @isRevocable, @revokeCooldown, @revokeTimestamp, @weight,
        @epochProducedMomentums, @epochExpectedMomentums)
        ON CONFLICT (ownerAddress) DO UPDATE SET producerAddress = @producerAddress, withdrawAddress = @withdrawAddress, name = @name,
        rank = @rank, giveMomentumRewardPercentage = @giveMomentumRewardPercentage, giveDelegateRewardPercentage = @giveDelegateRewardPercentage,
        isRevocable = @isRevocable, revokeCooldown = @revokeCooldown, revokeTimestamp = @revokeTimestamp, weight = @weight,
        epochProducedMomentums = @epochProducedMomentums, epochExpectedMomentums = @epochExpectedMomentums
        ''', json);
  }

  updatePillarSpawnInfo(
      String ownerAddress, int spawnTimestamp, int slotCostQsr) async {
    await _conn.execute('''
        UPDATE ${Table.pillars}
        SET spawnTimestamp = @spawnTimestamp, slotCostQsr = @slotCostQsr
        WHERE ownerAddress = @ownerAddress
        ''', {
      'spawnTimestamp': spawnTimestamp,
      'slotCostQsr': slotCostQsr,
      'ownerAddress': ownerAddress
    });
  }

  setPillarAsRevoked(String ownerAddress) async {
    await _conn.execute('''
        UPDATE ${Table.pillars}
        SET isRevoked = @isRevoked
        WHERE ownerAddress = @ownerAddress
        ''', {'isRevoked': true, 'ownerAddress': ownerAddress});
  }

  insertSentinel(SentinelInfo sentinel) async {
    final json = sentinel.toJson();
    json['owner'] = sentinel.owner.toString();
    await _conn.execute('''
        INSERT INTO ${Table.sentinels} VALUES (@owner, @registrationTimestamp, @isRevocable, @revokeCooldown, @active)
        ON CONFLICT (owner) DO UPDATE SET isRevocable = @isRevocable, revokeCooldown = @revokeCooldown, active = @active
        ''', json);
  }

  insertStake(
      String id,
      String address,
      int startTimestamp,
      int expirationTimestamp,
      int znnAmount,
      int durationInSec,
      String cancelId) async {
    final json = {};
    json['id'] = id;
    json['address'] = address;
    json['startTimestamp'] = startTimestamp;
    json['expirationTimestamp'] = expirationTimestamp;
    json['znnAmount'] = znnAmount;
    json['durationInSec'] = durationInSec;
    json['isActive'] = true;
    json['cancelId'] = cancelId;
    await _conn.execute(
        'INSERT INTO ${Table.stakes} VALUES (@id, @address, @startTimestamp, @expirationTimestamp, @znnAmount, @durationInSec, @isActive, @cancelId) ON CONFLICT (id) DO NOTHING',
        json);
  }

  setStakeInactive(String cancelId) async {
    await _conn.execute('''
        UPDATE ${Table.stakes}
        SET isActive = @isActive
        WHERE cancelId = @cancelId
        ''', {'cancelId': cancelId, 'isActive': false});
  }

  insertProject(Project project, String votingId) async {
    final json = project.toJson();
    json['votingId'] = votingId;
    json['yesVotes'] = project.voteBreakdown.yes;
    json['noVotes'] = project.voteBreakdown.no;
    json['totalVotes'] = project.voteBreakdown.total;

    await _conn.execute('''
        INSERT INTO ${Table.projects} VALUES (@id, @votingId, @owner, @name,
        @description, @url, @znnFundsNeeded, @qsrFundsNeeded, @creationTimestamp, @lastUpdateTimestamp, @status, @yesVotes, @noVotes, @totalVotes)
        ON CONFLICT (id) DO UPDATE SET lastUpdateTimestamp = @lastUpdateTimestamp, status = @status, yesVotes = @yesVotes, noVotes = @noVotes,
        totalVotes = @totalVotes
        ''', json);
  }

  insertProjectPhase(Phase phase, String votingId) async {
    final json = phase.toJson();
    json['votingId'] = votingId;
    json['yesVotes'] = phase.voteBreakdown.yes;
    json['noVotes'] = phase.voteBreakdown.no;
    json['totalVotes'] = phase.voteBreakdown.total;

    await _conn.execute('''
        INSERT INTO ${Table.projectPhases} VALUES (@id, @projectId, @votingId, @name,
        @description, @url, @znnFundsNeeded, @qsrFundsNeeded, @creationTimestamp, @acceptedTimestamp, @status, @yesVotes, @noVotes, @totalVotes)
        ON CONFLICT (id) DO UPDATE SET acceptedTimestamp = @acceptedTimestamp, status = @status, yesVotes = @yesVotes, noVotes = @noVotes,
        totalVotes = @totalVotes
        ''', json);
  }

  insertVote(AccountBlock block, String voterAddress, String projectId,
      String phaseId, String votingId, int vote) async {
    final json = {};
    json['momentumHash'] =
        block.confirmationDetail?.momentumHash.toString() ?? '';
    json['momentumTimestamp'] =
        block.confirmationDetail?.momentumTimestamp ?? '';
    json['momentumHeight'] = block.confirmationDetail?.momentumHeight ?? '';
    json['voterAddress'] = voterAddress;
    json['projectId'] = projectId;
    json['phaseId'] = phaseId;
    json['votingId'] = votingId;
    json['vote'] = vote;

    await _conn.execute('''
        INSERT INTO ${Table.votes} VALUES (DEFAULT, @momentumHash, @momentumTimestamp, @momentumHeight, @voterAddress, @projectId, @phaseId, @votingId, @vote)
        ''', json);
  }

  updatePillarVotingActivity(String ownerAddress, double votingActivity) async {
    await _conn.execute('''
        UPDATE ${Table.pillars}
        SET votingActivity = @votingActivity
        WHERE ownerAddress = @ownerAddress
        ''', {'votingActivity': votingActivity, 'ownerAddress': ownerAddress});
  }

  insertPlasmaFusion(
      String providerAddress,
      FusionEntry fusion,
      String cancelId,
      String momentumHash,
      int momentumTimestamp,
      int momentumHeight) async {
    final json = fusion.toJson();
    json['isActive'] = true;
    json['cancelId'] = cancelId;
    json['address'] = providerAddress;
    json['momentumHash'] = momentumHash;
    json['momentumTimestamp'] = momentumTimestamp;
    json['momentumHeight'] = momentumHeight;
    await _conn.execute(
        'INSERT INTO ${Table.fusions} VALUES (@id, @address, @beneficiary, @momentumHash, @momentumTimestamp, @momentumHeight, @qsrAmount, @expirationHeight, @isActive, @cancelId) ON CONFLICT (id) DO NOTHING',
        json);
  }

  setPlasmaFusionInactive(String cancelId) async {
    await _conn.execute('''
        UPDATE ${Table.fusions}
        SET isActive = @isActive
        WHERE cancelId = @cancelId
        ''', {'cancelId': cancelId, 'isActive': false});
  }

  updateCumulativeRewards(
      String address, int rewardType, int amount, String tokenStandard) async {
    final json = {};
    json['address'] = address;
    json['rewardType'] = rewardType;
    json['amount'] = amount;
    json['tokenStandard'] = tokenStandard;
    await _conn.execute(
        'INSERT INTO ${Table.cumulativeRewards} VALUES (DEFAULT, @address, @rewardType, @amount, @tokenStandard) ON CONFLICT (address, rewardType, tokenStandard) DO UPDATE SET amount = cumulativeRewards.amount + @amount',
        json);
  }

  insertRewardTransaction(
      String hash,
      String address,
      int rewardType,
      int momentumTimestamp,
      int momentumHeight,
      int amount,
      String tokenStandard) async {
    final json = {};
    json['hash'] = hash;
    json['address'] = address;
    json['rewardType'] = rewardType;
    json['momentumTimestamp'] = momentumTimestamp;
    json['momentumHeight'] = momentumHeight;
    json['amount'] = amount;
    json['tokenStandard'] = tokenStandard;
    await _conn.execute(
        'INSERT INTO ${Table.rewardTransactions} VALUES (@hash, @address, @rewardType, @momentumTimestamp, @momentumHeight, @amount, @tokenStandard) ON CONFLICT (hash) DO NOTHING',
        json);
  }
}
