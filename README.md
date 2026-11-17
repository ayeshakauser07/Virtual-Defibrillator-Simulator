# Virtual Defibrillator Simulator | MATLAB & Simulink

An interactive software-based defibrillator simulation developed using MATLAB and Simulink, demonstrating capacitor charging, simulated shock delivery, safe disarming, and electrical waveform analysis.

## Project Overview

The Virtual Defibrillator Simulator is a biomedical engineering project designed to demonstrate the fundamental electrical principles behind cardiac defibrillation through a software-based simulation.

The system features an interactive graphical user interface (GUI) that allows users to select energy levels, adjust patient-load impedance, charge the capacitor, simulate shock delivery, and safely discharge stored energy through an internal dump resistor.

The simulation model is constructed programmatically using fundamental Simulink blocks and differential equations.

## Key Features

- **Adjustable Energy Selection:** Select energy levels of 50, 100, 150, 200, 300, and 360 Joules.
- **Variable Patient Impedance:** Adjust simulated patient-load resistance between 25 and 150 Ohms.
- **Capacitor Charging:** Simulate capacitor charging to the selected energy level.
- **READY Indicator:** Visual indication when the capacitor reaches its target voltage.
- **SHOCK Function:** Simulate electrical discharge through the patient-load resistance.
- **DISARM Function:** Safely simulate internal energy discharge through a dedicated dump resistor without delivering energy to the patient load.
- **RESET Function:** Restore default simulation settings.
- **Waveform Visualization:** Display capacitor voltage, discharge current, and energy delivery.
- **Automatic Calculations:** Calculate electrical parameters and simulation performance metrics.

## Technologies Used

- MATLAB
- Simulink
- MATLAB GUI Components
- Differential Equation Modeling
- Electrical Circuit Simulation

## Simulation Parameters

| Parameter | Value |
|---|---:|
| Capacitance | 32 µF |
| Inductance | 50 mH |
| Supply Voltage | 5000 V |
| Charging Resistance | 30 kΩ |
| Internal Resistance | 10 Ω |
| Internal Dump Resistance | 1000 Ω |

## Simulation Outputs

The simulator provides graphical visualization of:

1. Capacitor voltage during charging and discharging.
2. Discharge current through the simulated patient load.
3. Energy delivered to the patient-load resistance over time.
4. Internal dump current and stored energy during disarming.

## Automatically Calculated Parameters

- Target capacitor voltage
- Capacitor charging time
- Peak discharge current
- Delivered energy
- Energy delivery efficiency
- Damping characteristics

## How to Run the Project

### Requirements

- MATLAB
- Simulink

### Execution Steps

1. Clone or download this repository.
2. Open MATLAB.
3. Navigate to the project directory.
4. Open the MATLAB folder.
5. Run the following command:

```matlab
build_defib_simulink_disarm
```

6. The graphical interface will launch.
7. Select the desired energy level and patient impedance.
8. Press **CHARGE** to charge the capacitor.
9. Once READY, choose **SHOCK** or **DISARM**.
10. Use **RESET** to restore the default settings.

The Simulink model is generated automatically when the main MATLAB function executes.

## Project Objective

The objective of this project is to explore the electrical principles involved in defibrillator operation, particularly capacitor-based energy storage, charging and discharging behavior, load impedance, and electrical energy delivery.

## Educational Disclaimer

This project is intended strictly for educational and simulation purposes. It is not a clinically validated defibrillator model, medical device, or substitute for a real defibrillator. It must not be used for patient treatment or connected to a human subject.

## Author

Ayesha Kauser

**Field:** Biomedical Engineering  
**Tools:** MATLAB | Simulink

