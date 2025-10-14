import 'dart:convert';

class RobotCommand {
  final String command;
  final Map<String, dynamic> params;

  RobotCommand({required this.command, required this.params});

  String toJson() {
    final Map<String, dynamic> json = {'command': command, 'params': params};
    return jsonEncode(json);
  }


  factory RobotCommand.driveDirect({
    required int leftSpeed,
    required int rightSpeed,
  }) {
    return RobotCommand(
      command: 'DRIVE_DIRECT',
      params: {
        'left_speed': leftSpeed.clamp(-100, 100),
        'right_speed': rightSpeed.clamp(-100, 100),
      },
    );
  }

  factory RobotCommand.executePath({required List<Map<String, double>> path}) {
    return RobotCommand(command: 'EXECUTE_PATH', params: {'path': path});
  }

  factory RobotCommand.emergencyStop() {
    return RobotCommand(command: 'ESTOP', params: {});
  }

  factory RobotCommand.setGestureMode({
    required String mode,
    required bool active,
  }) {
    return RobotCommand(
      command: 'SET_GESTURE_MODE',
      params: {'mode': mode, 'active': active},
    );
  }

  factory RobotCommand.getBatteryStatus() {
    return RobotCommand(command: 'GET_BATTERY_STATUS', params: {});
  }
}
