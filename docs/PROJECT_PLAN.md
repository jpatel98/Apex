# Production Plan: Caffeine Crash Forecaster (Apex)

---

### ## 1. Project Overview

* **App Name:** Apex (working title)
* **Core Mission:** To provide users with a predictive tool to manage their caffeine intake, optimize their energy levels, and preemptively handle the "crash."
* **Target User:** Professionals, students, athletes, and anyone reliant on caffeine who wants to better understand its effects on their body.

---

### ## 2. Core Features (Minimum Viable Product)

The initial version must be lean and focused on solving the core problem.

* **User Profile Setup:**
    * **Input:** User's self-assessed **caffeine sensitivity** (Low, Medium, High) and **body weight**. These are critical for the prediction model.
    * **Goal:** Quick, one-time setup.

* **Caffeine Logging:**
    * **Functionality:** A simple, fast interface to log caffeine intake.
    * **Presets:** Include common beverages (e.g., Coffee 8oz, Espresso Shot, Black Tea, Energy Drink). Each preset has an associated average caffeine `mg` value.
    * **Custom Entry:** Allow users to log a custom drink with a name and a `mg` value.
    * **Time Stamp:** Automatically log the current time but allow the user to adjust it. This logging process must be frictionless.

* **Main Dashboard:**
    * **Primary Visual:** A real-time graph or gauge showing the **estimated active caffeine level** in the user's system.
    * **Key Forecast:** Prominently display the **predicted "crash" time** (e.g., "Crash expected around 3:45 PM").
    * **Log Display:** A simple timeline or list showing today's logged drinks.

* **Push Notifications:**
    * **Trigger:** Send a notification **30 minutes before** the predicted crash time.
    * **Content:** Simple, actionable alert (e.g., "Heads up: A caffeine crash is predicted around 4:00 PM. Consider a short walk or a glass of water.").

---

### ## 3. Backend & Algorithm Logic

This is the engine of the app. The logic must be sound, even if simplified for the MVP.

* **User Data Model:**
    ```json
    {
      "UserID": "string",
      "Weight_kg": "number",
      "Sensitivity": "ENUM('LOW', 'MEDIUM', 'HIGH')",
      "LogEntries": [
        {
          "DrinkName": "string",
          "CaffeineAmount_mg": "number",
          "Timestamp": "datetime"
        }
      ]
    }
    ```

* **Caffeine Decay Algorithm (The "Crash" Model):**
    * **Principle:** Use a standard exponential decay model based on caffeine's half-life.
    * **Half-Life Variable (T):** This is determined by the user's self-assessed sensitivity.
        * **Low Sensitivity:** `T = 6` hours
        * **Medium Sensitivity:** `T = 5` hours
        * **High Sensitivity:** `T = 4` hours
    * **Calculation:** For each dose, calculate the remaining caffeine at any given time `t` using the formula: $$C(t) = C_0 \cdot (0.5)^{(t/T)}$$ where $C_0$ is the initial dose in `mg`. The total active caffeine is the sum of all recent doses' remaining `mg`.
    * **"Crash" Definition:** The crash is predicted when the total active caffeine level drops below a predefined threshold (e.g., **25% of the last peak level** or a fixed `mg` value like 40mg). The backend should constantly recalculate this.

---

### ## 4. Frontend & User Experience (UI/UX)

The design should be clean, data-driven, and intuitive.

* **Design Philosophy:** Minimalist. Data visualization is key. Offer both light and dark modes.
* **Logging Flow:** The "add drink" button should be the most prominent, always-accessible element on the main screen. The logging process should take no more than two taps for a preset.
* **Dashboard View:** The graph showing caffeine decay should be the centerpiece. The x-axis is time, the y-axis is active `mg`. Plot past intake, current level, and the future predicted decay curve.

---

### ## 5. Future Enhancements (Post-MVP)

* **Machine Learning Model:** Introduce a feedback mechanism ("Did you crash? Rate your energy."). Use this data to train a model that learns an individual user's *true* caffeine metabolism rate over time, moving beyond simple presets.
* **Health Integrations:** Sync with **Apple Health** or **Google Fit** to factor in sleep data, as sleep quality can significantly impact caffeine's effects.
* **Strategic Recommendations:** Evolve from just predicting a crash to providing recommendations, such as "For sustained focus, your next coffee should be around 1:30 PM."
* **Barcode Scanner:** Allow users to scan the barcode on a commercial drink to automatically log its caffeine content.

---

### ## 6. Monetization Strategy

Avoid ads. They destroy the focused user experience required for a utility app.

* **Freemium Model:**
    * **Free Version:** Includes all core MVP features (logging, prediction, notifications) but may be limited to logging 3-5 drinks per day.
    * **Premium Version (One-time purchase or subscription):**
        * Unlimited logging.
        * Access to the advanced ML-powered prediction model.
        * HealthKit/Google Fit integration.
        * Detailed historical data analysis and personal trend reports.