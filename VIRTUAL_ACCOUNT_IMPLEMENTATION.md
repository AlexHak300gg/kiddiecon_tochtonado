# Virtual Account System Implementation

## Overview
This implementation adds a comprehensive virtual account system with daily interest calculation powered by Android AlarmManager (plus in-app timer fallback) for background processing.

## Features Implemented

### 1. Core Models
- **Account Model** (`lib/models/account.dart`): Manages balance, daily rate, and calculation timestamps
- **Operation Model** (`lib/models/operation.dart`): Tracks all financial transactions with metadata

### 2. Services
- **AccountService** (`lib/services/account_service.dart`): 
  - Firebase integration with real-time streams
  - Local JSON caching for offline capability
  - Interest calculation for missed days
  - Operation logging with proper balance tracking
- **DailyInterestService** (`lib/services/daily_interest_service.dart`):
  - Android AlarmManager periodic task (every 45 minutes) with timer fallback for other platforms
  - Automatic daily interest calculation at 00:00
  - Compensation for missed days when app opens

### 3. UI Screens
- **AccountSettingsScreen** (`lib/screens/account_settings_screen.dart`):
  - Parent interface to manage daily interest rates
  - Real-time account information display
  - Interest rate configuration (annual percentage)
- **OperationHistoryScreen** (`lib/screens/operation_history_screen.dart`):
  - Detailed transaction history for children
  - Statistics and filtering by operation type
  - Balance progression tracking

### 4. Enhanced Child Home Screen
- Shows today's earned interest
- Real-time balance updates
- Quick access to detailed operation history

## Firebase Structure

### Account Data
```
/children/{childId}/account: {
  "balance": 1000.00,
  "dailyRate": 0.0001,  // 0.01% annually
  "lastCalculatedAt": "2024-01-01T00:00:00.000Z",
  "updatedAt": "2024-01-01T12:00:00.000Z"
}
```

### Operation History
```
/children/{childId}/history/{operationId}: {
  "type": "daily_interest",
  "amount": 0.10,
  "reason": "Ежедневный процент за 01.01.2024",
  "timestamp": "2024-01-01T00:00:00.000Z",
  "balanceBefore": 1000.00,
  "balanceAfter": 1000.10
}
```

## Interest Calculation Formula

### Daily Rate
```
daily_rate = annual_rate / 365
```

### Compound Interest
```
new_balance = current_balance * (1 + daily_rate)
```

### Example
- Annual rate: 0.01% (0.0001)
- Daily rate: 0.01% / 365 = 0.000027%
- On 1000₽ balance: 1000 * (1 + 0.0001) = 1000.10₽ daily

## Background Processing

### AlarmManager Integration
- **Frequency**: Every 45 minutes
- **Task**: Checks if interest calculation is needed for current day
- **Logic**: Only calculates if `lastCalculatedAt` is before today
- **Fallback**: Built-in timer worker for iOS/web/desktop + missed-day compensation on launch

### Compensation for Missed Days
When app opens after being closed for multiple days:
1. Calculates days since last interest payment
2. Applies compound interest for each missed day
3. Updates `lastCalculatedAt` to today
4. Logs each day's calculation separately

## Local Storage

### JSON Caching
- Account data cached locally in `account_{childId}.json`
- Operations cached in `operations_{childId}.json`
- Automatic sync with Firebase when online
- Offline capability with conflict resolution

## Parent Controls

### Interest Rate Management
- Parents can set annual percentage (0-100%)
- Changes apply to future calculations only
- Real-time validation
- Default: 0.01% annually

### Account Monitoring
- Real-time balance viewing
- Transaction history access
- Settings access via child cards

## Race Condition Prevention

### Firebase Transactions
- All balance updates use atomic transactions
- History and account updates in single operation
- Legacy balance (`parents_children`) synchronized
- Error handling with rollback capability

## User Experience

### Child Interface
- **Header Card**: Shows balance + today's interest
- **History Section**: Recent operations with "Подробнее" button
- **Real-time Updates**: Instant balance changes

### Parent Interface
- **Settings Button**: On each child card for account management
- **Transfer Updates**: Now logged as operations
- **Interest Configuration**: Simple percentage input with validation

## Technical Implementation Details

### Dependencies Added
```yaml
android_alarm_manager_plus: ^5.0.0
flutter_local_notifications: ^17.2.2
path_provider: ^2.1.3
```

### Platform Configuration
- **Android**: Background execution permissions, boot receiver
- **iOS**: Background modes for fetch and processing
- **Notifications**: Optional motivation notifications (future enhancement)

### Error Handling
- Comprehensive try-catch blocks
- User-friendly error messages
- Automatic retry mechanisms
- Debug logging for troubleshooting

## Testing

### Unit Tests
- Model serialization/deserialization
- Interest calculation accuracy
- Operation type handling

### Integration Testing
- Firebase transaction integrity
- AlarmManager/timer background task execution
- Offline/online synchronization

## Future Enhancements

### Notification System
- Daily interest notifications to children
- Motivational messages
- Achievement badges

### Advanced Analytics
- Interest earnings over time
- Savings growth projections
- Parent insights dashboard

### Security
- Operation confirmation dialogs
- Rate change approvals
- Audit trail maintenance

## Migration Notes

### Existing Data
- Legacy balance fields maintained
- Gradual migration to new account structure
- Backward compatibility ensured

### Deployment
- AlarmManager scheduling (with timer fallback) on app start
- Database initialization with defaults
- Error recovery mechanisms

This implementation provides a robust, scalable foundation for the virtual account system with comprehensive interest calculation and user-friendly management interfaces.