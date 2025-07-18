# Apex Methodology: Caffeine Crash Prediction

## Overview

Apex uses a pharmacokinetic model to predict caffeine crashes by tracking multiple doses throughout the day and calculating when blood caffeine levels will drop below a critical threshold. This methodology combines established scientific research on caffeine metabolism with personalized sensitivity factors.

## Core Scientific Principles

### 1. Caffeine Pharmacokinetics

Caffeine follows first-order elimination kinetics, meaning the rate of elimination is proportional to the amount present in the body. The plasma concentration over time can be modeled using:

```
C(t) = C₀ × e^(-kt)
```

Where:
- `C(t)` = Caffeine concentration at time t
- `C₀` = Initial caffeine concentration
- `k` = Elimination rate constant
- `t` = Time elapsed

### 2. Half-Life Calculations

The average caffeine half-life in healthy adults is **5-6 hours**, though this varies based on:
- Genetic factors (CYP1A2 enzyme variants)
- Smoking status (reduces half-life by ~50%)
- Pregnancy (increases half-life to 15-20 hours)
- Liver function
- Medications

Apex uses a default half-life of **5 hours** with user-adjustable sensitivity settings.

The elimination rate constant is calculated as:
```
k = ln(2) / t₁/₂ = 0.693 / 5 hours = 0.1386 hour⁻¹
```

### 3. Multiple Dose Superposition

When multiple caffeine doses are consumed, the total blood caffeine level is the sum of contributions from each dose:

```
C_total(t) = Σ[C_i × e^(-k(t - t_i))] for all doses where t > t_i
```

This principle of superposition allows Apex to accurately model complex consumption patterns.

## Crash Detection Algorithm

### 1. Baseline Threshold

A caffeine "crash" occurs when blood levels drop rapidly after being elevated. Apex defines the crash threshold as:

```
Crash Threshold = Peak Level × Sensitivity Factor
```

Where the sensitivity factor defaults to 0.3 (30% of peak) but is personalized during onboarding.

### 2. Rate of Change Analysis

Beyond absolute levels, Apex monitors the rate of caffeine decline:

```
dC/dt = -k × C(t)
```

Rapid declines (>20 mg/hour) combined with crossing the threshold trigger crash warnings.

### 3. Time Window Analysis

The algorithm uses a 24-hour sliding window to:
1. Track all caffeine intake
2. Calculate current blood levels
3. Project future levels for the next 12 hours
4. Identify crash risk periods

## Personalization Factors

### 1. Sensitivity Levels

Users select from three sensitivity presets during onboarding:

- **Low Sensitivity (0.2)**: Crash at 20% of peak
  - For regular/heavy caffeine users
  - Higher tolerance to fluctuations
  
- **Medium Sensitivity (0.3)**: Crash at 30% of peak
  - Default setting
  - Average caffeine response
  
- **High Sensitivity (0.4)**: Crash at 40% of peak
  - For occasional users
  - More sensitive to caffeine changes

### 2. Individual Metabolism

Future versions will incorporate:
- Custom half-life based on user feedback
- Machine learning to refine predictions
- Integration with sleep/activity data

## Implementation Details

### 1. Caffeine Content Database

Common drinks with standardized caffeine content (mg):
- Coffee (8 oz): 95 mg
- Espresso (1 oz): 63 mg
- Black Tea (8 oz): 47 mg
- Green Tea (8 oz): 28 mg
- Energy Drink (8 oz): 80 mg
- Soda (12 oz): 35 mg

### 2. Calculation Pipeline

```swift
1. Retrieve all caffeine entries from past 24 hours
2. For each entry:
   - Calculate time elapsed since consumption
   - Apply exponential decay formula
   - Sum remaining caffeine
3. Project forward:
   - Calculate levels at 15-minute intervals
   - Identify when threshold is crossed
   - Determine crash time
4. Schedule notification 30 minutes before predicted crash
```

### 3. Notification Strategy

- **Proactive Alerts**: 30 minutes before predicted crash
- **Smart Timing**: No notifications during typical sleep hours
- **Actionable Advice**: Suggest optimal re-dosing or alternatives

## Validation and Accuracy

### 1. Scientific Basis

The model is based on peer-reviewed research:
- Fredholm et al. (1999): "Actions of caffeine in the brain"
- Institute of Medicine (2014): "Caffeine for the Sustainment of Mental Task Performance"
- Nehlig (2018): "Interindividual Differences in Caffeine Metabolism"

### 2. Limitations

- Assumes linear pharmacokinetics (valid for typical doses)
- Doesn't account for caffeine tolerance development
- Simplified absorption model (instant vs. gradual)
- Individual variations can be significant

### 3. Future Improvements

- Bayesian updating based on user feedback
- Integration with wearable data (heart rate, sleep)
- Food interaction modeling
- Circadian rhythm considerations

## Safety Considerations

### 1. Recommended Limits

- FDA safe limit: 400 mg/day for adults
- Apex warns when approaching daily limits
- Special warnings for evening consumption

### 2. Health Disclaimers

- Not medical advice
- Consult healthcare providers for concerns
- Special populations (pregnant, cardiac conditions) should use caution

## Technical Implementation

### 1. Core Algorithm (Swift)

```swift
func calculateCaffeineLevel(entries: [CaffeineEntry], at time: Date) -> Double {
    let halfLife = 5.0 // hours
    let k = log(2) / halfLife
    
    return entries.reduce(0) { total, entry in
        let hoursElapsed = time.timeIntervalSince(entry.timestamp) / 3600
        guard hoursElapsed >= 0 else { return total }
        return total + entry.caffeineAmountMg * exp(-k * hoursElapsed)
    }
}
```

### 2. Crash Detection

```swift
func findCrashTime(entries: [CaffeineEntry], sensitivity: Double) -> Date? {
    let peakLevel = findPeakLevel(entries)
    let threshold = peakLevel * sensitivity
    
    // Project forward in 15-minute intervals
    for interval in stride(from: 0, to: 12*60, by: 15) {
        let checkTime = Date().addingTimeInterval(Double(interval * 60))
        let level = calculateCaffeineLevel(entries: entries, at: checkTime)
        
        if level < threshold && level > 0 {
            return checkTime
        }
    }
    return nil
}
```

## References

1. Blanchard, J., & Sawers, S. J. (1983). The absolute bioavailability of caffeine in man. European Journal of Clinical Pharmacology, 24(1), 93-98.

2. Fredholm, B. B., Bättig, K., Holmén, J., Nehlig, A., & Zvartau, E. E. (1999). Actions of caffeine in the brain with special reference to factors that contribute to its widespread use. Pharmacological Reviews, 51(1), 83-133.

3. Institute of Medicine. (2014). Caffeine for the Sustainment of Mental Task Performance: Formulations for Military Operations. Washington, DC: The National Academies Press.

4. Nehlig, A. (2018). Interindividual differences in caffeine metabolism and factors driving caffeine consumption. Pharmacological Reviews, 70(2), 384-411.

5. Temple, J. L., Bernard, C., Lipshultz, S. E., Czachor, J. D., Westphal, J. A., & Mestre, M. A. (2017). The safety of ingested caffeine: a comprehensive review. Frontiers in Psychiatry, 8, 80.

---

*Last Updated: July 2025*
*Version: 1.0*