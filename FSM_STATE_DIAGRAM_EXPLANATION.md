# FSM State Diagram Explanation
## Adaptive Four-Way Traffic Control System

## Overview
The traffic controller implements a Moore-type Finite State Machine (FSM) with 11 distinct states. The system operates cyclically through four directions (North, South, East, West) with adaptive timing based on traffic density sensors and includes a highest-priority emergency override mechanism.

---

## State Definitions

### 1. **IDLE (State 0)**
- **Description**: Initial power-on state
- **Duration**: Instantaneous
- **Outputs**: All lights RED
- **Next State**: Automatically transitions to ALL_RED_STATE
- **Purpose**: System initialization

### 2. **ALL_RED_STATE (State 10)**
- **Description**: Safety interval where all directions show RED
- **Duration**: 2 clock cycles (configurable via ALL_RED_TIME parameter)
- **Outputs**: All four directions show RED lights
- **Next State**: Cycles through directions in sequence (N→S→E→W→N...)
- **Purpose**: Provides safe transition period between direction changes

### 3. **NORTH_GREEN (State 1)**
- **Description**: North direction has green light
- **Duration**: Adaptive - depends on traffic_north sensor (10-40 cycles)
  - Low traffic (00): 10 cycles
  - Medium traffic (01): 20 cycles
  - High traffic (10): 30 cycles
  - Very High traffic (11): 40 cycles
- **Outputs**: 
  - North: GREEN
  - South: RED
  - East: RED
  - West: RED
- **Next State**: NORTH_YELLOW

### 4. **NORTH_YELLOW (State 2)**
- **Description**: North direction warning phase
- **Duration**: 3 clock cycles (fixed via YELLOW_TIME parameter)
- **Outputs**: 
  - North: YELLOW
  - All others: RED
- **Next State**: ALL_RED_STATE
- **Purpose**: Warns drivers that light is about to change

### 5. **SOUTH_GREEN (State 3)**
- **Description**: South direction has green light
- **Duration**: Adaptive based on traffic_south (10-40 cycles)
- **Outputs**: 
  - South: GREEN
  - All others: RED
- **Next State**: SOUTH_YELLOW

### 6. **SOUTH_YELLOW (State 4)**
- **Description**: South direction warning phase
- **Duration**: 3 clock cycles (fixed)
- **Outputs**: 
  - South: YELLOW
  - All others: RED
- **Next State**: ALL_RED_STATE

### 7. **EAST_GREEN (State 5)**
- **Description**: East direction has green light
- **Duration**: Adaptive based on traffic_east (10-40 cycles)
- **Outputs**: 
  - East: GREEN
  - All others: RED
- **Next State**: EAST_YELLOW

### 8. **EAST_YELLOW (State 6)**
- **Description**: East direction warning phase
- **Duration**: 3 clock cycles (fixed)
- **Outputs**: 
  - East: YELLOW
  - All others: RED
- **Next State**: ALL_RED_STATE

### 9. **WEST_GREEN (State 7)**
- **Description**: West direction has green light
- **Duration**: Adaptive based on traffic_west (10-40 cycles)
- **Outputs**: 
  - West: GREEN
  - All others: RED
- **Next State**: WEST_YELLOW

### 10. **WEST_YELLOW (State 8)**
- **Description**: West direction warning phase
- **Duration**: 3 clock cycles (fixed)
- **Outputs**: 
  - West: YELLOW
  - All others: RED
- **Next State**: ALL_RED_STATE

### 11. **EMERGENCY (State 9)**
- **Description**: Emergency vehicle override mode
- **Duration**: 30 clock cycles (fixed emergency duration)
- **Trigger**: emergency_override signal goes HIGH
- **Priority**: HIGHEST - can interrupt any state
- **Outputs**: Selected emergency direction gets GREEN, all others RED
- **Direction Selection**: Based on emergency_dir[1:0] input
  - 00: North GREEN
  - 01: South GREEN
  - 10: East GREEN
  - 11: West GREEN
- **Next State**: ALL_RED_STATE (after emergency clears)
- **Emergency Latch**: Signal is latched to prevent glitches during transitions

---

## State Transition Flow

### Normal Operation Cycle:
```
IDLE → ALL_RED_STATE → NORTH_GREEN → NORTH_YELLOW → ALL_RED_STATE → 
SOUTH_GREEN → SOUTH_YELLOW → ALL_RED_STATE → EAST_GREEN → EAST_YELLOW → 
ALL_RED_STATE → WEST_GREEN → WEST_YELLOW → ALL_RED_STATE → [Cycle Repeats]
```

### Emergency Override:
```
ANY_STATE → EMERGENCY (when emergency_override = 1)
           ↓
      ALL_RED_STATE (after emergency clears)
           ↓
      Resume normal cycle from NORTH_GREEN
```

---

## Key FSM Features

### 1. **Adaptive Timing Logic**
Each direction's green light duration is dynamically calculated based on real-time traffic density:
- **Function**: calculate_green_time(traffic_density[1:0])
- **Inputs**: 2-bit traffic sensor reading
- **Outputs**: Green light duration in clock cycles
- **Implementation**: Combinational logic using case statement
- **Benefit**: Optimizes traffic flow by giving more time to congested directions

### 2. **Emergency Override Priority**
- **Highest Priority**: Overrides all other state transitions
- **Latch Mechanism**: Prevents spurious transitions due to signal glitches
- **Safe Transition**: Returns to ALL_RED_STATE before resuming normal operation
- **Use Case**: Ambulance, fire truck, police vehicles needing immediate right-of-way

### 3. **Safety Features**
- **All-Red Interval**: Prevents conflicting green lights during transitions
- **Yellow Warning Phase**: Provides adequate warning time for vehicles
- **Synchronous Design**: All state changes occur on clock edges
- **Reset Capability**: Asynchronous active-low reset for immediate system recovery

### 4. **State Sequencing**
- **Round-Robin**: Fair scheduling through all four directions
- **Deterministic**: Predictable cycle time for traffic planning
- **Previous State Tracking**: Uses prev_state register to determine next direction
- **Prevents Starvation**: Every direction eventually gets green light

---

## Timing Parameters (Configurable)

| Parameter | Value (Clock Cycles) | Description |
|-----------|---------------------|-------------|
| YELLOW_TIME | 3 | Fixed yellow light duration |
| ALL_RED_TIME | 2 | Safety interval between directions |
| GREEN_LOW | 10 | Green time for low traffic |
| GREEN_MED | 20 | Green time for medium traffic |
| GREEN_HIGH | 30 | Green time for high traffic |
| GREEN_VHIGH | 40 | Green time for very high traffic |
| EMERGENCY_DURATION | 30 | Fixed emergency override time |

**Note**: These parameters are easily adjustable for different clock frequencies and traffic requirements. For real FPGA implementation, scale these values based on your system clock frequency.

---

## State Encoding

The FSM uses 4-bit binary encoding for 11 states:
- **Encoding Type**: Binary (straightforward, FPGA-friendly)
- **State Register**: 4-bit register (state[3:0])
- **Benefits**: 
  - Simple to decode
  - Minimal logic resources
  - Easy to debug
  - Standard synthesis tool support

---

## FSM Implementation Style

**Moore Machine Characteristics**:
- Outputs depend ONLY on current state
- State-based output generation
- Glitch-free outputs (registered)
- Predictable behavior

**Three-Block FSM Architecture**:
1. **State Register Block**: Sequential logic for state storage
2. **Next State Logic Block**: Combinational logic for state transitions
3. **Output Logic Block**: Registered outputs based on current state

---

## Reset Behavior

**Asynchronous Active-Low Reset**:
- When rst_n = 0:
  - All states reset to IDLE
  - All outputs set to RED
  - Timer resets to 0
  - Emergency latch clears
- Safe startup guaranteed
- Independent of clock edge
- Critical for system reliability

---

## Design Advantages

1. **Scalability**: Easy to add more directions or states
2. **Maintainability**: Clear state definitions and transitions
3. **Testability**: Each state can be tested independently
4. **Flexibility**: Timing parameters easily modified
5. **Safety**: Built-in safety intervals and single green enforcement
6. **Efficiency**: Adaptive timing optimizes traffic throughput
7. **Emergency Handling**: Real-world emergency vehicle support

---

## State Diagram Visualization

```
                    ┌──────────────┐
                    │     IDLE     │
                    └──────┬───────┘
                           │
                           ▼
                    ┌──────────────┐
             ┌─────►│ ALL_RED_STATE├─────┐
             │      └──────┬───────┘     │
             │             │             │
             │             ▼             │
             │      ┌──────────────┐    │
             │      │ NORTH_GREEN  │    │
             │      └──────┬───────┘    │
             │             │             │
             │             ▼             │
             │      ┌──────────────┐    │
             │      │NORTH_YELLOW  │    │
             │      └──────┬───────┘    │
             │             └─────────────┤
             │                           │
             │      ┌──────────────┐    │
             │      │ SOUTH_GREEN  │◄───┤
             │      └──────┬───────┘    │
             │             │             │
             │             ▼             │
             │      ┌──────────────┐    │
             │      │SOUTH_YELLOW  │    │
             │      └──────┬───────┘    │
             │             └─────────────┤
             │                           │
             │      ┌──────────────┐    │
             │      │  EAST_GREEN  │◄───┤
             │      └──────┬───────┘    │
             │             │             │
             │             ▼             │
             │      ┌──────────────┐    │
             │      │ EAST_YELLOW  │    │
             │      └──────┬───────┘    │
             │             └─────────────┤
             │                           │
             │      ┌──────────────┐    │
             │      │  WEST_GREEN  │◄───┤
             │      └──────┬───────┘    │
             │             │             │
             │             ▼             │
             │      ┌──────────────┐    │
             │      │ WEST_YELLOW  │    │
             │      └──────┬───────┘    │
             │             └─────────────┘
             │
             │      ┌──────────────┐
             └──────┤  EMERGENCY   │◄── Emergency Override
                    │ (Highest Pri)│    (from any state)
                    └──────────────┘
```

**Legend**:
- Solid arrows (─►): Normal state transitions
- Dashed concept: Emergency can interrupt from anywhere
- Loop structure: Continuous cycling through directions

---

## Conclusion

This FSM design provides a robust, adaptive, and safe traffic control system suitable for FPGA implementation. The clear state definitions, adaptive timing mechanisms, and emergency override capability make it suitable for real-world intelligent traffic management applications.
