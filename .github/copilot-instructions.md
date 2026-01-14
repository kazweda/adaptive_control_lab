# AI Coding Agent Instructions

## Project Overview

This is a **Flutter-based control systems simulation app** comparing PID control and Self-Tuning Regulator (STR) performance on discrete-time plant models. The app visualizes control behavior in real-time using time-series charts.

## Architecture

### Core Structure (lib/)

```
control/         → Control algorithms (plant, pid, disturbance) - MUST have 90%+ test coverage
simulation/      → State management & time-stepping (Simulator class)
ui/              → Flutter widgets (main_screen, plot)
```

**Key Pattern**: Separation of control logic from UI
- Control models are **pure Dart classes** with no Flutter dependencies
- Plant models implement `PlantModel` interface (supports 1st & 2nd order via `setPlantOrder()`)
- `Simulator` coordinates plant + controller + disturbance, maintains history for plotting
- UI layer consumes `Simulator` state via `Timer.periodic` (50ms intervals)

### Data Flow

1. User adjusts parameters (target value, PID gains, plant params) → UI updates `Simulator` properties
2. `Timer.periodic` triggers `Simulator.step()` → calculates error, computes control input, updates plant
3. History lists (`historyTarget`, `historyOutput`, `historyControl`) store data for `fl_chart` visualization
4. History is auto-trimmed to `maxHistoryLength` (default 5000) to prevent memory bloat

### Plant Selection Mechanism

`Simulator.setPlantOrder(useSecondOrder: bool)` switches between models:
- **1st order** (default): `y(k) = a*y(k-1) + b*u(k-1)` via `Plant` class
- **2nd order**: `y(k) = a1*y(k-1) + a2*y(k-2) + b1*u(k-1) + b2*u(k-2)` via `SecondOrderPlant`
- Both implement `PlantModel` interface for abstraction
- Plant switch resets all history (simulation restart needed for UI consistency)

### Disturbance Module

`Disturbance` class generates input disturbances for testing control robustness:
- `DisturbanceType`: none | step | impulse | sinusoid | noise
- Set via `Simulator.setDisturbanceType(type)` which creates default parameters
- Applied in `Simulator.step()`: `plant.step(_controlInput + disturbance.next())`
- Useful for testing PID response to external shocks

## Development Workflow

### Testing (CRITICAL)

**Zero-tolerance policy for warnings and test failures in PRs.**

```bash
# Required before every PR
flutter analyze    # Must output: "No issues found!"
flutter test       # All tests must pass
dart format .      # Auto-format all files
```

**Test Coverage Requirements**:
- `lib/control/`: 90%+ (enforced - see `docs/QUALITY_POLICY.md`)
- `lib/simulation/`: 90%+
- `lib/ui/`: 50%+ (basic behavior tests)

**Pattern**: Control logic tests use mathematical verification
- Example: `test/control/plant_test.dart` validates discrete difference equations
- Use `closeTo(expected, tolerance)` for floating-point comparisons
- Include stability tests (e.g., steady-state convergence for |a| < 1)

### Git Workflow

**Branch naming**: `feature/`, `fix/`, `refactor/`, `docs/`

**Commit convention**:
```
feat: Add feature
fix: Fix bug
refactor: Restructure code
test: Add/modify tests
docs: Update documentation
```

**CI Pipeline** (.github/workflows/test.yml):
- Runs on PR to `main` branch
- Verifies: formatting, analysis, tests with coverage
- Flutter version: 3.38.6 stable

### PR Template

All PRs use `.github/pull_request_template.md` which requires:
- Implementation description
- Related issue reference (e.g., `Implements #4`)
- Test checklist completion
- Adherence to `docs/QUALITY_POLICY.md`

## Code Conventions

### Dart Specifics

**Comment style**: Use Japanese for domain-specific math/control concepts
```dart
/// PID制御器
/// 制御式： u(k) = Kp * e(k) + Ki * Σe(k) + Kd * Δe(k)
class PIDController { ... }
```

**Math notation**: Document discrete-time equations in comments
- Plant: `y(k) = a * y(k-1) + b * u(k-1)`
- Variables use `_previousInput`, `_output` for time-indexed states
- State variables prefixed with `_` (private), named by time-step (e.g., `_prevOutput`, `_prevPrevInput`)

**Deprecated API handling**: Project uses Material 3
- Replace `Colors.grey.withOpacity(0.2)` with `Colors.grey.withValues(alpha: 0.2)`
- See `docs/QUALITY_POLICY.md` for common deprecation fixes

**Control Algorithm Pattern**:
- All control classes have `.reset()` method to clear internal state (critical for test isolation)
- Use `.step()` or `.compute()` for single-step updates
- Store history internally only if needed; `Simulator` maintains global history
- Never perform floating-point equality checks—use `closeTo(expected, 0.001)` in tests

### UI Patterns

**State management**: `StatefulWidget` with manual `setState()`
- No complex state libraries (Provider, Bloc, etc.)
- Timer-driven updates: `Timer.periodic(Duration(milliseconds: 50), ...)`

**Chart library**: `fl_chart` (v0.70.1)
- Data binding: `FlSpot(index, value)` from history lists
- Window management: UI supports 200/500/1000/all data points via dropdown
- Performance: Limit visible window to 200 during simulation to prevent lag

## Future Roadmap

**Planned features** (see README.md):
- Self-Tuning Regulator (STR) with Recursive Least Squares (RLS)
- Forgetting factor for RLS
- Pole placement control law
- Animation exercises (elevator, drone, vehicle simulations) - see `docs/PHASE2_4_ANIMATION_EXERCISES.md`

**When implementing STR**: Create `lib/control/str.dart` and `lib/control/rls.dart` following existing patterns in `plant.dart` and `pid.dart`.

## Key Files Reference

- `lib/simulation/simulator.dart`: Central coordinator - start here to understand data flow
- `lib/control/plant.dart`: 1st order discrete-time plant model
- `lib/control/second_order_plant.dart`: 2nd order plant model
- `lib/control/plant_model.dart`: PlantModel interface (key abstraction)
- `lib/control/pid.dart`: PID controller implementation
- `lib/control/disturbance.dart`: Disturbance signal generator (step, impulse, sinusoid, noise)
- `test/control/plant_test.dart`: Test pattern for control algorithms
- `docs/DEVELOPMENT.md`: Complete development process guide
- `docs/QUALITY_POLICY.md`: Detailed quality standards

## Quick Commands

```bash
# Run app
flutter run

# Run specific test file
flutter test test/control/plant_test.dart

# Generate coverage report (requires lcov/genhtml)
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Create PR with gh CLI
gh pr create --title "feat: Feature name" --body "Implements #issue_number"
```

## Gotchas

1. **History memory management**: `Simulator` auto-trims history to prevent unbounded growth - don't disable this without performance testing
2. **Timer lifecycle**: Always cancel `Timer` in `dispose()` to prevent memory leaks
3. **Flutter version**: CI uses 3.38.6 stable - match locally for consistent linting
4. **Test isolation**: Reset controller/plant state between tests using `.reset()` methods
