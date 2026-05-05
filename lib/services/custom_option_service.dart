import 'package:uuid/uuid.dart';
import '../models/custom_option.dart';
import '../utils/constants.dart';
import 'database_service.dart';

/// 自定义选项服务
class CustomOptionService {
  static final CustomOptionService _instance = CustomOptionService._internal();
  factory CustomOptionService() => _instance;
  CustomOptionService._internal();

  final DatabaseService _dbService = DatabaseService();
  final _uuid = const Uuid();

  /// 获取指定类型的所有选项（预设 + 自定义）
  Future<List<String>> getOptions(CustomOptionType type, {String? category}) async {
    final options = <String>[];

    // 添加预设选项
    switch (type) {
      case CustomOptionType.category:
        options.addAll(PresetCategories.defaults);
        break;
      case CustomOptionType.location:
        options.addAll(_getDefaultLocations(category));
        break;
      case CustomOptionType.unit:
        options.addAll(['个', '盒', '袋', '瓶', '包', '罐', '份']);
        break;
      case CustomOptionType.subCategory:
        options.addAll(_getDefaultSubCategories(category));
        break;
    }

    // 添加自定义选项
    final customOptions = await getCustomOptions(type, category: category);
    for (final option in customOptions) {
      if (!options.contains(option.value)) {
        options.add(option.value);
      }
    }

    return options;
  }

  /// 获取自定义选项（公开方法）
  Future<List<CustomOption>> getCustomOptions(
    CustomOptionType type, {
    String? category,
  }) async {
    final db = await _dbService.database;

    String where = 'option_type = ?';
    List<dynamic> whereArgs = [type.name];

    if (category != null) {
      where += ' AND (category IS NULL OR category = ?)';
      whereArgs.add(category);
    } else {
      where += ' AND category IS NULL';
    }

    final List<Map<String, dynamic>> maps = await db.query(
      DatabaseService.tableCustomOptions,
      where: where,
      whereArgs: whereArgs,
      orderBy: 'usage_count DESC, created_at DESC',
    );

    return maps.map((map) => CustomOption.fromJson(map)).toList();
  }

  /// 添加自定义选项
  Future<CustomOption> addOption({
    required CustomOptionType type,
    String? category,
    required String value,
  }) async {
    final now = DateTime.now();
    final option = CustomOption(
      id: _uuid.v4(),
      type: type,
      category: category,
      value: value,
      usageCount: 0,
      createdAt: now,
      updatedAt: now,
    );

    final db = await _dbService.database;
    await db.insert(
      DatabaseService.tableCustomOptions,
      option.toJson(),
    );

    return option;
  }

  /// 删除自定义选项
  Future<void> deleteOption(String id) async {
    final db = await _dbService.database;
    await db.delete(
      DatabaseService.tableCustomOptions,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 增加使用次数
  Future<void> incrementUsage(String value, CustomOptionType type, {String? category}) async {
    final db = await _dbService.database;

    String where = 'option_type = ? AND value = ?';
    List<dynamic> whereArgs = [type.name, value];

    if (category != null) {
      where += ' AND category = ?';
      whereArgs.add(category);
    }

    await db.rawUpdate(
      'UPDATE ${DatabaseService.tableCustomOptions} SET usage_count = usage_count + 1, updated_at = ? WHERE $where',
      [DateTime.now().toIso8601String(), ...whereArgs],
    );
  }

  /// 检查选项是否存在
  Future<bool> optionExists(String value, CustomOptionType type, {String? category}) async {
    final db = await _dbService.database;

    String where = 'option_type = ? AND value = ?';
    List<dynamic> whereArgs = [type.name, value];

    if (category != null) {
      where += ' AND category = ?';
      whereArgs.add(category);
    }

    final result = await db.query(
      DatabaseService.tableCustomOptions,
      where: where,
      whereArgs: whereArgs,
    );

    return result.isNotEmpty;
  }

  /// 获取默认存放位置
  List<String> _getDefaultLocations(String? category) {
    if (category == PresetCategories.food) {
      return ['冰箱冷藏', '冰箱冷冻', '储藏室', '厨房'];
    } else if (category == PresetCategories.drug) {
      return ['药箱', '床头柜', '冰箱', '随身携带'];
    }
    return ['储藏室'];
  }

  /// 获取默认子分类
  List<String> _getDefaultSubCategories(String? category) {
    if (category == PresetCategories.food) {
      return ['生鲜食品', '包装食品', '调味品', '饮料'];
    } else if (category == PresetCategories.drug) {
      return ['处方药', '非处方药', '保健品', '医疗器械'];
    }
    return [];
  }
}
