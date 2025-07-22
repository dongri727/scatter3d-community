class AxisConfig {
  final String legend;
  final double min;
  final double max;

  const AxisConfig({
    required this.legend,
    required this.min,
    required this.max,
  });

  Map<String, dynamic> toMap() {
    return {
      'legend': legend,
      'min': min,
      'max': max,
    };
  }

  static AxisConfig fromMap(Map<String, dynamic> map) {
    return AxisConfig(
      legend: map['legend'] as String,
      min: (map['min'] as num).toDouble(),
      max: (map['max'] as num).toDouble(),
    );
  }

  AxisConfig copyWith({
    String? legend,
    double? min,
    double? max,
  }) {
    return AxisConfig(
      legend: legend ?? this.legend,
      min: min ?? this.min,
      max: max ?? this.max,
    );
  }
}

class ProjectAxisConfig {
  final String projectName;
  final AxisConfig xAxis;
  final AxisConfig yAxis;
  final AxisConfig zAxis;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectAxisConfig({
    required this.projectName,
    required this.xAxis,
    required this.yAxis,
    required this.zAxis,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'projectName': projectName,
      'axes': {
        'x': xAxis.toMap(),
        'y': yAxis.toMap(),
        'z': zAxis.toMap(),
      },
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  static ProjectAxisConfig fromMap(Map<String, dynamic> map) {
    final axes = map['axes'] as Map<String, dynamic>;
    return ProjectAxisConfig(
      projectName: map['projectName'] as String,
      xAxis: AxisConfig.fromMap(axes['x'] as Map<String, dynamic>),
      yAxis: AxisConfig.fromMap(axes['y'] as Map<String, dynamic>),
      zAxis: AxisConfig.fromMap(axes['z'] as Map<String, dynamic>),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  ProjectAxisConfig copyWith({
    String? projectName,
    AxisConfig? xAxis,
    AxisConfig? yAxis,
    AxisConfig? zAxis,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectAxisConfig(
      projectName: projectName ?? this.projectName,
      xAxis: xAxis ?? this.xAxis,
      yAxis: yAxis ?? this.yAxis,
      zAxis: zAxis ?? this.zAxis,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static ProjectAxisConfig createDefault({
    required String projectName,
    List<String>? headers,
  }) {
    final now = DateTime.now();
    return ProjectAxisConfig(
      projectName: projectName,
      xAxis: AxisConfig(
        legend: headers != null && headers.isNotEmpty ? headers[0] : 'X',
        min: 0.0,
        max: 100.0,
      ),
      yAxis: AxisConfig(
        legend: headers != null && headers.length > 1 ? headers[1] : 'Y',
        min: 0.0,
        max: 100.0,
      ),
      zAxis: AxisConfig(
        legend: headers != null && headers.length > 2 ? headers[2] : 'Z',
        min: 0.0,
        max: 100.0,
      ),
      createdAt: now,
      updatedAt: now,
    );
  }
}